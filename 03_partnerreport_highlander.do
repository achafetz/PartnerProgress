**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: check completness for HTC and TX & determine appropriate disaggs
**   Date: July 1, 2016
**   Updated: 

/* NOTES
	- Data source: ICPIFactView - SNU by IM Level_db-frozen_20160617 [Data Hub]
	- For variables not using "Total Numerator (HTC_TST_POS & TX_NEW_<1) need to
		determine which disagg to use, Finer or Coarser; to do so, we run a version
		of the Highlander Script at OU level
	- Report aggregates DSD and TA
	- Report looks across HTC_TST, HTC_TST_POS, TX_NEW, & TX_NEW_<01
*/

********************************************************************************

*open data (generated in 02)
	use "$output\ICPIFactView_SNUbyIM.dta", clear

*replace missing SNU prioritizatoins
	replace snuprioritization="[not classified]" if snuprioritization==""

*create new indicator variable for only the ones of interest for analysis
	* for most indicators we just want their Total Numerator reported
	* exceptions = HTC_TST, Positives & TX_CURR <1 --> need to "create" new var
	gen key_ind=indicator if inlist(indicator, "HTC_TST", "TX_NEW")
	*HTC_TST_POS indicator
	replace key_ind="HTC_TST_POS" if indicator=="HTC_TST" & ///
		resultstatus=="Positive" & ///
		inlist(disaggregate, "Age/Sex/Result", "Age/Sex Aggregated/Result")
	* TX_NEW_<1 indicator
	replace key_ind="TX_NEW_<1"	if indicator=="TX_NEW" & age=="<01"	

*create SAPR variable to sum up necessary variables
	egen fy2016sapr = rowtotal(fy2016q1 fy2016q2)
		replace fy2016sapr =. if fy2016sapr==0 //should be missing
		
* delete extrainous vars/obs
	*drop if fundingagency=="Dedup" // looking at each partner individually
	drop if key_ind=="" //only need data on key indicators
	drop regionuid operatingunituid mechanismuid indicator fy2015* fy2016q* fy2016apr
	rename key_ind indicator
	order indicator,  before(numeratordenom) //place it back where indicator was located

*reshape long (targets/sapr)
	replace psnuuid = "MIL" if psnu==""
	egen id = group(operatingunit countryname psnuuid fundingagency ///
		primepartner mechanismid implementingmechanismname indicator ///
		indicatortype disaggregate categoryoptioncomboname)
	rename fy2016_targets fy2016targets
	reshape long fy2016@, i(id) j(pd, string)
	drop id
	
*setup disaggs for wide reshape
	keep if inlist(disaggregate,"Age/Sex Aggregated/Result",  "Age/Sex/Result", ///
		"Total Numerator", "Age/Sex", "Age/Sex Aggregated")
	replace indicator = "TX_NEW_u1" if indicator== "TX_NEW_<1"
	levelsof indicator
	foreach ind in `r(levels)'{
		replace disaggregate="`ind'_COARSE" if inlist(disaggregate, ///
			"Age/Sex Aggregated/Result", "Age/Sex Aggregated") & indicator=="`ind'"
		replace disaggregate="`ind'_FINER" if inlist(disaggregate, ///
			"Age/Sex/Result", "Age/Sex") & indicator=="`ind'"
		replace disaggregate="`ind'_TOTAL_NUMERATOR" if ///
			disaggregate=="Total Numerator" & indicator=="`ind'"
		}
		*end
	
*reshape wide (ind & disaggs)
	gen id = _n
	reshape wide fy2016, i(id) j(disaggregate, string)
//work in progress
