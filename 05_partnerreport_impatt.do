**   Partner Performance Report
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: correct naming partner and mechanism names to offical source
**   Date: October 18, 2016
**   Updated: 1/14/17

/* NOTES
	- Data source: ICPI_Fact_View_NAT_SUBNAT_201611 [ICPI Data Store]
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	global datestamp "20161230_v2_2"
	
*import/open data
	import delimited "$fvdata\ICPI_FactView_NAT_SUBNAT_${datestamp}.txt", ///
		case(lower) clear

*keep just pop and plhiv
	keep if inlist(indicator, "POP_NUM", "PLHIV") & disaggregate=="Total Numerator"
	replace indicator = "PLHIV_NUM" if indicator=="PLHIV"
	keep ïregion operatingunit countryname psnu psnuuid fy16snuprioritization ///
		indicator fy2016q4
	sort operatingunit psnu	
	br 

