**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: generate output for Excel monitoring dashboard
**   Date: June 20, 2016
**   Updated: 11/21/2016

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160822 [ICPI Data Store]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across HTC_TST, HTC_TST_POS, PMTCT_STAT, PMTCT_STAT_POS, 
		PMTCT_ARV, PMTCT_EID, TB_STAT, TB_STAT_POS, TB_ART, TX_NEW, TX_CURR,
		OVC_SERV, VMMC_CIRC, KP_PREV, PP_PREV, and CARE_CURR
*/
********************************************************************************

*Which outputs to produce? 0 = No, 1 = Yes
	global global_output 0	 //full global dataset
	global ctry_output 1 	//one dataset for every OU
	global sel_output 0	//just an outut for select OU specified below
	global sel_output_list "Mozambique"  //OU selection
	global site_app 0 //append site data
	
*set today's date for saving
	global date = subinstr("`c(current_date)'", " ", "", .)
	
*set date of frozen instance - needs to be changed w/ updated data
	global datestamp "20161115"
	
*import/open data
	capture confirm file "$output\ICPIFactView_SNUbyIM${datestamp}.dta"
		if !_rc{
			use "$output\ICPIFactView_SNUbyIM${datestamp}.dta", clear
		}
		else{
			import delimited "$data\ICPI_Fact_View_PSNU_IM_${datestamp}.txt", clear
			save "$output\ICPIFactView_SNUbyIM${datestamp}.dta", replace
		}
	*end

*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST Positives & TX_NET_NEW --> need to "create" new var
	gen key_ind=indicator if (inlist(indicator, "HTC_TST", "CARE_NEW", ///
		"PMTCT_STAT", "PMTCT_ARV", "PMTCT_EID", "TX_NEW", "TX_CURR", ///
		"OVC_SERV", "VMMC_CIRC") | inlist(indicator, "TB_STAT", "TB_ART", ///
		"KP_PREV", "PP_PREV", "CARE_CURR", "TX_RET", "TX_VIRAL", "TX_UNDETECT", ///
		"GEND_GBV") | inlist(indicator, "GEND_NORM", "KP_MAT", "PMTCT_FO", ///
		"TB_SCREEN")) & disaggregate=="Total Numerator"
	
	*denominators
	foreach x in "TB_STAT" "TB_ART"{
		replace key_ind = "`x'_D" if indicator=="`x'" & ///
		disaggregate=="Total Denominator"
		}
		*end
	
	*HTC_TST_POS & TB_STAT_POS indicator
	replace disaggregate="Results" if disaggregate=="Result"
	foreach x in "HTC_TST" "TB_STAT" {
		replace key_ind="`x'_POS" if indicator=="`x'" & ///
		resultstatus=="Positive" & disaggregate=="Results"
		}
		*end
		
	*PMTCT_STAT_POS
	replace key_ind="PMTCT_STAT_POS" if indicator=="PMTCT_STAT" & ///
		disaggregate=="Known/New"

	*TX_NET_NEW indicator
			expand 2 if key_ind=="TX_CURR" & , gen(new) //create duplicate of TX_CURR
			replace key_ind= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
			drop new
		*create copy periods to replace "." w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach x in fy2015q4 fy2016q2 fy2016q4 fy2016_targets{
			clonevar `x'_cc = `x'
			recode `x'_cc (. = 0)
			}
			*end
		*create net new variables (tx_curr must be reporting in both pds)
		gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
			replace fy2016q2_nn = . if (fy2016q2==. & fy2015q4==.)
		gen fy2016q4_nn = fy2016q4_cc-fy2016q2_cc
			replace fy2016q4_nn = . if (fy2016q4==. & fy2016q2==.)
		gen fy2016_targets_nn = fy2016_targets_cc - fy2015q4_cc
			replace fy2016_targets_nn = . if fy2016_targets==. & fy2015q4==.
		drop *_cc
		*replace raw period values with generated net_new values
		foreach x in fy2016q2 fy2016q4 fy2016_targets {
			replace `x' = `x'_nn if key_ind=="TX_NET_NEW"
			drop `x'_nn
			}
			*end
		*remove tx net new values for fy15
		foreach pd in fy2015q2 fy2015q3 fy2015q4 fy2015apr {
			replace `pd' = . if key_ind=="TX_NET_NEW"
			}
			*end
			
	*create SAPR and cumulative variable to sum up necessary variables
		local i 2
		foreach agg in "sapr" "cum" {
			if "`agg'"=="sapr" egen fy2016`agg' = rowtotal(fy2016q1 fy2016q2)
				else egen fy2016`agg' = rowtotal(fy2016q*)
			replace fy2016`agg' = fy2016q`i' if inlist(key_ind, "TX_CURR", ///
				"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR", ///
				"TB_ART", "TX_RET", "TX_VIRAL") | inlist("TX_UNDETECT", ///
				"GEND_GBV", "GEND_NORM", "KP_MAT", "PMTCT_FO", "TB_SCREEN")
			replace fy2016`agg' =. if fy2016`agg'==0 //should be missing
			local i = `i' + 2
			}
			*end
		replace fy2016cum = fy2016apr
		
*delete reporting that shouldn't have occured
	/*
	tabstat fy2015q3 fy2016q1 fy2016q3 if inlist(indicator, "TX_CURR", ///
		"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR"), ///
		s(sum count) by(operatingunit)
	*/
	ds *q1 *q3
	foreach pd in `r(varlist)'{
		replace `pd'=. if inlist(key_ind, "TX_CURR", ///
			"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR", ///
			"TB_ART", "TX_RET", "TX_VIRAL") | inlist("TX_UNDETECT", ///
			"GEND_GBV", "GEND_NORM", "KP_MAT", "PMTCT_FO", "TB_SCREEN")
		}
		*end
* delete extrainous vars/obs
	drop if key_ind=="" //only need data on key indicators
	drop indicator
	rename ïregion region
	rename key_ind indicator
	local vars region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016q4 fy2016apr ///
		fy2016cum 
	keep `vars'
	order `vars'

*append all site
	if $site_app == 1 {
		append using "$output\ICPIFactView_SiteIM_${date}_ALLTX"
		}
	else{
		gen facilityuid = .
		gen facilityprioritization = .
		}
	order facilityuid facilityprioritization, before(indicator)
	
	
*export full dataset
	if $global_output == 1 {
		di "GLOBAL OUTPUT"
		export delimited using "$excel\ICPIFactView_SNUbyIM_GLOBAL_${date}", ///
		nolabel replace dataf
		}
		*end
	
*set up to loop through countries
	if $ctry_output == 1{
		di "COUNTRY OUTPUT"
		if $sel_output == 1 {
			keep if inlist(operatingunit, "$sel_output_list")
			}
		qui:levelsof operatingunit, local(levels)
		foreach ou of local levels {
			preserve
			qui:keep if operatingunit=="`ou'"
			qui: order facilityuid facilityprioritization, before(indicator)
			di in yellow "export dataset: `ou' "
			qui: export delimited using "$excel\ICPIFactView_SNUbyIM_${date}_`ou'", ///
				nolabel replace dataf
			restore
			}
			}
			*end
