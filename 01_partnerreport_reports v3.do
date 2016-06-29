**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz
**   Purpose: identify underachieving partners
**   Date: June 20, 2016
**   Updated: JTD on June 28 2016

/* NOTES
	- Data source: ICPIFactView - SNU by IM Level_db-frozen_20160617 [Data Hub]
	- Current scope limited to Tanzania
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across HTC_TST, HTC_TST_POS, PMTCT_STAT, PMTCT_ARV, PMTCT_EID,
		TX_NEW, TX_CURR, OVC_SERV, VMMC_CIRC		
*/

*import data
	import delimited "$data\ICPIFactView - SNU by IM Level_db-frozen_20160617.txt", clear
	save "$output\ICPIFactView_SNUbyIM.dta", replace 

**********************************************************************************************
*set up to loop through countries

qui:levelsof operatingunit, local(levels)

foreach o of local levels {

*subset
	keep if operatingunit=="`o'"

	
*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""
	
*total number of partners
	encode primepartner, gen(pp)

* create key vars

gen key_ind=indicator if inlist(indicator, "HTC_TST", "CARE_NEW", "PMTCT_STAT", "PMTCT_ARV", ///
 "PMTCT_EID", "TX_NEW", "TX_CURR", "OVC_SERV", "VMMC_CIRC") | inlist(indicator, "TB_STAT", "TB_ART" ///
 "KP_PREV", "PP_PREV") & disaggregate=="Total Numerator"


 *HTC_TST_POS indicator

 replace key_ind="HTC_TST_POS" if indicator=="HTC_TST" & resultstatus=="Positive" & inlist(disaggregate, "Age/Sex/Result", "Age/Sex Aggregated/Result")

* TX_NEW_<1
	replace key_ind="TX_NEW_<1"	if indicator=="TX_NEW" & age=="<01"	

* Delete Extrainous
	keep if key_ind!=""
	drop regionuid operatingunituid mechanismuid fy2015*

* Export to excel

export delimited using "$excel\ICPIFactView_SNUbyIM `o'", nolabel replace dataf


u "$output\ICPIFactView_SNUbyIM.dta", clear

}
*
