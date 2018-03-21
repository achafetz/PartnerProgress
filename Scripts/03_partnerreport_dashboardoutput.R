##   Partner Performance by SNU
##   COP FY17
##   Aaron Chafetz
##   Purpose: generate output for Excel monitoring dashboard
##   Date: 2016-06-20 (STATA)
##   Updated: 2018-03-19

## NOTES
#   - Data source: ICPI_Fact_View_PSNU_IM  [ICPI Data Store]
#   - Report aggregates DSD and TA
#   - Report uses Totals and MCAD

######################################################################################

#dependencies
library(tidyverse)
library(here)

#file directory for Fact View datasets
datafv <- "~/ICPI/Data"

#Which outputs to produce? 0 = No, 1 = Yes
  #global_output <-  1 //full global dataset
  #equip_output <- 0 //full global dataset
  #ctry_output <- 1 	//one dataset for every OU
  #sel_output <- 0	//just an outut for select OU specified below
  #sel_output_list <- "Zambia"  //OU selection

#set today's date for saving
	date <- format(Sys.Date(), format="%Y%b%d")

#import/open data	
	df_mer <- read_rds(Sys.glob(file.path(datafv, "ICPI_FactView_PSNU_IM_*.Rds")))

#find current quarter & fy
	source(here("Scripts", "currentperiod.R"))
	curr_q <- currentpd(df, "quarter")
	curr_fy <- currentpd(df, "year")
	
#create future filler columns
	source(here("Scripts", "futurefiller.R"))
	df_mer <- fill_future_pds(df_mer, curr_fy, curr_q)
	
#subset to indicators of interest
	source(here("Scripts", "filter_inds.R"))
	df_ppr <- filter_keyinds(df_mer, curr_q)
	
#create net new and bind it on
	source(here("Scripts", "netnew.R"))
	df_ppr <- netnew(df_ppr)
  	
#add cumulative value for fy
  source(here("Scripts", "cumulative.R"))
  df_ppr <- cumulative(df_ppr, curr_fy, curr_q)

#apply offical names before aggregating (since same mech id may have multiple partner/mech names)  
  source(here("Scripts", "officialnames.R"))
  df_ppr <- officialnames(df_ppr, here("RawData"))  
  
#clean up - create age/sex disagg & replace missing SNU prioritizations
  df_ppr <- df_ppr %>% 
    mutate(disagg = ifelse(ismcad=="Y", paste(age, sex, sep="/"), "Total"),
           currentsnuprioritization = ifelse(is.na(currentsnuprioritization),"[not classified]", currentsnuprioritization))
  
#aggregate by subset variable list
   group_by(operatingunit, countryname, psnu, psnuuid, currentsnuprioritization,
            fundingagency, primepartner, mechanismid, implementingmechanismname,
            indicator, disagg) %>%
   summarize_at(vars(starts_with("fy")), funs(sum(., na.rm=TRUE))) %>%
   ungroup()


	#replace all 0's with NA
	  df_ppr[df_ppr==0] <- NA
	
	df_ppr <- df_ppr %>%
	    gather(period, value, starts_with("fy"), na.rm = TRUE, factor_key = TRUE) %>%
	    drop_na(value) %>%
	    spread(period, value) %>%

	    # select(operatingunit, countryname, psnu, psnuuid, currentsnuprioritization,
	    #        fundingagency, primepartner, mechanismid, implementingmechanismname,
	    #        indicator, disagg, fy2015q2, fy2015q3, fy2015q4, fy2015apr, fy2016_targets,
	    #        fy2016q1, fy2016q2, fy2016q2, fy2016q3, fy2016q4, fy2016apr, fy2017_targets,
	    #        fy2017q1, fy2017q2, fy2017q3, fy2017q4, fy2017cum)
	    
	
	
	test<- df_ppr %>% drop_na(fy2015q2:fy2017cum)