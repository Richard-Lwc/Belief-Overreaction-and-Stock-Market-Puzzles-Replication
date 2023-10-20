cd "C:\Users\ASUS\Desktop\Overreaction_replication"
import delimited "LTG_portfolio_return.csv", case(preserve) clear

save "LTG_portfolio_return.dta", replace