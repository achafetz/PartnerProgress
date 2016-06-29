**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz
**   Purpose: identify underachieving partners
**   Date: June 20, 2016
**   Updated: 

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
*subset
	keep if operatingunit=="Tanzania"
	save "$output\ICPIFactView_SNUbyIM_TNZ.dta", replace
	
*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""
	
*total number of partners
	encode primepartner, gen(pp)
	sum pp
	di "Number of partners: `r(max)'"

*create HTC_TST_POS indicator
	expand 2 if indicator == "HTC_TST" & inlist(disaggregate, "Age/Sex/Result", ///
		"Age/Sex Aggregated/Result") & resultstatus=="Positive", gen(new)
		replace indicator = "HTC_TST_POS" if new==1
		drop new
*create SAPR variable to sum up necessary variables
	ds, has(varl "FY2016Q*")
	egen fy2016sapr = rowtotal(`r(varlist)')
		replace fy2016sapr = fy2016q2 if inlist(indicator, "TX_CURR", "OVC_SERV", "PMTCT_ARV")
		replace fy2016sapr =. if fy2016sapr==0

*subset to just necessary variables
	keep if (inlist(indicator, "HTC_TST", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", ///
		"TX_CURR", "OVC_SERV", "VMMC_CIRC") & disaggregate=="Total Numerator") | ///
		(indicator=="HTC_TST_POS" & resultstatus=="Positive" & disaggregate=="Age/Sex/Result")

*relabel variables for export
	lab var fy2016sapr "SAPR Results"
	lab var fy2016_targets "FY2016 Targets"
	lab var snuprioritization "Prioritization"
	lab var psnu "Priority SNU"
	
	
/// OU VIEW ///

preserve
*aggregate up indicators
	collapse (sum) fy2016sapr fy2016_targets ///
		if inlist(indicator, "HTC_TST", "HTC_TST_POS", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", ///
		"TX_CURR", "OVC_SERV", "VMMC_CIRC"), by(indicator)
*generate progress pct
	gen progress = fy2016sapr/fy2016_targets
		lab var progress "Progress towards FY15 COP Target"
*format 
	format fy* %13.0fc
	format progress %5.2f
	lab var indicator "Indicator"
	lab var fy2016sapr "SAPR Results"
	lab var fy2016_targets "FY2016 Targets"
*export
	export excel "$excel\PartnerReport_TNZ.xlsx", sheet("OU") sheetreplace firstrow(varl)
restore

/// PRIORITIZATION VIEW ///	
	
preserve
*aggregate up indicators
	collapse (sum) fy2016sapr fy2016_targets ///
		if inlist(indicator, "HTC_TST", "HTC_TST_POS", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", ///
		"TX_CURR", "OVC_SERV", "VMMC_CIRC"), by(snuprioritization indicator)
*generate progress pct
	gen progress = fy2016sapr/fy2016_targets
		lab var progress "Progress towards FY15 COP Target"
*format 
	format fy* %13.0fc
	format progress %5.2f
	lab var indicator "Indicator"
	lab var fy2016sapr "SAPR Results"
	lab var fy2016_targets "FY2016 Targets"
*export
	export excel "$excel\PartnerReport_TNZ.xlsx", sheet("Priority") sheetreplace firstrow(varl)
restore


/// PSNU VIEW ///	
	
preserve
*aggregate up indicators
	collapse (sum) fy2016sapr fy2016_targets ///
		if inlist(indicator, "HTC_TST", "HTC_TST_POS", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", ///
		"TX_CURR", "OVC_SERV", "VMMC_CIRC"), by(indicator psnu)
*generate progress pct
	gen progress = fy2016sapr/fy2016_targets
		lab var progress "Progress towards FY15 COP Target"
*format 
	format fy* %13.0fc
	format progress %5.2f
	lab var indicator "Indicator"
	lab var fy2016sapr "SAPR Results"
	lab var fy2016_targets "FY2016 Targets"
	lab var snuprioritization "Priority SNU"
*export
	export excel "$excel\PartnerReport_TNZ.xlsx", sheet("PSNU") sheetreplace firstrow(varl)
restore

/// MECHANISM VIEW ///	
	
preserve
*aggregate up indicators
	collapse (sum) fy2016sapr fy2016_targets ///
		if inlist(indicator, "HTC_TST", "HTC_TST_POS", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", ///
		"TX_CURR", "OVC_SERV", "VMMC_CIRC"), by(snuprioritization indicator psnu implementingmechanismname)
*generate progress pct
	gen progress = fy2016sapr/fy2016_targets
		lab var progress "Progress towards FY15 COP Target"
*format 
	format fy* %13.0fc
	format progress %5.2f
	lab var indicator "Indicator"
	lab var fy2016sapr "SAPR Results"
	lab var fy2016_targets "FY2016 Targets"
	lab var snuprioritization "Priority SNU"
	lab var implementingmechanismname "IM Name"
*export
	export excel "$excel\PartnerReport_TNZ.xlsx", sheet("IM") sheetreplace firstrow(varl)
restore


	
		
		
		
		
		