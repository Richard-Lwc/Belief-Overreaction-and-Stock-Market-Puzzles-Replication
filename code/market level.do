cd "C:\Users\ASUS\Desktop\Overreaction_replication"
import delimited "sp500_data.csv", case(preserve) clear

egen std_LTG  = std(LTG)
egen std_e_2_e_1 = std(log(EPS_2) - log(EPS_1))
egen std_return_1 = std(return_1)
egen std_return_1_3 = std(return_1_3)
egen std_return_1_5 = std(return_1_5)
egen std_e_1_e_0 = std(log(EPS_1) - log(EPS))
egen std_dp = std(dp)
egen std_pe = std(pe)
egen std_SVIX = std(SVIX)
egen std_term_spread = std(term_spread)
egen std_credit_spread = std(credit_spread)
egen std_uncertainty = std(USEPUINDXM)
egen std_inflation = std(INFCPI1YR)
egen std_e_cae = std(e_cae)
egen std_delta_LTG = std(delta_LTG)
egen std_delta_LTG_1 = std(delta_LTG_1)
egen std_delta_LTG_2 = std(delta_LTG_2)
egen std_delta_LTG_3 = std(delta_LTG_3)
egen std_delta_LTG_4 = std(delta_LTG_4)
egen std_delta_LTG_5 = std(delta_LTG_5)
egen std_lag_LTG = std(lag_LTG)

egen std_forecast_error = std(forecast_error)
egen std_forecast_error_m1 = std(forecast_error_m1)
egen std_forecast_error_m2 = std(forecast_error_m2)
egen std_forecast_error_m3 = std(forecast_error_m3)
egen std_forecast_error_m4 = std(forecast_error_m4)

// merge with portfolio return data
merge 1:1 rankdate using "LTG_portfolio_return.dta", keep(match) nogen

gen t=_n
tsset t

// Table 3
newey std_delta_LTG std_lag_LTG std_e_cae, lag(12)
est store m1
newey std_delta_LTG std_lag_LTG std_e_cae std_dp, lag(12)
est store m2
newey std_delta_LTG std_lag_LTG std_e_cae std_SVIX, lag(12)
est store m3
reg2docx m1 m2 m3 using table3.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_delta_LTG std_lag_LTG std_e_cae
reg std_delta_LTG std_lag_LTG std_e_cae std_dp
reg std_delta_LTG std_lag_LTG std_e_cae std_SVIX


//Table 3 has a span from 1988:01 - 2020:12，then other tables are all from 1988:01 - 2015:12，thus I first run table 3 then I drop the data after 2015.12
drop if rankdate > 201512

// Table 1
// Panel A
newey std_return_1 std_LTG, lag(12)
est store m1
newey std_return_1_3 std_LTG, lag(36)
est store m2
newey std_return_1_5 std_LTG, lag(60)
est store m3

reg2docx m1 m2 m3 using table1_panelA.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant

// get adjusted R_square
reg std_return_1 std_LTG
reg std_return_1_3 std_LTG
reg std_return_1_5 std_LTG


// Panel B
newey std_return_1 std_e_1_e_0, lag(12)
est store m1
newey std_return_1_3 std_e_1_e_0, lag(36)
est store m2
newey std_return_1_5 std_e_1_e_0, lag(60)
est store m3
reg2docx m1 m2 m3 using table1_panelB.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant

// get adjusted R_square
reg std_return_1 std_e_1_e_0
reg std_return_1_3 std_e_1_e_0
reg std_return_1_5 std_e_1_e_0

//Panel C
newey std_return_1 std_e_2_e_1, lag(12)
est store m1
newey std_return_1_3 std_e_2_e_1, lag(36)
est store m2
newey std_return_1_5 std_e_2_e_1, lag(60)
est store m3
reg2docx m1 m2 m3 using table1_panelC.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

// get adjusted R_square
reg std_return_1 std_e_2_e_1
reg std_return_1_3 std_e_2_e_1
reg std_return_1_5 std_e_2_e_1

// Table 2
// Panel A
newey std_return_1_5 std_LTG std_dp, lag(60)
est store m1
newey std_return_1_5 std_LTG std_pe, lag(60)
est store m2
newey std_return_1_5 std_LTG std_SVIX, lag(60)
est store m3
newey std_return_1_5 std_LTG std_e_1_e_0, lag(60)
est store m4

reg2docx m1 m2 m3 m4 using table2_panelA_5.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant 

reg std_return_1_5 std_LTG std_dp
reg std_return_1_5 std_LTG std_pe
reg std_return_1_5 std_LTG std_SVIX
reg std_return_1_5 std_LTG std_e_1_e_0

newey std_return_1_3 std_LTG std_dp, lag(36)
est store m1
newey std_return_1_3 std_LTG std_pe, lag(36)
est store m2
newey std_return_1_3 std_LTG std_SVIX, lag(36)
est store m3
newey std_return_1_3 std_LTG std_e_1_e_0, lag(36)
est store m4

reg2docx m1 m2 m3 m4 using table2_panelA_3.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant 

reg std_return_1_3 std_LTG std_dp
reg std_return_1_3 std_LTG std_pe
reg std_return_1_3 std_LTG std_SVIX
reg std_return_1_3 std_LTG std_e_1_e_0

newey std_return_1 std_LTG std_dp, lag(12)
est store m1
newey std_return_1 std_LTG std_pe, lag(12)
est store m2
newey std_return_1 std_LTG std_SVIX, lag(12)
est store m3
newey std_return_1 std_LTG std_e_1_e_0, lag(12)
est store m4

reg2docx m1 m2 m3 m4 using table2_panelA_1.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant 

reg std_return_1 std_LTG std_dp
reg std_return_1 std_LTG std_pe
reg std_return_1 std_LTG std_SVIX
reg std_return_1 std_LTG std_e_1_e_0


// Panel B
newey std_return_1_5 std_LTG std_term_spread, lag(60)
est store m1
newey std_return_1_5 std_LTG std_credit_spread, lag(60)
est store m2
newey std_return_1_5 std_LTG std_uncertainty, lag(60)
est store m3
newey std_return_1_5 std_LTG std_inflation, lag(60)
est store m4
reg2docx m1 m2 m3 m4 using table2_panelB_5.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_return_1_5 std_LTG std_term_spread
reg std_return_1_5 std_LTG std_credit_spread
reg std_return_1_5 std_LTG std_uncertainty
reg std_return_1_5 std_LTG std_inflation

newey std_return_1_3 std_LTG std_term_spread, lag(36)
est store m1
newey std_return_1_3 std_LTG std_credit_spread, lag(36)
est store m2
newey std_return_1_3 std_LTG std_uncertainty, lag(36)
est store m3
newey std_return_1_3 std_LTG std_inflation, lag(36)
est store m4
reg2docx m1 m2 m3 m4 using table2_panelB_3.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_return_1_3 std_LTG std_term_spread
reg std_return_1_3 std_LTG std_credit_spread
reg std_return_1_3 std_LTG std_uncertainty
reg std_return_1_3 std_LTG std_inflation

newey std_return_1 std_LTG std_term_spread, lag(12)
est store m1
newey std_return_1 std_LTG std_credit_spread, lag(12)
est store m2
newey std_return_1 std_LTG std_uncertainty, lag(12)
est store m3
newey std_return_1 std_LTG std_inflation, lag(12)
est store m4
reg2docx m1 m2 m3 m4 using table2_panelB_1.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_return_1 std_LTG std_term_spread
reg std_return_1 std_LTG std_credit_spread
reg std_return_1 std_LTG std_uncertainty
reg std_return_1 std_LTG std_inflation


// Table 4
newey std_forecast_error std_delta_LTG std_lag_LTG, lag(60)
est store m1
predict predicted_forecast_error, xb
newey std_return_1_5 std_delta_LTG std_lag_LTG, lag(60)
est store m2
// IV
// egen std_predicted_forecast_error = std(predicted_forecast_error)
newey std_return_1_5 predicted_forecast_error, lag(60)
est store m3
newey std_return_1_5 predicted_forecast_error std_dp, lag(60)
est store m4
reg2docx m1 m2 m3 m4 using table4_5.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_forecast_error std_delta_LTG std_lag_LTG
reg std_return_1_5 std_delta_LTG std_lag_LTG
reg std_return_1_5 predicted_forecast_error
reg std_return_1_5 predicted_forecast_error std_dp

ivreg2 std_return_1_5 (std_forecast_error = std_delta_LTG std_lag_LTG), r
weakivtest

// 3
newey std_return_1_3 std_delta_LTG std_lag_LTG, lag(36)
est store m2
// IV
newey std_return_1_3 predicted_forecast_error, lag(36)
est store m3
newey std_return_1_3 predicted_forecast_error std_dp, lag(36)
est store m4
reg2docx m1 m2 m3 m4 using table4_3.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_forecast_error std_delta_LTG std_lag_LTG
reg std_return_1_3 std_delta_LTG std_lag_LTG
reg std_return_1_3 predicted_forecast_error
reg std_return_1_3 predicted_forecast_error std_dp

ivreg2 std_return_1_3 (std_forecast_error = std_delta_LTG std_lag_LTG), r
weakivtest

// 1
newey std_return_1 std_delta_LTG std_lag_LTG, lag(12)
est store m2
// IV
newey std_return_1 predicted_forecast_error, lag(12)
est store m3
newey std_return_1 predicted_forecast_error std_dp, lag(12)
est store m4
reg2docx m1 m2 m3 m4 using table4_1.docx, se(%9.4f) b(%9.4f) replace scalars(N r2_a) noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_forecast_error std_delta_LTG std_lag_LTG
reg std_return_1 std_delta_LTG std_lag_LTG
reg std_return_1 predicted_forecast_error
reg std_return_1 predicted_forecast_error std_dp

ivreg2 std_return_1 (std_forecast_error = std_delta_LTG std_lag_LTG), r
weakivtest




//Table 5
// get residuals, according to Table B.7
qui reg std_return_1 std_delta_LTG_1 std_forecast_error_m4
predict residual_return_1, r

qui reg std_return_1_3 std_delta_LTG_1 std_delta_LTG_2 std_delta_LTG_3 std_forecast_error_m4 std_forecast_error_m3 std_forecast_error_m2 
predict residual_return_1_3, r

qui reg std_return_1_5 std_delta_LTG_1 std_delta_LTG_2 std_delta_LTG_3 std_delta_LTG_4 std_delta_LTG_5 std_forecast_error_m4 std_forecast_error_m3 std_forecast_error_m2 std_forecast_error_m1 std_forecast_error
predict residual_return_1_5, r

newey std_return_1 std_dp, lag(12)
est store m1
newey residual_return_1 std_dp, lag(12)
est store m2
newey std_return_1_3 std_dp, lag(36)
est store m3
newey residual_return_1_3 std_dp, lag(36)
est store m4
newey std_return_1_5 std_dp, lag(60)
est store m5
newey residual_return_1_5 std_dp, lag(60)
est store m6

reg2docx m1 m2 m3 m4 m5 m6 using table5.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_return_1 std_dp
reg residual_return_1 std_dp
reg std_return_1_3 std_dp
reg residual_return_1_3 std_dp
reg std_return_1_5 std_dp
reg residual_return_1_5 std_dp

//Table 7
egen std_Mkt_1_5 = std(Mkt_1_5)
egen std_Mkt_5 = std(Mkt_5)
egen std_Mkt_3 = std(Mkt_3)
egen std_LLTG_return_1_5 = std(LLTG_1_5)
egen std_HLTG_return_1_5 = std(HLTG_1_5)
egen std_LLTG_return_1_3 = std(LLTG_1_3)
egen std_HLTG_return_1_3 = std(HLTG_1_3)
egen std_PMO_1_5 = std(PMO_1_5)
egen std_PMO_1_3 = std(PMO_1_3)


newey std_LLTG_return_1_3 std_delta_LTG std_lag_LTG std_Mkt_3, lag(36)
est store m1
newey std_HLTG_return_1_3 std_delta_LTG std_lag_LTG std_Mkt_3, lag(36)
est store m2
newey std_PMO_1_3 std_delta_LTG std_lag_LTG std_Mkt_3, lag(36)
est store m3
newey std_PMO_1_3 std_delta_LTG std_lag_LTG std_Mkt_3 std_SVIX, lag(36)
est store m4
newey std_PMO_1_3 std_delta_LTG std_lag_LTG std_Mkt_3 std_dp, lag(36)
est store m5
reg2docx m1 m2 m3 m4 m5 using table7_3.docx, se(%9.4f) b(%9.4f) replace noconstant scalars(N r2_a) note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_LLTG_return_1_3 std_delta_LTG std_lag_LTG std_Mkt_3
reg std_HLTG_return_1_3 std_delta_LTG std_lag_LTG std_Mkt_3
reg std_PMO_1_3 std_delta_LTG std_lag_LTG std_Mkt_3
reg std_PMO_1_3 std_delta_LTG std_lag_LTG std_Mkt_3 std_SVIX
reg std_PMO_1_3 std_delta_LTG std_lag_LTG std_Mkt_3 std_dp

newey std_LLTG_return_1_5 std_delta_LTG std_lag_LTG std_Mkt_5, lag(60)
est store m1
newey std_HLTG_return_1_5 std_delta_LTG std_lag_LTG std_Mkt_5, lag(60)
est store m2
newey std_PMO_1_5 std_delta_LTG std_lag_LTG std_Mkt_5, lag(60)
est store m3
newey std_PMO_1_5 std_delta_LTG std_lag_LTG std_Mkt_5 std_SVIX, lag(60)
est store m4
newey std_PMO_1_5 std_delta_LTG std_lag_LTG std_Mkt_5 std_dp, lag(60)
est store m5
reg2docx m1 m2 m3 m4 m5 using table7_5.docx, se(%9.4f) b(%9.4f) replace noconstant scalars(N r2_a) note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_LLTG_return_1_5 std_delta_LTG std_lag_LTG std_Mkt_5
reg std_HLTG_return_1_5 std_delta_LTG std_lag_LTG std_Mkt_5
reg std_PMO_1_5 std_delta_LTG std_lag_LTG std_Mkt_5
reg std_PMO_1_5 std_delta_LTG std_lag_LTG std_Mkt_5 std_SVIX
reg std_PMO_1_5 std_delta_LTG std_lag_LTG std_Mkt_5 std_dp

//Table 8
egen std_LLTG_error = std(LLTG_error)
egen std_HLTG_error = std(HLTG_error)
egen std_PMO_error = std(PMO_error)

newey std_LLTG_error std_delta_LTG std_lag_LTG, lag(60)
est store m1
newey std_HLTG_error std_delta_LTG std_lag_LTG, lag(60)
est store m2
newey std_PMO_error std_delta_LTG std_lag_LTG, lag(60)
est store m3
reg2docx m1 m2 m3 using table8.docx, se(%9.4f) b(%9.4f) replace noconstant scalars(N r2_a) note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)

reg std_LLTG_error std_delta_LTG std_lag_LTG
reg std_HLTG_error std_delta_LTG std_lag_LTG
reg std_PMO_error std_delta_LTG std_lag_LTG
