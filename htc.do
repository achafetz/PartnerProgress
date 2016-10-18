**   Partner Performance by SNU
**   COP FY16
**   Aaron Chafetz
**   Purpose: create an aggregate site dataset for TX_CURR & TX_NEW
**   Date: October 11, 2016
**   Updated:

/* NOTES
	- Data source: ICPI_Fact_View_PSNU_IM_20160915 [ICPI Data Store]
	- Report uses FY2016APR results since it sums up necessary values
	- Report aggregates DSD and TA
	- Report looks across TX_CURR & TX_NEW
*/
********************************************************************************

* unzip folder containing all site data
	cd "C:\Users\achafetz\Documents\ICPI\Data"
	global folder "ALL Site Dataset 20160915"
	unzipfile "$folder"
	
*convert files from txt to dta for appending and keep only TX_CURR and TX_NEW (total numerator)
	cd "C:\Users\achafetz\Documents\ICPI\Data\ALL Site Dataset 20160915"
	fs 
	foreach ou in `r(files)'{
		di "import/save: `ou'"
		qui: import delimited "`ou'", clear
		*keep just TX_NEW and TX_CURR
		qui: keep if indicator=="HTC_TST"
		qui: save "`ou'.dta", replace
		}
		*end
*append all ou files together
	clear
	fs *.dta
	di "append files"
	qui: append using `r(files)', force
	
*save all site file
	local datestamp "20160915"
	save "$output\ICPIFactView_ALLHTC_Site_IM`datestamp'", replace
	
*delete files
	fs *.dta 
	erase `r(files)'
	fs *.txt
	erase `r(files)'
	rmdir "C:\Users\achafetz\Documents\ICPI\Data\ALL Site Dataset 20160915\"
	

	
keep if inlist(disaggregate, "Age/Sex Aggregated/Result", "Age/Sex/Result", "Results", "ServiceDeliveryPoint/Result", "Total Numerator")	
collapse (sum) fy*, by(operatingunit psnu fundingagency mechanismid disaggregate)

save "$output\ICPIFactView_ALLHTC_Site_IM_agg`datestamp'", replace
use "$output\ICPIFactView_ALLHTC_Site_IM_agg`datestamp'", clear
drop fy2015q2-fy2016q2

levelsof disaggregate, local(levels)
foreach d of local levels{
	local sub "`=subinstr("`d'","/","_",.)'"
	local sub "`=subinstr("`sub'"," ","_",.)'"
	replace disaggregate = "`sub'" if disaggregate=="`d'"
	}
	*end
replace disaggregate = "SDP_Result" if disaggregate=="ServiceDeliveryPoint_Result"
replace disaggregate = "AgeSex_Agg_Result" if disaggregate=="Age_Sex_Aggregated_Result"
reshape wide fy2016q3, i(operatingunit psnu fundingagency mechanismid) j(disaggregate, string)
egen rtotal = rowtotal(fy*)
drop if rtotal==0
drop rtotal


gen result_pct = fy2016q3Results/fy2016q3Total_Numerator
gen flag = 0
	replace flag=1 if result_pct<.95 | result_pct>1.05


