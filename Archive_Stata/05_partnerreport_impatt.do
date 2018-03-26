**   Partner Performance Report
**   COP FY16
**   Aaron Chafetz & Josh Davis
**   Purpose: correct naming partner and mechanism names to offical source
**   Date: October 18, 2016
**   Updated: 5/15/17

/* NOTES
	- Data source: ICPI_Fact_View_NAT_SUBNAT [ICPI Data Store]
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	global datestamp "20170515_v1_1"
	
*import/open data
	import delimited "$fvdata\ICPI_FactView_NAT_SUBNAT_${datestamp}.txt", ///
		case(lower) clear

*keep just pop and plhiv
	keep if inlist(indicator, "POP_EST (SUBNAT)", "PLHIV (SUBNAT)")
	replace indicator = "PLHIV_NUM" if indicator=="PLHIV (SUBNAT)"
	replace indicator = "POP_NUM" if indicator=="POP_EST (SUBNAT)"
	keep region operatingunit countryname psnu psnuuid fy17snuprioritization ///
		indicator fy2017
	drop if fy2017 ==""
	sort operatingunit psnu	
	br 

