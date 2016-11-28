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
	import excel "$data\ICPI_Fact_view_NAT_SUBNAT_`datestamp'.xlsx", ///
		firstrow case(lower) clear

*keep just pop and plhiv
	keep if inlist(indicator, "POP_NUM", "PLHIV") & disaggregate=="Total Numerator"
	replace indicator = "PLHIV_NUM" if indicator=="PLHIV"
	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		indicator value
		
	br
