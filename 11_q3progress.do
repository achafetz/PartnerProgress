
*set today's date for saving
	global date = subinstr("`c(current_date)'", " ", "", .)
	
*set date of frozen instance - needs to be changed w/ updated data
	global datestamp "20170702_v2_1"
	
*import/open data
	use "$fvdata/ICPI_FactView_OU_IM_${datestamp}.dta", clear


*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST Positives & TX_NET_NEW --> need to "create" new var
	gen key_ind=indicator if ///
		inlist(indicator, "HTS_TST", "HTS_TST_POS", "TX_NEW", "TX_CURR", ///
		"TX_NET_NEW", "PMTCT_STAT")& disaggregate=="Total Numerator"
	
	*add future quarters in 
	foreach x in q2 q3 q4 apr{
		capture confirm variable fy2017`x'
		if _rc gen fy2017`x' = .
		}
		*end
		
	*create cumulative variable to sum up necessary variables
		egen fy2017cum = rowtotal(fy2017q*)
			replace fy2017cum = . if fy2017cum==0
		*for Q2
		local i 2 
		replace fy2017cum = fy2017q`i' if inlist(key_ind, "OVC_SERV", ///
			"TX_CURR")
		replace fy2017cum =. if fy2017cum==0 //should be missing
		/*capture confirm variable fy2017apr
			if !_rc replace fy2017cum = fy2017apr */

********************************************************************************
egen kp = rowtotal(fy2016q1 fy2016q2 fy2016q3 fy2016q4 fy2016_targets fy2017q1 fy2017q2 fy2017_targets)
drop if kp==0
drop kp

	drop if key_ind=="" //only need data on key indicators
	drop indicator
	rename key_ind indicator
	order indicator, after(implementingmechanismname)
	
collapse (sum) fy*, by(operatingunit primepartner fundingagency mechanismid implementingmechanismname indicator)

preserve
keep operatingunit primepartner fundingagency mechanismid implementingmechanismname indicator *targets *apr *cum
save "$output/extradata.dta", replace
restore

********************************************************************************

drop *targets *apr *cum
egen id = group(operatingunit primepartner fundingagency mechanismid implementingmechanismname indicator)
reshape long fy, i(id) j(qtr, string)

drop id
egen pnl = group(operatingunit primepartner fundingagency mechanismid implementingmechanismname indicator)
recode fy (0 = .)
gen qdate = quarterly(qtr, "YQ")

tsset pnl qdate

gen gr = D.fy/L.fy

format qdate %tq

egen ind_avg = group(operatingunit indicator)
bysort pnl: egen ma_gr_q3 = mean(gr) if inrange(qdate,224,230)
bysort ind_avg: egen ma_gr_q3_overall = mean(gr) if inrange(qdate,224,230)

bysort pnl: egen ma_gr_q4 = mean(gr) if inrange(qdate,225,231)
bysort ind_avg: egen ma_gr_q4_overall = mean(gr) if inrange(qdate,225,231)  

gen ma = ma_gr_q3 if qdate==230
	replace ma = ma_gr_q3_overall if ma_gr_q3==. & qdate==230
	replace ma = ma_gr_q4 if qdate==231
	replace ma = ma_gr_q4_overall if ma_gr_q4==. & qdate==231

sort pnl qdate indicator
replace fy = round((1+ ma) * L.fy, 1) if qdate==230
replace fy = round((1+ ma) * L2.fy, 1) if qdate==231

drop qdate-ma
reshape wide fy, i(pnl) j(qtr, string)
drop pnl

order operatingunit-indicator

merge 1:1 operatingunit primepartner fundingagency mechanismid ///
	implementingmechanismname indicator using "$output/extradata.dta", nogen
	
	order fy2015apr fy2016_targets, after(fy2015q4)
	order fy2016apr fy2017_targets, after(fy2016q4)

egen fy2017apr_p = rowtotal(fy2017q1 fy2017q2 fy2017q3 fy2017q4)
	replace fy2017apr_p = fy2017q4 if inlist(indicator, "TX_CURR", "OVC_SERV")
	replace fy2017apr = fy2017apr_p

recode fy2017apr (0 = .)	

keep if fundingagency=="USAID"			
		
********************************************************************************
	*TX_NET_NEW indicator
		expand 2 if indicator== "TX_CURR", gen(new) //create duplicate of TX_CURR
			replace indicator= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
			drop new
		*create copy periods to replace "." w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach x in fy2015q2 fy2015q4 fy2016q2 fy2016q4 fy2017q1 fy2017q2 fy2017q3 fy2017q4 fy2017_targets{
			clonevar `x'_cc = `x'
			recode `x'_cc (. = 0) 
			}
			*end
		*create net new variables (tx_curr must be reporting in both pds)
		gen fy2015q4_nn = fy2015q4_cc-fy2015q2_cc
			replace fy2015q4_nn = . if (fy2015q4==. & fy2015q2==.)
		gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
			replace fy2016q2_nn = . if (fy2016q2==. & fy2015q4==.)
		gen fy2016q4_nn = fy2016q4_cc-fy2016q2_cc
			replace fy2016q4_nn = . if (fy2016q4==. & fy2016q2==.)
		egen fy2016apr_nn = rowtotal(fy2016q2_nn fy2016q4_nn)
		gen fy2017q1_nn = fy2017q1_cc-fy2016q4_cc
			replace fy2017q1_nn = . if (fy2017q1==. & fy2016q4==.)
		gen fy2017q2_nn = fy2017q2_cc-fy2017q1_cc
			replace fy2017q2_nn = . if (fy2017q2==. & fy2017q1==.)
		gen fy2017q3_nn = fy2017q3_cc-fy2017q2_cc
			replace fy2017q3_nn = . if (fy2017q3==. & fy2017q2==.)	
		gen fy2017q4_nn = fy2017q4_cc-fy2017q3_cc
			replace fy2017q4_nn = . if (fy2017q4==. & fy2017q3==.)	
		gen fy2017_targets_nn = fy2017_targets_cc - fy2016q4_cc
			replace fy2017_targets_nn = . if fy2017_targets==. & fy2016q4==.
		egen fy2017apr_nn = rowtotal(fy2017q1_nn fy2017q2_nn fy2017q3_nn fy2017q4_nn)
		drop *_cc
		*replace raw period values with generated net_new values
		foreach x in fy2015q4 fy2016q2 fy2016q4 fy2016apr fy2017q1 fy2017q2 fy2017q3 fy2017q4 fy2017apr fy2017_targets{
			replace `x' = `x'_nn if key_ind=="TX_NET_NEW"
			drop `x'_nn
			}
			*end
		*remove tx net new values for fy15
		foreach pd in fy2015q2 fy2015q3 fy2015apr {
			replace `pd' = . if indicator=="TX_NET_NEW"
			}
			*end
* delete extrainous vars/obs

	local vars operatingunit ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016q3 fy2016q4 fy2016apr fy2017_targets ///
		fy2017q1 fy2017q2 fy2017q3 fy2017q4 fy2017apr fy2017cum
	keep `vars'
	order `vars'
	
		
	
*update all partner and mech to offical names (based on FACTS Info)
	*tostring mechanismid, replace
	preserve
	run 06_partnerreport_officalnames
	restore
	merge m:1 mechanismid using "$output/officialnames.dta", ///
		update replace nogen keep(1 3 4 5) //keep all but non match from using

*export
	export delimited using "$excel/progressq3", nolabel replace dataf
