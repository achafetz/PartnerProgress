**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz
**   Purpose: create an aggregate site dataset for TX_CURR & TX_NEW
**   Date: October 11, 2016
**   Updated: 11/3/16

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160915 [ICPI Data Store]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across TX_CURR & TX_NEW
*/
********************************************************************************

*set date of frozen instance - needs to be changed w/ updated data
	global datestamp "20161010"

* unzip folder containing all site data
	cd "C:\Users\achafetz\Documents\ICPI\Data"
	global folder "ALL Site Dataset ${datestamp}"
	unzipfile "$folder"
	
*convert files from txt to dta for appending and keep only TX_CURR and TX_NEW (total numerator)
	cd "C:\Users\achafetz\Documents\ICPI\Data\ALL Site Dataset ${datestamp}""
	fs 
	foreach ou in `r(files)'{
		di "import/save: `ou'"
		qui: import delimited "`ou'", clear
		*keep just TX_NEW and TX_CURR
		qui: keep if inlist(indicator, "TX_NEW", "TX_CURR") & disaggregate=="Total Numerator"
		qui: save "`ou'.dta", replace
		}
		*end
*append all ou files together
	clear
	fs *.dta
	append using `r(files)', force
	
*save all site file
	local datestamp "20160915"
	save "$output\ICPIFactView_ALLTX_Site_IM${datestamp}"", replace
	
*delete files
	fs *.dta 
	erase `r(files)'
	fs *.txt
	erase `r(files)'
	rmdir "C:\Users\achafetz\Documents\ICPI\Data\ALL Site Dataset ${datestamp}"\"
