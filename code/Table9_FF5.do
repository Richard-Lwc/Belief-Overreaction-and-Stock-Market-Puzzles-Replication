cd "C:\Users\ASUS\Desktop\Overreaction_replication"
import delimited "FF5_data.csv", case(preserve) clear

egen std_Mkt_1_5 = std(Mkt_1_5)
egen std_SMB_1_5 = std(SMB_1_5)
egen std_HML_1_5 = std(HML_1_5)
egen std_RMW_1_5 = std(RMW_1_5)
egen std_CMA_1_5 = std(CMA_1_5)
egen std_lag_LTG = std(lag_LTG)
egen std_delta_LTG = std(delta_LTG)
egen std_f_SMB = std(f_SMB)
egen std_f_HML = std(f_HML)
egen std_f_RMW = std(f_RMW)
egen std_f_CMA = std(f_CMA)

gen t = _n
tsset t

// Table 9
// Panel A
newey std_HML_1_5 std_delta_LTG std_lag_LTG std_Mkt_1_5, lag(60)
est store m1
newey std_RMW_1_5 std_delta_LTG std_lag_LTG std_Mkt_1_5, lag(60)
est store m2
newey std_CMA_1_5 std_delta_LTG std_lag_LTG std_Mkt_1_5, lag(60)
est store m3
newey std_SMB_1_5 std_delta_LTG std_lag_LTG std_Mkt_1_5, lag(60)
est store m4
reg2docx m1 m2 m3 m4 using table9_panelA.docx, se(%9.4f) b(%9.4f) replace noconstant

// Panel B
newey std_f_HML std_delta_LTG std_lag_LTG, lag(60)
est store m1
newey std_f_RMW std_delta_LTG std_lag_LTG, lag(60)
est store m2
newey std_f_CMA std_delta_LTG std_lag_LTG, lag(60)
est store m3
newey std_f_SMB std_delta_LTG std_lag_LTG, lag(60)
est store m4
reg2docx m1 m2 m3 m4 using table9_panelB.docx, se(%9.4f) b(%9.4f) replace noconstant note(*: p < 0.1  **: p < 0.05  ***: p < 0.01)


