**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: generate DREAMS output for Excel monitoring dashboard
**   Date: Sept 8, 2016
**   Updated: 10/27/16

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160822 [ICPI Data Store]
	- Similar process run in 02_partnerreport_dashboardoutput
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across DREAMS indicators
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	local datestamp "20161010"
*import/open data
	capture confirm file "$output\ICPIFactView_SNUbyIM_DREAMS_`datestamp'.dta"
		if !_rc{
			use "$output\ICPIFactView_SNUbyIM_DREAMS_`datestamp'.dta", clear
		}
		else{
			import delimited "$data\PSNU_IM_DREAMS_`datestamp'.txt", clear
			save "$output\ICPIFactView_SNUbyIM_DREAMS_`datestamp'.dta", replace
		}
	*end
/*
*import SNU by IM data for non DREAMS countries
	local datestamp "20161010"
	use "$output\ICPIFactView_SNUbyIM`datestamp'.dta", clear
	keep if inlist(operatingunit, "Namibia", "Ethiopia", "Cote d'Ivoire", "Botswana") 
*/

*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	replace indicator="PREP_NEW" if indicator=="PrEP_NEW"
	gen key_ind=""
	replace key_ind = indicator if ///
		(inlist(indicator, "HTC_TST", "TX_NEW")	& ///
			inlist(age, "10-14", "15-19", "20-24") & ///
			inlist(disaggregate, "Age/Sex", "Age/Sex/Result")) | ///
		(inlist(indicator, "HTC_TST", "TX_NEW") & age=="25-49" & sex=="male") | ///
		(indicator=="VMMC_CIRC" & ///
			inlist(age, "10-14", "15-19", "20-24", "25-29")) | ///
		(indicator=="PMTCT_STAT" & disaggregate=="Known/New/Age") | ///
		(indicator=="PREP_NEW" & inlist(age, "15-19", "20-24")) | ///
		(indicator=="PP_PREV" & inlist(age, "10-14", "15-19", "20-24")) | ///
		(indicator=="TX_CURR" & inlist(age, "5-14", "15-19", "20+")) | ///
		(indicator=="OVC_SERV" & disaggregate=="Age/Sex" & ///
			inlist(age, "10-14", "15-17", "18-24") & inlist(otherdisaggregate, ///
			"Economic Strengthening", "Education Support", ///
			"Other Service Areas", "Parenting/Caregiver Programs", ///
			"Social Protection"))  | /// 
		(indicator=="KP_PREV" & otherdisaggregate=="FSW")
			
		/* add for Q4
		(indicator=="GEND_GBV" & sex=="Female" & ///
			inlist(age, "10-14", "15-17", "18-24")) |
		(indicator="TX_RET" & inlist(age, "5-14", "15-19", "20+"))
		*/
		
	replace key_ind="PMTCT_STAT_POS" if indicator=="PMTCT_STAT" & ///
		disaggregate=="Known/New/Age"
	replace key_ind="KP_PREV_FSW" if indicator=="KP_PREV"
	
*create SAPR and cumulative variable to sum up necessary variables
	foreach agg in "sapr" "cum" {
		if "`agg'"=="sapr" egen fy2016`agg' = rowtotal(fy2016q1 fy2016q2)
			else egen fy2016`agg' = rowtotal(fy2016q*)
		replace fy2016`agg' = fy2016q2 if inlist(indicator, "TX_CURR", ///
			"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		replace fy2016`agg' =. if fy2016`agg'==0 //should be missing
		}
		*end
*
	foreach pd in fy2015q3 fy2016q1 fy2016q3{
		replace `pd'=. if inlist(indicator, "TX_CURR", "OVC_SERV", ///
			"PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		}
*delete reporting that shouldn't have occured
	tabstat fy2015q3 fy2016q1 fy2016q3 if inlist(indicator, "TX_CURR", ///
		"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR"), ///
		s(sum count) by(operatingunit)	
	foreach pd in fy2015q3 fy2016q1 fy2016q3{
		replace `pd'=. if inlist(indicator, "TX_CURR", "OVC_SERV", ///
			"PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		}
* delete extrainous vars/obs
	drop if key_ind=="" //only need data on key indicators
	drop indicator
	rename ïregion region
	rename key_ind indicator
	capture confirm variable dsnu
		if !_rc{
		drop psnu psnuuid
		rename dsnu psnu
		rename dsnuuid psnuuid
		}
	gen facilityuid	= ""
	gen facilityprioritization =""

	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		facilityuid facilityprioritization indicator age sex otherdisaggregate ///
		fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016cum
	order region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		facilityuid facilityprioritization indicator age sex otherdisaggregate ///
		fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016cum

/*
*save extra DREAMS countries for merging onto DREAMS dataset
	local date = subinstr("`c(current_date)'", " ", "", .)
	save "$output\ICPIFactView_SNUbyIM_DREAMS_extras_`date'", replace
*/
*export full dataset
	local date = subinstr("`c(current_date)'", " ", "", .)
	export delimited using "$excel\ICPIFactView_SNUbyIM_DREAMS_GLOBAL_`date'", nolabel replace dataf
/*
*merge DREAMS + additional 4 OUs
	local date = subinstr("`c(current_date)'", " ", "", .)
	append using "$output\ICPIFactView_SNUbyIM_DREAMS_extras_`date'"
	export delimited using "$excel\ICPIFactView_SNUbyIM_DREAMS_GLOBAL+_`date'", nolabel replace dataf
*/
