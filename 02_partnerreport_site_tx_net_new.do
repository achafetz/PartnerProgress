**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz
**   Purpose: generate site level aggre
**   Date: September 22, 2016
**   Updated: 11/4

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160822 [ICPI Data Store]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across TX_CURR & TX_NEW
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	local datestamp "20160915"
	local ou ALLTX
	
*set today's date for saving
	global date = subinstr("`c(current_date)'", " ", "", .)
	
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
	
*rename region
	rename ïregion region
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

*TX_NET_NEW indicator
	expand 2 if indicator=="TX_CURR" & , gen(new) //create duplicate of TX_CURR
		replace indicator= "TX_NET_NEW" if new==1 //rename duplicate TX_NET_NEW
		drop new
	*create copy periods to replace "." w/ 0 for generating net new (if . using in calc --> answer == .)
	foreach x in fy2015q2 fy2015q4 fy2016q2 fy2016_targets{
		clonevar `x'_cc = `x'
		recode `x'_cc (. = 0)
		}
		*end
	*create net new variables
	gen fy2016q2_nn = fy2016q2_cc-fy2015q4_cc
		replace fy2016q2_nn = . if (fy2016q2==. & fy2015q4==.)
	gen fy2016_targets_nn = fy2016_targets_cc - fy2015q4_cc
		replace fy2016_targets_nn = . if fy2016_targets==. & fy2015q4==.
	drop *_cc
	*replace raw period values with generated net_new values
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
	/*
	tabstat fy2015q3 fy2016q1 fy2016q3 if inlist(indicator, "TX_CURR", ///
		"OVC_SERV", "PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR"), ///
		s(sum count) by(operatingunit) //report of all incorrect reporting by OU
	*/
	ds *q1 *q3
	foreach pd in `r(varlist)'{
		replace `pd'=. if inlist(indicator, "TX_CURR", "OVC_SERV", ///
			"PMTCT_ARV", "KP_PREV", "PP_PREV", "CARE_CURR")
		}
		*end

*create not retained on TX variable (TX_NEW - TX_NET_NEW) --> dataset needs to be wide
	*collapse so only one observation per site
		collapse (sum) fy2015q2 fy2015apr fy2016_targets fy2016sapr, by(region ///
			operatingunit countryname psnu psnuuid snuprioritization facilityuid ///
			facilityprioritization indicator fundingagency implementingmechanismname)
	*reshape wide
		*drop if typemilitary=="Y"
		*egen id = group(psnuuid mechanismid primepartner communityuid facilityuid indicatortype) 
		reshape wide fy2015q2 fy2015apr fy2016_targets fy2016sapr, ///
			i(operatingunit countryname facilityuid fundingagency implementingmechanismname) ///
			j(indicator, string)
	*create copy periods to replace "." w/ 0 for generating net new (if . using in calc --> answer == .)
		foreach fy in fy2016saprTX_NEW fy2016saprTX_NET_NEW{
			clonevar `fy'_cc = `fy' // create copy to replace missing with zero for calculations (otherwise x-.=. or .-x = .)
			}
		ds *_cc
		recode `r(varlist)' (.=0)
	*new variable - not retained on treatment (will be stored in TX_CURR)
		*gen tx_not_ret = fy2016saprTX_NEW_cc-fy2016saprTX_NET_NEW_cc
		gen tx_ret = fy2016saprTX_NET_NEW_cc - fy2016saprTX_NEW_cc
			*change to missing if not in both time periods  
			replace tx_ret = . if ///
				(inlist(fy2016saprTX_NEW, ., 0) & inlist(fy2016saprTX_NET_NEW, ., 0)) | /// if either TX_NEW and NET_NEW were missing
				(inlist(fy2015aprTX_CURR, ., 0) & inlist(fy2016saprTX_CURR, ., 0))
		drop *_cc
	*reshape back to long from wide
		reshape long
		
*new variable - site exits for TX_CURR in both SAPR and APR
	*have to collapse up partners to site level and then merge back in
	preserve
	collapse (sum) fy2015apr fy2016sapr if indicator=="TX_CURR", by(operatingunit facilityuid)
	gen bothpds = 0
		replace bothpds = 1 if (!inlist(fy2015apr, ., 0) & ///
			!inlist(fy2016sapr, ., 0))
	drop fy*
	tempfile bothpds
	save "`bothpds'"
	restore
	merge m:1 operatingunit facilityuid using "`bothpds'"
* delete extrainous vars/obs
	rename tx_ret fy2016sapr_tx_ret 
	drop if indicator=="TX_NET_NEW" // only needed for not retain calculation
	replace fy2016sapr_tx_ret = . if indicator!="TX_CURR" //only want one obs of tx_retained
	drop if fy2015apr==. & fy2016sapr==. & fy2016sapr_tx_ret==. //drop if all relevant pd results are both missing
	
* keep and order variables
	local vars region operatingunit countryname psnu psnuuid snuprioritization ///
		fundingagency implementingmechanismname facilityuid ///
		facilityprioritization indicator ///
		fy2015q2 fy2015apr fy2016_targets fy2016sapr fy2016sapr_tx_ret bothpds
	keep `vars' 
	order `vars'  

*save as dta file for appending onto PSNU version [need to add to 02 do file]
	save "$output\ICPIFactView_SiteIM_${date}_`ou'", replace

