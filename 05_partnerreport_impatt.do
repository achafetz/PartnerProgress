**   Partner Performance Report
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: correct naming partner and mechanism names to offical source
**   Date: October 18, 2016
**   Updated: 11/22/16

/* NOTES
	- Data source: ICPI_Fact_View_NAT_SUBNAT_201611 [ICPI Data Store]
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	local datestamp "20161115"

*import/open data
	capture confirm file "$output\ICPIFactView_IMPATT`datestamp'.dta"
		if !_rc{
			use "$output\ICPIFactView_IMPATT`datestamp'.dta", clear
		}
		else{
			*import delimited "$data\ICPI_Fact_view_NAT_SUBNAT_`datestamp'.txt", clear
			import excel "$data\ICPI_Fact_view_NAT_SUBNAT_`datestamp'.xlsx", ///
				firstrow case(lower) clear
			}
	*end

	keep if inlist(indicator, "POP_NUM", "PLHIV")
	replace indicator = "PLHIV_NUM" if indicator=="PLHIV"
	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		indicator value
