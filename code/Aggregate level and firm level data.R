cat("\f")  
rm(list=ls())
###############################################################################
# Set working directory
###############################################################################
wd <- "C:\\Users\\ASUS\\Desktop\\Overreaction_replication"
setwd(wd)
gc()
###############################################################################
# Library
###############################################################################
library(tidyverse)
library(data.table)
library(DescTools)
library(zoo)

###############################################################################
# Get CRSP data and S&P500 list
# PRC, RET, SHROUT, CFACSHR, vwretd
###############################################################################
crsp <- fread('CRSP.csv')
# 调整PRICE以及RET
crsp[!is.na(DLPRC), PRC := DLPRC]
crsp[, PRC := abs(PRC)]
crsp[, c('RET', 'DLRET') := .(as.numeric(RET), as.numeric(DLRET))]
crsp[!is.na(DLRET), RET := DLRET]
# crsp存在重复值
market_list <- crsp %>% mutate(rankdate = YearMonth(date)) %>% 
  distinct(PERMNO, rankdate, .keep_all = TRUE) %>% 
  select(PERMNO, date, rankdate, NCUSIP, PRC, 
         RET, SHROUT, CFACSHR, vwretd)

sp500 <- fread('sp500.csv') %>% mutate(rankdate = YearMonth(date))
# sp500 %>% group_by(date) %>% count()
sp500_list <- market_list %>% semi_join(sp500, by = c('PERMNO' = 'permno', 'rankdate'))


###############################################################################
# Get IBES Summary Statistics and Compustat data
# forecasted EPS from IBES
# epspx, epspx, Total asset, operating profit from Compustat
# I originally used IBES actual, but there were too many missing data
###############################################################################

IBES <- fread('IBES.csv') %>%  arrange(TICKER, STATPERS, FPI)

IBES <- IBES %>% mutate(yearmonth = YearMonth(FPEDATS) - 100 * FPI)
# YearMonth(FPEDATS) - 100 * FPI means the latest date of the EPS data analysts have when they forecast EPS

###############################################################################
# Merge with Compustat
###############################################################################
compustat <- fread('compustat.csv')
compustat$LINKENDDT[compustat$LINKENDDT == 'E'] <- as.character(Today())
# For a current valid link, LINKENDDT is set to 'E', thus replace it with current date

# Define a function to calculate the root, including for negative numbers
root <- function(x, root) {
  sign(x) * abs(x) ^ (1 / 5)
}
compustat <- compustat %>%
  filter(datadate >= LINKDT, datadate <= LINKENDDT) %>% 
  group_by(datadate) %>% 
  # winsorize across the whole dataset
  mutate(epspx = Winsorize(epspx, na.rm = TRUE, probs = c(.01,.99))) %>%
  group_by(LPERMNO) %>% 
  mutate(past_eps = lag(epspx),
         yearmonth = YearMonth(datadate),
# construct e_growth to signify the actual LTG.
# The LTG forecasts, as collected by I/B/E/S, usually cover a five-year period that begins on the first day of the current fiscal year. 
         e_growth = root(lead(epspx, 5) / abs(epspx), 5) - 1) %>% 
  select(LPERMNO, datadate, fyear, yearmonth, at, epspi, past_eps, epspx, oibdp, e_growth)

# 
link_table <- fread('link_data.csv')

link <- link_table %>% filter(SCORE == 1) %>% 
  select(-SCORE) %>% distinct(TICKER, PERMNO, NCUSIP)

IBES_link <- IBES %>% left_join(link, by = c('CUSIP' = 'NCUSIP', 'TICKER')) %>%
  left_join(compustat, by = c('PERMNO' = 'LPERMNO', 'yearmonth')) %>% 
  select(PERMNO, CUSIP, STATPERS, FPI, MEDEST, epspx, e_growth, past_eps, at, oibdp,
         CURCODE, datadate, fyear)
  
# LTG cannot match Compustat data (LTG data doesn't have FPEDATS)
# To keep other data when using the spread function, we first separate the LTG data (merge later)
IBES_link_LTG <- IBES_link %>% filter(FPI == 0) %>% select(-epspx, -FPI, -past_eps,
                                                           -at, -oibdp, -fyear,
                                                           -CURCODE, -datadate, -e_growth)
IBES_link_EPS <- IBES_link %>% filter(FPI != 0)

# 长表变宽表
IBES_all <- IBES_link_EPS %>% 
  spread(key = FPI, value = MEDEST) %>% arrange(PERMNO, STATPERS) %>% 
  left_join(IBES_link_LTG, by = c('PERMNO', 'CUSIP', 'STATPERS')) %>% 
  distinct(PERMNO, STATPERS, .keep_all = TRUE) %>% 
  rename(EPS_1=`1`, EPS_2=`2`, EPS_3=`3`, EPS_4=`4`, EPS_5=`5`, LTG=MEDEST) %>%
  mutate(rankdate = YearMonth(STATPERS))

###############################################################################
# link with sp500 from CRSP by matching STATPERS and date
###############################################################################

# can say the month when analysts first use a new EPS is the month that this EPS
# is announced. Thus, assume earnings are reported with a 3-month lag is not necessary.
sp500_data <- sp500_list %>%
  inner_join(IBES_all, by = c('PERMNO', 'rankdate')) %>%
  filter(CURCODE == 'USD') %>% select(-CURCODE) %>%
  # mutate(ann_yearmonth = YearMonth(as.Date(datadate) + months(3))) %>% 
  group_by(PERMNO, datadate) %>% 
  mutate(ann_cfacshr = first(CFACSHR))


###############################################################################
# adjust SP500 data, Insert financial ratios data: pe_exi, pe_inc, divyield, bm, CAPE
###############################################################################

sp500_data <- sp500_data %>% 
  gather(key = 'horizon', value = 'predict_EPS', EPS_1:EPS_5) %>% 
  arrange(PERMNO, rankdate) %>% group_by(PERMNO, rankdate) %>% mutate(LTG = LTG / 100)

# Beyond the second fiscal year we assume that analysts expect EPS to grow at the rate LTG starting 
# with the last non-missing positive EPS forecast
sp500_data <- sp500_data %>% 
  mutate(predict_EPS = ifelse(is.na(predict_EPS) & !is.na(LTG) & horizon == 'EPS_3', 
                      ifelse(!is.na(lag(predict_EPS)),  lag(predict_EPS) * (1 + LTG), 
                             lag(predict_EPS, 2) * (1 + LTG) ** 2), 
                      predict_EPS))
for (i in 1:2){
  sp500_data <- sp500_data %>% 
    mutate(predict_EPS = ifelse(is.na(predict_EPS) & !is.na(lag(predict_EPS)) & !is.na(LTG) & horizon %in% c('EPS_4', 'EPS_5'), 
                        lag(predict_EPS) * (1 + LTG), predict_EPS))
}

# Linear interpolate
sp500_data <- sp500_data %>% mutate(predict_EPS = na.approx(predict_EPS, na.rm = FALSE))

# Adjust EPS to the forecast date and generate same base EPS 
sp500_DATA <- sp500_data %>% 
  spread(key = horizon, value = predict_EPS)  %>% group_by(PERMNO) %>% 
  mutate(EPS = epspx * CFACSHR / ann_cfacshr, 
         # EPS_same_base = epspx / ann_cfacshr,
         # EPS_same_base is to mitigate the effects of share splitting
         MV = PRC * SHROUT,
         lag_MV = lag(MV)) %>% 
  filter(!is.na(MV))

# CAPEI: Multiple of Market Value of Equity to 5-year moving average of Net Income 

financial_ratio <- fread('financial ratio.csv')
financial_ratio <- financial_ratio %>% mutate(rankdate = YearMonth(public_date)) %>% 
  select(permno, adate, rankdate, bm, pe_exi, pe_inc, divyield, CAPEI) %>% 
  rename(datadate = adate, PERMNO = permno, dp = divyield)

financial_ratio %>% fwrite('refine_financial_ratio.csv')

CAPEI <- financial_ratio %>% select(PERMNO, rankdate, CAPEI)
sp500_DATA <- sp500_DATA %>% 
  left_join(CAPEI, by = c('PERMNO', 'rankdate')) %>% 
  mutate(cae = PRC / CAPEI)

###############################################################################
# get sp500 index from CRSP
###############################################################################

sp500_index <- fread('sp500_index.csv')
sp500_index <- sp500_index %>% 
  mutate(rankdate = YearMonth(caldt), divisor = totval / spindx * 1000, 
         return = log(spindx) - log(lag(spindx))) %>% 
  select(rankdate, return, totval, divisor)

###############################################################################
# Summarise sp500 level data
###############################################################################

market_sp500 <- sp500_DATA %>% group_by(date, rankdate) %>% 
  summarise(LTG = weighted.mean(LTG, MV, na.rm = TRUE),
            cae = sum(cae * SHROUT, na.rm = TRUE),
            epspx = sum(epspx * SHROUT, na.rm = TRUE),
            EPS = sum(EPS * SHROUT, na.rm = TRUE),
            EPS_1 = sum(EPS_1 * SHROUT, na.rm = TRUE),
            EPS_2 = sum(EPS_2 * SHROUT, na.rm = TRUE),
            EPS_3 = sum(EPS_3 * SHROUT, na.rm = TRUE),
            EPS_4 = sum(EPS_4 * SHROUT, na.rm = TRUE),
            EPS_5 = sum(EPS_5 * SHROUT, na.rm = TRUE),
            MV = sum(MV, na.rm = TRUE))
# There is a very subtle point here: For the EPS, it is adjusted to the splitting
# level of the analysts' forecast day to equal the splitting level of EPS forecasts.
# But for the cyclically adjusted earnings,  I believe it's better to use the real
# earnings per share since when calculating the CAPE we just use the real EPS. 
# Also, it applies to the calculation the forecast error.
###############################################################################
# Figure 1
###############################################################################

market_sp500 <- market_sp500 %>% 
  left_join(sp500_index, by = 'rankdate') %>% 
  filter(MV >= 0.9 * totval) %>%
  mutate(epspx = epspx / divisor,
         cae = cae / divisor,
         EPS = EPS / divisor, 
         EPS_1 = EPS_1 / divisor,
         EPS_2 = EPS_2 / divisor,
         EPS_3 = EPS_3 / divisor,
         EPS_4 = EPS_4 / divisor,
         EPS_5 = EPS_5 / divisor) %>% 
  filter(!is.na(LTG))


# the graph of "E[e_t+1] - e_t" seems to have some problems, much more volatile than the paper's.
ggplot(market_sp500) + 
  geom_line(mapping = aes(x = rankdate, y = LTG), colour = 'blue') +
  stat_smooth(aes(x = rankdate, y = LTG), formula = y ~ s(x, k = 254), method = "gam", se = FALSE, colour = 'red') +
  theme_classic()

ggplot(market_sp500) +
  geom_line(mapping = aes(x = rankdate, y = log(EPS_1) - log(EPS)), colour = 'blue') +
  stat_smooth(aes(x = rankdate, y = log(EPS_1) - log(EPS)), formula = y ~ s(x, k = 100), method = "gam", se = FALSE, colour = '#008a00') +
  theme_classic()

# merge 2 graphs
# scale_y_continuous(
#   # Feature of the first axis
#   name = "LTG_t",
#   # Add a second axis and specify its features
#   sec.axis = sec_axis(~.*coeff, name = 'E[e_t+1] - e_t')
# ) +
#   theme_classic()
###############################################################################
# Merge data with other proxies from Nasdaq
###############################################################################

pd <- fread("MULTPL-SP500_DIV_YIELD_MONTH.csv")
pd <- pd %>% mutate(day = Day(date), rankdate = YearMonth(date)) %>% 
  filter(day != 1) %>% select(rankdate, dp)

# PE ratio是期初的，可能有一点误差
pe <- fread("MULTPL-SP500_PE_RATIO_MONTH.csv")
pe <- pe %>% mutate(day = Day(Date), rankdate = YearMonth(Date)) %>% 
  filter(day == 1) %>% select(rankdate, pe)
SVIX <- fread('SVIX2.csv') 
SVIX <- SVIX %>% mutate(rankdate = YearMonth(date)) %>% group_by(rankdate) %>% 
  summarise(SVIX = last(SVIX_12))

bond_1_year <- fread('1-year treasury yield.csv')
bond_10_year <- fread('Long-Term Government Bond Yields.csv')
term_spread <- bond_10_year %>% inner_join(bond_1_year, by = 'DATE') %>% 
  arrange(DATE) %>% 
  mutate(term_spread = log(IRLTLT01USM156N) - log(GS1), rankdate = YearMonth(DATE)) %>% 
  select(rankdate, term_spread)

BAA <- fread('BAA.csv')
AAA <- fread('AAA.csv')
credit_spread <- BAA %>% inner_join(AAA, by = 'DATE') %>% 
  mutate(credit_spread = log(BAA) - log(AAA), rankdate = YearMonth(DATE)) %>% 
  select(rankdate, credit_spread)

inflation <- fread('Inflation.csv')

inflation <- inflation %>% select(YEAR, QUARTER, INFCPI1YR)

economic_uncertainty <- fread('economic policy uncertainty index.csv') %>% 
  mutate(rankdate = YearMonth(DATE)) %>% select(rankdate, USEPUINDXM)


market_sp500 <- market_sp500 %>% ungroup() %>% 
  mutate(YEAR = Year(date), QUARTER = Quarter(date),
         lag_LTG = lag(LTG, 12), delta_LTG = LTG - lag_LTG,
         # right now, the column 'epspx' signifies the latest data analysts have,
         # thus, to calculate the actual LTG, the EPS right now should not be included.
         forecast_error = (lead(epspx, 60) / epspx) ** (1 / 5) - 1 - LTG,
         e_cae = log(epspx) - log(cae)) %>% 
  left_join(pd, by = 'rankdate')  %>% 
  left_join(pe, by = 'rankdate') %>% 
  left_join(SVIX, by = 'rankdate') %>% 
  left_join(term_spread, by = 'rankdate') %>% 
  left_join(credit_spread, by = 'rankdate') %>% 
  left_join(economic_uncertainty, by = 'rankdate') %>% 
  left_join(inflation, by = c('YEAR', 'QUARTER'))
  
  
market_sp500 %>% fwrite('sp500_data.csv')
# get average dp to discount return
pd %>% summarise(pd = 1 / (1 + exp(mean(dp))))
#######################   Go to Python: S&P500 data ############################

###############################################################################
# Firm level data ---- Table 6 : Merge with Financial Ratio from Compustat
###############################################################################

market_data <- sp500_list %>% 
  inner_join(IBES_all, by = c('PERMNO', 'rankdate')) %>% 
  filter(CURCODE == 'USD') %>% select(-CURCODE) %>% 
  group_by(PERMNO, datadate) %>% 
  mutate(ann_cfacshr = first(CFACSHR))

market_all <- market_data %>% 
  group_by(PERMNO) %>% 
  mutate(Year = Year(STATPERS),
         LTG = LTG / 100,
         lag_LTG = lag(LTG, 12), 
         delta_LTG = LTG - lag_LTG,
         MV = PRC * SHROUT, 
         lag_MV = lag(MV),
         log_RET = log(1 + RET),
         forecast_error = ifelse(epspx > 0, 
                                 (lead(epspx, 60) / epspx) ** (1 / 5) - 1 - LTG,
                                 ifelse(epspx < 0, 1 - (lead(epspx, 60) / epspx) ** (1 / 5) - LTG, NA)),
         pe = ifelse(epspx > 0, log(PRC) - log(epspx), NA))


market_all %>% fwrite('market_level_data.csv')

#######################   Go to Python: firm level    ##########################
###############################################################################
# LTG level data ---- Table 7 and 8  10 deciles
###############################################################################

LTG_portfolio <- market_all %>% filter(!is.na(LTG), !is.na(lag_MV)) %>% 
  group_by(rankdate) %>% 
  mutate(quantile_rank = ntile(LTG, 10))

LTG_RET <- LTG_portfolio %>%
  filter(quantile_rank %in% c(1, 10)) %>% 
  group_by(rankdate, quantile_rank) %>% 
  summarise(RET = weighted.mean(RET, lag_MV, na.rm = TRUE),
            Mkt = mean(vwretd)) %>% 
  spread(key = quantile_rank, value = RET) %>% 
  rename(LLTG_RET = `1`, HLTG_RET = `10`)

portfolio_error <- LTG_portfolio %>% 
  filter(quantile_rank %in% c(1, 10)) %>% 
  group_by(rankdate, quantile_rank) %>% 
  summarise(portfolio_error = mean(forecast_error, na.rm = TRUE)) %>% 
    spread(key = quantile_rank, value = portfolio_error) %>% 
    rename(LLTG_error = `1`, HLTG_error = `10`)

LTG_all <- LTG_RET %>% left_join(portfolio_error, by = 'rankdate')

LTG_all %>% fwrite('LTG_portfolio.csv')

#######################   Go to Python: LTG Portfolio ##########################

# ###############################################################################
# # bias level data ---- Table 7 and 8 using LTG bias
# ###############################################################################
# bias_portfolio <- market_all %>% filter(!is.na(forecast_error), !is.na(lag_MV)) %>% 
#   group_by(rankdate) %>% 
#   mutate(quantile_rank = ntile(forecast_error, 2))
# 
# bias_RET <- bias_portfolio %>% group_by(rankdate, quantile_rank) %>% 
#   summarise(RET = weighted.mean(RET, lag_MV, na.rm = TRUE),
#             Mkt = mean(vwretd)) %>% 
#   spread(key = quantile_rank, value = RET) %>% 
#   rename(Lbias_RET = `1`, Hbias_RET = `2`)
# 
# portfolio_error <- bias_portfolio %>% group_by(rankdate, quantile_rank) %>% 
#   summarise(portfolio_error = mean(forecast_error, na.rm = TRUE)) %>% 
#   spread(key = quantile_rank, value = portfolio_error) %>% 
#   rename(Lbias_error = `1`, Hbias_error = `2`)
# 
# bias_all <- bias_RET %>% left_join(portfolio_error, by = 'rankdate')
# 
# bias_all %>% fwrite('bias_portfolio.csv')
# 
# #######################   Go to Python: Bias Portfolio ##########################

###############################################################################
# FF5 ---- Table 9       I use all firms in the market rather than only S&P500 
###############################################################################

#######################         Go to Python : FF5   ###########################

ff5_LTG <- na.omit(market_all %>% filter(!is.na(MV)) %>% group_by(date, rankdate) %>% 
  summarise(LTG = weighted.mean(LTG, MV, na.rm = TRUE))) %>% ungroup() %>% 
  mutate(lag_LTG = lag(LTG, 12), 
         delta_LTG = LTG - lag_LTG)

#######################         FF_5.csv is from Python          ###############
FF5 <- fread('FF_5.csv') %>% 
  group_by(PERMNO) %>% 
  mutate(lag_MV = lag(MV)) %>% 
  filter(!is.na(size_rank), !is.infinite(forecast_error), !is.na(lag_MV))
 

Mkt <- FF5 %>% group_by(rankdate) %>% summarise(Mkt = mean(vwretd))

BM <- FF5 %>% group_by(rankdate, size_rank, bm_rank) %>% 
  summarise(RET = weighted.mean(RET, lag_MV, na.rm = TRUE), 
            forecast_error = mean(forecast_error, na.rm = TRUE))

OP <- FF5 %>% group_by(rankdate, size_rank, OP_rank) %>% 
  summarise(RET = weighted.mean(RET, lag_MV, na.rm = TRUE),
            forecast_error = mean(forecast_error, na.rm = TRUE))

INV <- FF5 %>% group_by(rankdate, size_rank, inv_rank) %>% 
  summarise(RET = weighted.mean(RET, lag_MV, na.rm = TRUE), 
            forecast_error = mean(forecast_error, na.rm = TRUE))

# 先考虑return 
# SMB
SMB_BM <- BM %>% group_by(rankdate, size_rank) %>% 
  summarise(RET = mean(RET)) %>% 
  spread(key = size_rank, value = RET) %>% 
  mutate(SMB_BM = `1` - `2`) %>% select(rankdate, SMB_BM)
SMB_OP <- OP %>% group_by(rankdate, size_rank) %>% 
  summarise(RET = mean(RET)) %>% 
  spread(key = size_rank, value = RET) %>% 
  mutate(SMB_OP = `1` - `2`) %>% select(rankdate, SMB_OP)
SMB_INV <- INV %>% group_by(rankdate, size_rank) %>% 
  summarise(RET = mean(RET)) %>% 
  spread(key = size_rank, value = RET) %>% 
  mutate(SMB_INV = `1` - `2`) %>% select(rankdate, SMB_INV)

SMB <- SMB_BM %>% 
  left_join(SMB_OP, by = 'rankdate') %>% 
  left_join(SMB_INV, by = 'rankdate') %>% 
  mutate(SMB = (SMB_BM + SMB_OP + SMB_INV) / 3) %>% 
  select(rankdate, SMB)

# HML
HML <- BM %>% filter(bm_rank != 2) %>% group_by(rankdate, bm_rank) %>% 
  summarise(RET = mean(RET)) %>% 
  spread(key = bm_rank, value = RET) %>% 
  mutate(HML = `3` - `1`) %>% select(rankdate, HML)

# RMW
RMW <- OP %>% filter(OP_rank != 2) %>% group_by(rankdate, OP_rank) %>% 
  summarise(RET = mean(RET)) %>% 
  spread(key = OP_rank, value = RET) %>% 
  mutate(RMW = `3` - `1`) %>% select(rankdate, RMW)

# CMA
CMA <- INV %>% filter(inv_rank != 2) %>% group_by(rankdate, inv_rank) %>% 
  summarise(RET = mean(RET)) %>% 
  spread(key = inv_rank, value = RET) %>% 
  mutate(CMA = `1` - `3`) %>% select(rankdate, CMA)

ff5_return <- SMB %>% left_join(HML, by = 'rankdate') %>% 
  left_join(RMW, by = 'rankdate') %>% 
  left_join(CMA, by = 'rankdate')

# 再考虑forecast error
# SMB
f_SMB_BM <- BM %>% group_by(rankdate, size_rank) %>% 
  summarise(forecast_error = mean(forecast_error, na.rm = TRUE)) %>% 
  spread(key = size_rank, value = forecast_error) %>% 
  mutate(f_SMB_BM = `1` - `2`) %>% select(rankdate, f_SMB_BM)
f_SMB_OP <- OP %>% group_by(rankdate, size_rank) %>% 
  summarise(forecast_error = mean(forecast_error, na.rm = TRUE)) %>% 
  spread(key = size_rank, value = forecast_error) %>% 
  mutate(f_SMB_OP = `1` - `2`) %>% select(rankdate, f_SMB_OP)
f_SMB_INV <- INV %>% group_by(rankdate, size_rank) %>% 
  summarise(forecast_error = mean(forecast_error, na.rm = TRUE)) %>% 
  spread(key = size_rank, value = forecast_error) %>% 
  mutate(f_SMB_INV = `1` - `2`) %>% select(rankdate, f_SMB_INV)

f_SMB <- f_SMB_BM %>% 
  left_join(f_SMB_OP, by = 'rankdate') %>% 
  left_join(f_SMB_INV, by = 'rankdate') %>% 
  mutate(f_SMB = (f_SMB_BM + f_SMB_OP + f_SMB_INV) / 3) %>% 
  select(rankdate, f_SMB)

# HML
f_HML <- BM %>% filter(bm_rank != 2) %>% group_by(rankdate, bm_rank) %>% 
  summarise(forecast_error = mean(forecast_error, na.rm = TRUE)) %>% 
  spread(key = bm_rank, value = forecast_error) %>% 
  mutate(f_HML = `3` - `1`) %>% select(rankdate, f_HML)

# RMW
f_RMW <- OP %>% filter(OP_rank != 2) %>% group_by(rankdate, OP_rank) %>% 
  summarise(forecast_error = mean(forecast_error, na.rm = TRUE)) %>% 
  spread(key = OP_rank, value = forecast_error) %>% 
  mutate(f_RMW = `3` - `1`) %>% select(rankdate, f_RMW)

# CMA
f_CMA <- INV %>% filter(inv_rank != 2) %>% group_by(rankdate, inv_rank) %>% 
  summarise(forecast_error = mean(forecast_error, na.rm = TRUE)) %>% 
  spread(key = inv_rank, value = forecast_error) %>% 
  mutate(f_CMA = `3` - `1`) %>% select(rankdate, f_CMA)

ff5_forecast_error <- f_SMB %>% left_join(f_HML, by = 'rankdate') %>% 
  left_join(f_RMW, by = 'rankdate') %>% 
  left_join(f_CMA, by = 'rankdate')

ff5_data <- ff5_LTG %>% left_join(Mkt, by = 'rankdate') %>% 
  left_join(ff5_return, by = 'rankdate') %>% 
  left_join(ff5_forecast_error, by = 'rankdate')

ff5_data %>% fwrite('FF5_data.csv')
######     Go to Python: After Generate 'FF5_data.csv' from R  ##############

