Data origination:

"1-year treasury yield.csv", 
"Long-Term Government Bond Yields.csv", 
"BAA.csv", "AAA.csv", 
"economic policy uncertainty index.csv", 
"CPILFESL.csv": https://fred.stlouisfed.org/

"inflation.csv" (the forecast for CPI inflation in year t+1): https://www.philadelphiafed.org/surveys-and-data/real-time-data-research/survey-of-professional-forecasters

"SVIX2.csv": https://personal.lse.ac.uk/martiniw/

"MULTPL-SP500_DIV_YIELD_MONTH.csv",
"MULTPL-SP500_PE_RATIO_MONTH.csv": https://data.nasdaq.com/

"sp500_index": History constituents of S&P500 portfolios, can't find the origination though.

other datasets (e.g., CRSP, IBES, link_data) are all from WRDS database, due to copyrights, I can't upload them, but could show the columns of each dataset so as to faster the search process in the future if needed: 
CRSP columns: PERMNO, date, NCUSIP, PRC, RET, SHROUT, CFACSHR, vwretd
IBES all columns: not that many, so I just downloaded all of them
Compustat columns: GVKEY, LINKPRIM, LIID, LINKTYPE, LPERMNO, LINKDT, LINKENDDT, datadate, fyear, tic, cusip, fyr, at, epspi, epspx, oibdp 
financial ratios columns: gvkey, permno, adate, qdate, public_date, bm, pe_exi, pe_inc, divyield, TICKER, cusip
link_data columns: TICKER, PERMNO, NCUSIP, sdate, edate, SCORE

Data usage for all figures and tables:
Figure 1: EPS from Compustat and LTG from IBES Summary

Table 1 (Return Predictability and Expectations of Earnings Growth): 
LTG, 1-year and 2-year EPS forecasts Median (MEDEST) from IBES Summary, returns from CRSP

Table 2 (Return Predictability, Expectations and Measures of Required Returns):
Panel A: 
the price to dividend ratio, price to earnings ratio, expected one-year return on the market (SVIX), expected 1-year earnings growth forecasts
(surplus consumption ratio and consumption-wealth ratio haven't been covered in the replication)
Panel B: 
term spread, credit spread, economic policy uncertainty index, the forecast for CPI inflation in year t+1 by the Survey of Professional Forecasters
(optimal forecast of aggregate equity market returns and experienced dividend growth haven't been covered in the replication)

Table 3 (Determinants of LTG revisions): 
delta LTG, cyclically adjusted average earnings (inflation adjusted) from the previous 10 years (not sure though, cuz in the paper there is no absolute description)

Table 4 (Predictability of Forecast Errors and Returns):
cumulative returns, forecast errors, LTG

Table 5 (Unbundling Return Predictability from Price Dividend Ratio):
price dividend ratio, cumulative return, forecast error

Table 6 (Firm-Level Results):
LTG, price dividend ratio, price earnings ratio, cumulative returns, forecast error

Table 7 (Market Return and LTG portfolio returns):
LTG, cumulative returns, CRSP's value-weighted index (market return), SVIX, price dividend ratio

Table 8 (Forecast Errors of LTG Portfolios):
LTG, forecast error

Table 9 (Predictability of factor returns and forecast errors):
LTG, Fama-French HML, RMW, CMA and SMB portfolios, CRSP's value-weighted index, cumulative returns, forecast error
 
