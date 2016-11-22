**   Partner Performance Report
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: correct naming partner and mechanism names to offical source
**   Date: November 22, 2016
**   Updated: 

/* NOTES
	- Data source: FACTS Info [T. Lim], Nov 17, 2016
	- mechanism partner list 2012-2016
*/
********************************************************************************

*import/open data
	capture confirm file "$output\FACTInfo_OfficialNames_2016.11.17.dta"
		if !_rc{
			use "$output\FACTInfo_OfficialNames_2016.11.17.dta", clear
		}
		else{
			import excel "$data\FACTSInfo_OfficialNames_2016.11.17.xlsx", firstrow ///
				case(lower) allstring clear
			save "$output\FACTInfo_OfficialNames_2016.11.17.dta", replace
		}
	*end

*clean
	drop operatingunit agency legacyid
	rename mechanismidentifier mechanismid
	rename mechanismname implementingmechanismname
	rename primepartner primepartner
	
	
*save 
	save "$output\officialnames.dta", replace
