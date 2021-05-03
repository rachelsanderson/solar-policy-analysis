**********************************************
****
**** OPENING DATA FOR Rachel Anderson
****
**********************************************
set more off
clear all
macro drop _all
clear matrix
drop _all 
cap log close
estimates clear

import delimited "/Users/rachelanderson/Dropbox (Princeton)/Research_V2/descriptive_solar/code/analysis/stata-policy-analysis/state_policy_panel.csv"

**********************************************
****
**** Encode group identifiers
****
**********************************************

egen state_code = group(state)
egen region_code = group(region)

**********************************************
****
**** Outcomes
****
**********************************************


// Create log outcome variables
gen log_n_plants = log(n_plants+1)
gen log_ac_cap = log(ac_cap_added + 1)

gen log_n_plants_qf = log(n_plants_qf + 1)
gen log_ac_cap_qf = log(ac_cap_added_qf + 1)

gen log_cum_ac_cap = log(cum_ac_cap_added + 1)
gen log_cum_n_plants = log(cum_n_plants + 1)

gen cum_avg_cap = cum_ac_cap_added/cum_n_plants
replace cum_avg_cap = 0 if cum_avg_cap == .
replace avg_cap_ac = 0 if avg_cap_ac == .

gen log_cum_avg_plant = log(cum_avg_cap + 1)
label variable log_cum_avg_plant "Log Avg. Size"

label variable log_cum_ac_cap "Log Total Capacity"
label variable log_ac_cap "Log Capacity Additions"

label variable log_n_plants "Log # Plants Added"
label variable log_cum_n_plants "Log Total # Plants"

label variable cum_avg_cap "Avg. plant size"
label variable avg_cap_ac "Avg. new plant size"

gen log_avg_cap = log(avg_cap_ac + 1)
label variable log_avg_cap "Log avg. size"

// Create non-QF variables for robustness checks
global outcomes "n_plants ac_cap_added"
foreach i in $outcomes{
    gen `i'_non_qf = `i' - `i'_qf
    gen log_`i'_non_qf = log(`i'_non_qf + 1)
}

**********************************************
****
**** Controls
****
**********************************************

gen log_acres = log(acres)
gen log_cf = log(nrel_cap_factor)

global controls "log_cf log_acres log_pop retail_choice log_gdp"
global retail_controls "p_public_sales_2016 p_retail_sales_2016"

label variable log_cf "Log Capacity Factor"
label variable nrel_cap_factor "Capacity Factor"

label variable acres "Acres"
label variable log_acres "Log acres"

label variable p_retail_sales_2016 "% Retail Sales (2016)"
label variable p_iou_sales_2016 "% IOU Sales (2016)"
label variable retail_choice "Retail Choice?"
label variable iso_rto_dummy "ISO/RTO?"

label variable log_pop "Log population"
label variable log_sales "Log retail sales"

gen log_gdp = log(gdp)
label variable log_gdp "Log GDP"

gen n_years_rps = year - first_yr_tot_rps_lbl
gen n_years_srps = year - first_yr_solar_rps_manual
gen n_years_any_plant = year - first_plant_year
gen n_years_qf = year - first_qf_year

global n_years "n_years_rps n_years_srps n_years_any_plant n_years_qf"

foreach i in $n_years{
    replace `i' = 0 if `i' < 0 | `i' == .
}

egen n_plant_years = group(n_years_any_plant), label

**********************************************
****
**** Event study plots
****
**********************************************

sort state_code year 
by state_code: gen datenum = _n 
by state_code: gen target = datenum if year == first_plant_year
egen td=min(target), by(state_code)
drop target
gen event_time_first_plant=datenum-td
drop td

replace event_time_first_plant = 0 if event_time_first_plant ==. 
label variable event_time_first_plant "Year relative to state's first 5 MW project" 

// foreach outcome in "n_plants ac_cap_added avg_cap_ac"{
//     preserve
//     collapse (mean) `outcome', by(event_time_first_plant)
//     twoway line `outcome' event_time_first_plant
// //     graph export `i'_event_study.png, replace
// 	graph export fig32.png, width(400) replace
// 	graph drop
//     restore
// }

preserve
collapse (mean) log_n_plants , by(event_time_first_plant)
twoway line log_n_plants  event_time_first_plant
restore

// foreach outcome in "log_n_plants log_ac_cap log_avg_cap"{
//     preserve
//     collapse (mean) `outcome', by(event_time_first_plant)
//     twoway line `outcome' event_time_first_plant
    
//     restore
// }


// sort state_code year 
// by state_code: gen datenum = _n 
// by state_code: gen target = datenum if year == first_qf_year 
// egen td=min(target), by(state_code)
// by state_code: replace td = 2010-first_qf_year if td == .
// drop target
// gen event_time_qf=datenum-td
// drop td

// replace event_time_qf = 0 if event_time_qf <= -2000

esplot log_n_plants event_time_first_plant, absorb(year)
