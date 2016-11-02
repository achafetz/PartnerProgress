


*set date of frozen instance - needs to be changed w/ updated data
	local datestamp "20161010"
*import/open data
	capture confirm file "$output\ICPIFactView_IMPATT`datestamp'.dta"
		if !_rc{
			use "$output\ICPIFactView_IMPATT`datestamp'.dta", clear
		}
		else{
			import delimited "$data\ICPI_Fact_view_NAT_SUBNAT_`datestamp'.txt", clear
			save "$output\ICPIFactView_IMPATT`datestamp'.dta", replace
		}
	*end

	keep if inlist(indicator, "POP_NUM", "PLHIV_NUM")
	keep region operatingunit countryname psnu psnuuid snuprioritization ///
		indicator value
