**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: generate output for Excel monitoring dashboard
**   Date: June 20, 2016
**   Updated: JTD on June 28 2016

/* NOTES
	- Data source: ICPIFactView - SNU by IM Level_db-frozen_20160617 [Data Hub]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across HTC_TST, HTC_TST_POS, PMTCT_STAT, PMTCT_ARV, PMTCT_EID,
		TX_NEW, TX_CURR, OVC_SERV, VMMC_CIRC		
*/
********************************************************************************

*import data
	import delimited "$data\ICPIFactView - SNU by IM Level_db-frozen_20160617.txt", clear
	save "$output\ICPIFactView_SNUbyIM.dta", replace 
	*use "$output\ICPIFactView_SNUbyIM.dta", clear
	
*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only ones of interest for analysis
	* most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST, Positives & TX_CURR <1 --> need to "create"
	gen key_ind=indicator if (inlist(indicator, "HTC_TST", "CARE_NEW", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", "TX_CURR", ///
		"OVC_SERV", "VMMC_CIRC") | inlist(indicator, "TB_STAT", "TB_ART" ///
		"KP_PREV", "PP_PREV")) & disaggregate=="Total Numerator"
	*HTC_TST_POS indicator
	replace key_ind="HTC_TST_POS" if indicator=="HTC_TST" & ///
		resultstatus=="Positive" & ///
		inlist(disaggregate, "Age/Sex/Result", "Age/Sex Aggregated/Result")
	* TX_NEW_<1 indicator
	replace key_ind="TX_NEW_<1"	if indicator=="TX_NEW" & age=="<01"	

* Delete Extrainous
	*drop if fundingagency=="Dedup" // looking at each partner individually
	drop if key_ind=="" //only need data on key indicators
	rename key_ind indicator
	order indicator,  before(numeratordenom) //place it back where indicator was located
	drop regionuid operatingunituid mechanismuid fy2015* indicator
	
*export full dataset
	export delimited using "$excel\ICPIFactView_SNUbyIM_GLOBAL", nolabel replace dataf

*set up to loop through countries
	qui:levelsof operatingunit, local(levels)
	foreach o of local levels {
		export delimited using "$excel\ICPIFactView_SNUbyIM `o'", ///
			if operatingunit=="`o'" ///
			nolabel replace dataf
		}
		*end
