**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz
**   Purpose: generate site level aggre
**   Date: September 22, 2016
**   Updated: 

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160822 [ICPI Data Store]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across TX_CURR & TX_NEW
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	local datestamp "20160915"
	local ou Mozambique
*import/open data
	capture confirm file "$output\ICPIFactView_`ou'_Site_IM`datestamp'.dta"
		if !_rc{
			use "$output\ICPIFactView_`ou'_Site_IM`datestamp'.dta", clear
		}
		else{
			import delimited "$data\Site_IM_`datestamp'_`ou'.txt", clear
			save "$output\ICPIFactView_`ou'_Site_IM`datestamp'.dta", replace
		}
	*end

*replace missing prioritizatoins
	foreach type in snu community facility{
		replace `type'prioritization="[not classified]" if `type'prioritization==""
		}
		*end
*replace missing facility uid
	replace facilityuid = "MIL" if typemilitary=="Y" & facilityuid==""
	replace facilityuid = "[not classified]" if facilityuid==""
*keep just TX_NEW and TX_CURR
	keep if inlist(indicator, "TX_NEW", "TX_CURR") & disaggregate=="Total Numerator"
/*
*TX_NET_NEW indicator
		expand 2 if indicator=="TX_CURR" & , gen(new) //create duplicate of TX_CURR
			replace indicator= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
			drop new
		*create copy periods to replace . w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach x in fy2015q2 fy2015q4 fy2016q2 fy2016_targets{
			clonevar `x'_cc = `x'
			recode `x'_cc (. = 0)
			}
			*end
		*create net new variables
		gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
		gen fy2016_targets_nn = fy2016_targets_cc - fy2015q4_cc
		drop *_cc
		*replace period values with net_new
		foreach x in fy2016q2 fy2016_targets {
			replace `x' = `x'_nn if indicator=="TX_NET_NEW"
			drop `x'_nn
			}
			*end
		*remove tx net new values for fy15
		foreach pd in fy2015q2 fy2015q3 fy2015q4 fy2015apr {
			replace `pd' = . if indicator=="TX_NET_NEW"
			}
			*end
*/			
*create SAPR and cumulative variable to sum up necessary variables
	foreach agg in "sapr" "cum" {
		if "`agg'"=="sapr" egen fy2016`agg' = rowtotal(fy2016q1 fy2016q2)
			else egen fy2016`agg' = rowtotal(fy2016q*)
		replace fy2016`agg' = fy2016q2 if inlist(indicator, "TX_CURR", ///
			"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		replace fy2016`agg' =. if fy2016`agg'==0 //should be missing
		}
		*end

*delete reporting that shouldn't have occured
	tabstat fy2015q3 fy2016q1 fy2016q3 if inlist(indicator, "TX_CURR", ///
		"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR"), ///
		s(sum count) by(operatingunit)	
	foreach pd in fy2015q3 fy2016q1 fy2016q3{
		replace `pd'=. if inlist(indicator, "TX_CURR", "OVC_SERV", ///
			"PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		}
/*reshape long
	gen id = _n //unique id for reshaping
	reshape long fy@, i(id) j(type, string)
	rename fy value
	drop id

*reshape wide
	drop if typemilitary=="Y"
	drop fy2015q2-fy2016q3 fy2016cum
	egen id = group(psnuuid mechanismid primepartner communityuid facilityuid) 
	collapse (sum) fy2016sapr, by(ïregion-indicator)
	reshape wide fy2016sapr, i(id) j(indicator, string)
	recode fy* (.=0)
	gen nr = fy2016saprTX_NEW-fy2016saprTX_NET_NEW
		recode fy* nr (0=.)
		replace nr = 0 if nr==. & fy2016saprTX_NEW!=. & fy2016saprTX_NET_NEW!=.
	gen notretained = nr if nr>=0
	gen attributionchange = nr if nr<0
	drop nr
*/

*collapse DSD/TA (by varlist is same as keep list below)
	collapse (sum) fy*, by(ïregion operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		facilityuid facilityprioritization indicator)
		
*clean out site period not using in for TX_NET_NEW
	foreach x of varlist fy2015q2-fy2015q4 fy2016_targets-fy2016q3 fy2016cum{
		replace `x' = .
		}
		*end
	recode fy* (0 = .)

* delete extrainous vars/obs
	rename ïregion region
	drop if fy2015apr==. & fy2016sapr==. //drop if all relevant pd results are missing
	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		facilityuid facilityprioritization indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016cum
	order region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency primepartner mechanismid implementingmechanismname ///
		facilityuid facilityprioritization indicator fy2015q2 fy2015q3 fy2015q4 fy2015apr fy2016_targets ///
		fy2016q1 fy2016q2 fy2016q2 fy2016sapr fy2016q3 fy2016cum

*set up to loop through countries
	qui:levelsof operatingunit, local(levels)
	local date = subinstr("`c(current_date)'", " ", "", .)
	foreach ou of local levels {
		preserve
		di "export dataset: `ou' "
		qui:keep if operatingunit=="`ou'"
		qui: export delimited using "$excel\ICPIFactView_SiteIM_`date'_`ou'", ///
			nolabel replace dataf
		restore
		}
		*end
