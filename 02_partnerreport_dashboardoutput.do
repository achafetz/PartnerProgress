**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: generate output for Excel monitoring dashboard
**   Date: June 20, 2016
**   Updated: 7/6/16

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
	use "$output\ICPIFactView_SNUbyIM.dta", clear
	
*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST, Positives & TX_CURR <1 --> need to "create" new var
	gen key_ind=indicator if (inlist(indicator, "HTC_TST", "CARE_NEW", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", "TX_CURR", ///
		"OVC_SERV", "VMMC_CIRC") | inlist(indicator, "TB_STAT", "TB_ART" ///
		"KP_PREV", "PP_PREV")) & disaggregate=="Total Numerator"
	
	*HTC_TST_POS indicator
	replace key_ind="HTC_TST_POS" if indicator=="HTC_TST" & ///
		resultstatus=="Positive" & disaggregate=="Results" 
		*inlist(disaggregate, "Age/Sex/Result", "Age/Sex Aggregated/Result") //alternative to using Results disagg
	/* NOT USING TX_NEW CURRENTLY
	* TX_NEW_<1 indicator
	replace key_ind="TX_NEW_<1"	if indicator=="TX_NEW" & age=="<01"	
	*/
*rename disaggs
	replace disaggregate="TOTAL NUMERATOR" if disaggregate=="Total Numerator"
	replace disaggregate="FINER" if inlist(disaggregate, ///
			"Age/Sex/Result", "Age/Sex")
	replace disaggregate="COARSE" if inlist(disaggregate, ///
			"Age/Sex Aggregated/Result", "Age/Sex Aggregated")
*create SAPR variable to sum up necessary variables
	egen fy2016sapr = rowtotal(fy2016q1 fy2016q2)
		replace fy2016sapr = fy2016q2 if inlist(indicator, "TX_CURR", ///
			"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV")
		replace fy2016sapr =. if fy2016sapr==0 //should be missing
*adjust age for output so Excel does not interpret as date
	*gen age2 = "'" + age if age!=""
	
* delete extrainous vars/obs
	*drop if fundingagency=="Dedup" // looking at each partner individually
	drop if key_ind=="" //only need data on key indicators
	drop regionuid operatingunituid mechanismuid indicator-coarsedisaggregate fy2016apr
	rename ïregion region
	rename key_ind indicator
	*rename age2 age
	order indicator,  after(implementingmechanismname) //place it back where indicator was located
	*order age, before(sex)
	
*export full dataset
	local date = subinstr("`c(current_date)'", " ", "", .)
	export delimited using "$excel\ICPIFactView_SNUbyIM_GLOBAL_`date'", nolabel replace dataf

*set up to loop through countries
	qui:levelsof operatingunit, local(levels)
	local date = subinstr("`c(current_date)'", " ", "", .)
	foreach ou of local levels {
		preserve
		di "`ou'"
		keep if operatingunit=="`ou'" 
		export delimited using "$excel\ICPIFactView_SNUbyIM_`date'_`ou'", ///
			nolabel replace dataf
		restore
		}
		*end


**** Finer/Coarse Comparison/Completeness Check ***
	*export tables to Excel for comparison		
		
*TX_NEW
	tab operatingunit disaggregate if indicator=="TX_NEW" & age=="<01" //freq
	table operatingunit disaggregate if indicator=="TX_NEW", c(sum fy2016sapr sum fy2016_targets)
	table operatingunit disaggregate if indicator=="TX_NEW" & age=="<01", c(sum fy2016sapr sum fy2016_targets) m
		
*HTC_TST
	tab operatingunit disaggregate if indicator=="HTC_TST" //freq
	table operatingunit disaggregate if indicator=="HTC_TST" & inlist(disaggregate,"Age/Sex/Result", "Age/Sex Aggregated/Result", "Total Numerator"), c(sum fy2016sapr sum fy2016_targets) m
	table operatingunit disaggregate if indicator=="HTC_TST" & inlist(disaggregate,"Age/Sex/Result", "Age/Sex Aggregated/Result") & resultstatus=="Positive", c(sum fy2016sapr sum fy2016_targets) m
