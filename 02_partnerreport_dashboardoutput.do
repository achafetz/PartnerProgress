**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: generate output for Excel monitoring dashboard
**   Date: June 20, 2016
**   Updated: 7/16/16

/* NOTES
	- Data source: ICPIFactView - SNU by IM Level_db-frozen_20160617 [Data Hub]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across HTC_TST, HTC_TST_POS, PMTCT_STAT, PMTCT_ARV, PMTCT_EID,
		TX_NEW, TX_CURR, OVC_SERV, VMMC_CIRC		
*/
********************************************************************************

*import data
	import delimited "$data\PSNU_IM_20160715.txt", clear
	save "$output\ICPIFactView_SNUbyIM.dta", replace 
	use "$output\ICPIFactView_SNUbyIM.dta", clear
	
*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST Positives & TX_NET_NEW --> need to "create" new var
	gen key_ind=indicator if (inlist(indicator, "HTC_TST", "CARE_NEW", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", "TX_CURR", ///
		"OVC_SERV", "VMMC_CIRC") | inlist(indicator, "TB_STAT", "TB_ART", ///
		"KP_PREV", "PP_PREV", "CARE_CURR")) & disaggregate=="Total Numerator"
	
	*HTC_TST_POS indicator
	replace key_ind="HTC_TST_POS" if indicator=="HTC_TST" & ///
		resultstatus=="Positive" & disaggregate=="Results" 
		
	*TX_NET_NEW indicator
		expand 2 if key_ind=="TX_CURR" & , gen(new) //create duplicate of TX_CURR
			replace key_ind= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
			drop new
		*create copy periods to replace . w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach x in fy2015q2 fy2015q4 fy2016q2 fy2016_targets{
			clonevar `x'_cc = `x' 
			recode `x'_cc (. = 0) 
			}
			*end
		*create net new variables
		gen fy2015q4_nn = fy2015q4_cc-fy2015q2_cc
		gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
		gen fy2016_targets_nn = fy2016_targets_cc - fy2015q4_cc
		drop *_cc	
		*replace period values with net_new
		foreach x in fy2015q4 fy2016q2 fy2016_targets {
			replace `x' = `x'_nn if key_ind=="TX_NET_NEW"
			drop `x'_nn
			}
			*end
		
*create SAPR variable to sum up necessary variables
	egen fy2016sapr = rowtotal(fy2016q1 fy2016q2)
		replace fy2016sapr = fy2016q2 if inlist(indicator, "TX_CURR", ///
			"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		replace fy2016sapr =. if fy2016sapr==0 //should be missing
	
* delete extrainous vars/obs
	*drop if fundingagency=="Dedup" // looking at each partner individually
	drop if key_ind=="" //only need data on key indicators
	rename ïregion region
	rename key_ind indicator
	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016sapr
	order region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016sapr


*export full dataset
	local date = subinstr("`c(current_date)'", " ", "", .)
	export delimited using "$excel\ICPIFactView_SNUbyIM_GLOBAL_`date'", nolabel replace dataf

*set up to loop through countries
	qui:levelsof operatingunit, local(levels)
	local date = subinstr("`c(current_date)'", " ", "", .)
	foreach ou of local levels {
		preserve
		di "export dataset: `ou' "
		qui:keep if operatingunit=="`ou'" 
		qui: export delimited using "$excel\ICPIFactView_SNUbyIM_`date'_`ou'", ///
			nolabel replace dataf
		restore
		}
		*end
