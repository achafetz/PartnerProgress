**   Partner Performance Report
**   COP FY17
**   Aaron Chafetz & Josh Davis
**   Purpose: correct naming partner and mechanism names to offical source
**   Date: November 22, 2016
**   Updated: 4/17/17

/* NOTES
	- Data source: FACTS Info, April 17, 2017
	- mechanism partner list COP 2012-2017
*/
********************************************************************************

global datetime "201704170951"

*import data
	import excel using "$data/FY12-16 Standard COP Matrix Report-${datetime}.xls", ///
		cellrange(A3) case(lower) clear

*rename variables
	rename A operatingunit
	rename B mechanismid

	local copyr 2014
	foreach v of varlist C E G I {
		rename `v' primepartner`copyr'
		local copyr = `copyr' + 1
		}
		*end
		
	local copyr 2014
	foreach v of varlist D F H J {
		rename `v' implementingmechanismname`copyr'
		local copyr = `copyr' + 1
		}
		*end

*figure out latest name for IM and partner (should both be from the same year)
	foreach y in primepartner implementingmechanismname{
		gen `y' = ""
		gen `y'yr =.
		foreach x in 2014 2015 2016 2017{
			replace `y' = `y'`x' if `y'`x'!=""
			replace `y'yr = `x' if `y'`x'!=""
			}
			}
			*end

*keep only necessary infor	
	keep mechanismid implementingmechanismname primepartner  

*save 
	save "$output/officialnames.dta", replace

