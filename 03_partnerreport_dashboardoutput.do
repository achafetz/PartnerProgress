**   Partner Performance by SNU
**   COP FY17
**   Aaron Chafetz
**   Purpose: generate output for Excel monitoring dashboard
**   Date: June 20, 2016
**   Updated: 8/29/17

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM  [ICPI Data Store]
	- Report aggregates DSD and TA
	- Report uses Totals and MCAD
*/
********************************************************************************

*Which outputs to produce? 0 = No, 1 = Yes
	global global_output 0 //full global dataset
	global equip_output 0 //full global dataset
	global ctry_output 1 	//one dataset for every OU
	global sel_output 0	//just an outut for select OU specified below
	global sel_output_list "Zambia"  //OU selection


*set today's date for saving
	global date = subinstr("`c(current_date)'", " ", "", .)

*set date of frozen instance - needs to be changed w/ updated data
	global datestamp "20170815_v1_1"

*import/open data
	capture confirm file "$fvdata/ICPI_FactView_PSNU_IM_${datestamp}.dta"
		if !_rc{
			use "$fvdata/ICPI_FactView_PSNU_IM_${datestamp}.dta", clear
		}
		else{
			import delimited "$fvdata/ICPI_FactView_PSNU_IM_${datestamp}.txt", clear
			save "$fvdata/ICPI_FactView_PSNU_IM_${datestamp}.dta", replace
		}
	*end

*SNU prioritizations
	drop fy16snuprioritization
	rename fy17snuprioritization snuprioritization
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST Positives & TX_NET_NEW --> need to "create" new var
	gen key_ind=indicator if ///
		(inlist(indicator, "HTS_TST", "HTS_TST_POS", ///
			"PMTCT_STAT", "PMTCT_STAT_POS", "PMTCT_ART", "PMTCT_EID", "TX_NEW", "TX_CURR", ///
			"VMMC_CIRC") | ///
		inlist(indicator, "KP_PREV", "PP_PREV", "OVC_HIVSTAT", "OVC_SERV", ///
				"TB_ART", "TB_STAT", "TB_STAT_POS", "TX_TB")) & disaggregate=="Total Numerator"
		/* inlist(indicator, "GEND_GBV", "PMTCT_FO", "TX_RET", "KP_MAT") ///  */

	*denominators (semi-annually)
		foreach x in "TB_STAT" "TB_ART"{
			replace key_ind = "`x'_D" if indicator=="`x'" & ///
			disaggregate=="Total Denominator"
		}
		*end

	*MCAD indicators disaggs
	replace key_ind=indicator if inlist(standardizeddisaggregate, "MostCompleteAgeDisagg", ///
		"Modality/MostCompleteAgeDisagg") & indicator!="HTS_TST_NEG" & ///
		sex!="" & inlist(age, "<15", "15+")

*keep only key indicators
	drop if key_ind=="" //only need data on key indicators

	*TX_NET_NEW indicator
		expand 2 if key_ind== "TX_CURR", gen(new) //create duplicate of TX_CURR
			replace key_ind= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
			drop new
		*create copy periods to replace "." w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach x in fy2015q2 fy2015q4 fy2016q2 fy2016q4 fy2017q1 fy2017q2 fy2017q3 fy2017_targets{
			clonevar `x'_cc = `x'
			recode `x'_cc (. = 0)
			}
			*end
		*create net new variables (tx_curr must be reporting in both pds?)
		gen fy2015q4_nn = fy2015q4_cc-fy2015q2_cc
		gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
		gen fy2016q4_nn = fy2016q4_cc-fy2016q2_cc
		egen fy2016apr_nn = rowtotal(fy2016q2_nn fy2016q4_nn)
		gen fy2017q1_nn = fy2017q1_cc-fy2016q4_cc
		gen fy2017q2_nn = fy2017q2_cc-fy2017q1_cc
		gen fy2017q3_nn = fy2017q3_cc-fy2017q2_cc
		**gen fy2017q4_nn = fy2017q4_cc-fy2017q3_cc //for Q4
		gen fy2017_targets_nn = fy2017_targets_cc - fy2016q4_cc
		*egen fy2017apr_nn = rowtotal(fy2017q2_nn fy2017q4_nn) //for Q4
		drop *_cc
		*replace raw period values with generated net_new values
		foreach x in fy2015q4 fy2016q2 fy2016q4 fy2016apr fy2017q1 fy2017q2 fy2017q3 fy2017_targets{
			replace `x' = `x'_nn if key_ind=="TX_NET_NEW"
			drop `x'_nn
			}
			*end
		*remove tx net new values for fy15
		foreach pd in fy2015q2 fy2015q3 fy2015apr {
			replace `pd' = . if key_ind=="TX_NET_NEW"
			}
			*end

	*add future quarters in
	foreach x in q2 q3 q4 apr{
		capture confirm variable fy2017`x'
		if _rc gen fy2017`x' = .
		}
		*end

	*create cumulative variable to sum up necessary variables
		egen fy2017cum = rowtotal(fy2017q*)
			replace fy2017cum = . if fy2017cum==0
		*for semi annual indicators
		local i 2 //change at Q4
		replace fy2017cum = fy2017q`i' if inlist(key_ind, "KP_PREV", ///
			"PP_PREV", "OVC_HIVSTAT", "OVC_SERV", "TB_ART",  ///
			"TB_STAT", "TX_TB") | inlist(key_ind, "GEND_GBV", "PMTCT_FO", ///
			"TX_RET", "KP_MAT")
		*for quarterly snapshot indicators
		local i 3 //change every quarter
		replace fy2017cum = fy2017q`i' if key_ind=="TX_CURR"
		*clean up
		replace fy2017cum =. if fy2017cum==0 //should be missing
		/*capture confirm variable fy2017apr
			if !_rc replace fy2017cum = fy2017apr */

* format disaggs
	gen disagg = "Total"
		replace disagg = age + "/" + sex if ismcad=="Y"

* delete extrainous vars/obs
	drop indicator
	rename ïregion region
	rename key_ind indicator
	local vars operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator disagg fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016q3 fy2016q4 fy2016apr fy2017_targets ///
		fy2017q1 fy2017q2 fy2017q3 fy2017q4 fy2017cum
	keep `vars'
	order `vars'


*update all partner and mech to offical names (based on FACTS Info)
	*tostring mechanismid, replace
	preserve
	run 06_partnerreport_officalnames
	restore
	merge m:1 mechanismid using "$output/officialnames.dta", ///
		update replace nogen keep(1 3 4 5) //keep all but non match from using

*aggregate rows
	collapse (sum) fy*, by(operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		indicator disagg)

*recode 0's to blanks to save space
	recode fy* (0 = .)

* identify rows with no usable data and drop
	egen nonmiss = rownonmiss(fy*)
		drop if nonmiss==0
		drop nonmiss


*export full dataset
	if $global_output == 1 {
		di "GLOBAL OUTPUT"
		export delimited using "$excel/ICPIFactView_SNUbyIM_${date}_GLOBAL", ///
			nolabel replace dataf
		}
		*end

*export EQUIP global dataset
	if $global_output == 1 {
		di "EQUIP OUTPUT"
		preserve
		merge m:1 mechanismid using "$data/equip_mech_list.dta", nogen keep(matched)
		export delimited using "$excel/ICPIFactView_SNUbyIM_${date}_EQUIP", ///
			nolabel replace dataf
		restore
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
			di in yellow "export dataset: `ou' "
			qui: export delimited using "$excel/ICPIFactView_SNUbyIM_${date}_`ou'", ///
				nolabel replace dataf
			restore
			}
			}
			*end


*****
*KP output
/*
preserve
	import excel "Documents/KP PREV IMs.xlsx", allstring firstrow clear
	save "$output/kpmechs", replace
	restore
	preserve
	merge m:1 mechanismid using "$output/kpmechs", nogen keep(match)
	qui: export delimited using "$excel/ICPIFactView_SNUbyIM_${date}_KPmechs", ///
		nolabel replace dataf
	restore
*/
