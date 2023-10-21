cd "C:\Users\ASUS\Desktop\Overreaction_replication"
import delimited "whole_firm_data.csv", case(preserve) clear

destring pe, replace force
egen std_forecast_error = std(forecast_error)
egen std_return_1_5 = std(return_1_5)
egen std_delta_LTG = std(delta_LTG)
egen std_lag_LTG = std(lag_LTG)
egen std_dp = std(dp)
egen std_pe = std(pe)
// egen std_pe_exi = std(pe_exi)
// egen std_pe_inc = std(pe_inc)

sort PERMNO rankdate
by PERMNO: gen t = _n
xtset PERMNO t

keep if rankdate >= 198212 & rankdate <= 201512
// Table 6
xtscc std_forecast_error std_delta_LTG std_lag_LTG i.Year, fe lag(60)
est store m1
xtscc std_return_1_5 std_delta_LTG std_lag_LTG i.Year, fe lag(60)
est store m2

// get the fitted forecast error
reghdfe std_forecast_error std_lag_LTG std_delta_LTG, absorb(PERMNO Year)
predict predicted_forecast_error, xb
egen std_predicted_forecast_error = std(predicted_forecast_error)

ivreg2 std_return_1_5 (std_forecast_error = std_lag_LTG std_delta_LTG), r

xtscc std_return_1_5 predicted_forecast_error i.Year, fe lag(60)
est store m3
xtscc std_return_1_5 predicted_forecast_error std_dp i.Year, fe lag(60)
est store m4
xtscc std_return_1_5 predicted_forecast_error std_pe i.Year, fe lag(60)
est store m5

reghdfe std_forecast_error std_delta_LTG std_lag_LTG, absorb(PERMNO Year)
reghdfe std_return_1_5 std_delta_LTG std_lag_LTG, absorb(PERMNO Year)
reghdfe std_return_1_5 predicted_forecast_error, absorb(PERMNO Year)
reghdfe std_return_1_5 predicted_forecast_error std_dp, absorb(PERMNO Year)
reghdfe std_return_1_5 predicted_forecast_error std_pe, absorb(PERMNO Year)

drop if inrange(Year, 1998, 2002) | inrange(Year, 2007, 2009)


reghdfe std_forecast_error std_lag_LTG std_delta_LTG, absorb(PERMNO Year)
predict predicted_forecast_error_2, xb
egen std_predicted_forecast_error_2 = std(predicted_forecast_error_2)

// KP F-stat
ivreg2 std_return_1_5 (std_forecast_error = std_lag_LTG std_delta_LTG), r

xtscc std_return_1_5 predicted_forecast_error_2 std_dp i.Year, fe lag(60)
est store m6
xtscc std_return_1_5 predicted_forecast_error_2 std_pe i.Year, fe lag(60)
est store m7
reg2docx m1 m2 m3 m4 m5 m6 m7 using table6.docx, se(%9.4f) b(%9.4f) scalars(N r2_a) replace noconstant addfe("Year FE = YES" "Firm FE = YES") note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)


reghdfe std_return_1_5 predicted_forecast_error_2 std_dp, absorb(PERMNO Year)
reghdfe std_return_1_5 predicted_forecast_error_2 std_pe, absorb(PERMNO Year)