##   Partner Performance by SNU
##   COP FY17
##   Aaron Chafetz
##   Purpose: generate output for Excel monitoring dashboard
##   Date: 2016-06-20 (STATA)
##   Updated: 2018-03-21

## NOTES
#   - Data source: ICPI_Fact_View_PSNU_IM  [ICPI Data Store]
#   - Need current COP Matrix report (renaming to official names)
#   - Report aggregates DSD and TA
#   - Report looks at only Totals and MCAD

######################################################################################

#dependencies
library(tidyverse)
library(here)

#file directory for Fact View datasets
datapathfv <- "~/ICPI/Data"

#Which outputs to produce? 0 = No, 1 = Yes
  output_global <-  1 #full global dataset
  #equip_output <- 0  #just EQUIP
  output_ctry <- 1 	#one dataset for every OU
  #sel_output <- 0	//just an outut for select OU specified below
  #sel_output_list <- "Zambia"  //OU selection


#import/open data	
	df_mer <- read_rds(Sys.glob(file.path(datapathfv, "ICPI_FactView_PSNU_IM_*.Rds")))
	
#find current quarter & fy
	source(here("Scripts", "currentperiod.R"))
	curr_q <- currentpd(df_mer, "quarter")
	curr_fy <- currentpd(df_mer, "year")
	fy_save <- 
	  currentpd(df_mer, "full") %>% 
	  toupper()
	
#create future filler columns
	source(here("Scripts", "futurefiller.R"))
	df_mer <- fill_future_pds(df_mer, curr_fy, curr_q)
	
#subset to indicators of interest
	source(here("Scripts", "filter_keyinds.R"))
	df_ppr <- filter_keyinds(df_mer, curr_q)
	
#create net new and bind it on
	source(here("Scripts", "netnew.R"))
	df_ppr <- netnew(df_ppr)

#apply offical names before aggregating (since same mech id may have multiple partner/mech names)  
  source(here("Scripts", "officialnames.R"))
  df_ppr <- officialnames(df_ppr, here("RawData"))  
  
#clean up - create age/sex disagg & replace missing SNU prioritizations
  df_ppr <- df_ppr %>% 
    mutate(disagg = ifelse(ismcad=="Y", paste(age, sex, sep="/"), "Total"),
           currentsnuprioritization = ifelse(is.na(currentsnuprioritization),"[not classified]", currentsnuprioritization))
  
#aggregate by subset variable list
  df_ppr <- df_ppr %>%  
    group_by(operatingunit, countryname, psnu, psnuuid, currentsnuprioritization,
              fundingagency, primepartner, mechanismid, implementingmechanismname,
              indicator, disagg) %>%
     summarize_at(vars(starts_with("fy")), ~ sum(., na.rm=TRUE)) %>%
     ungroup()

#drop missing rows
	df_ppr <- df_ppr %>%
	    gather(period, value, starts_with("fy"), na.rm = TRUE, factor_key = TRUE) %>%
	    mutate(value = ifelse(value == 0, NA, value)) %>% 
	    drop_na(value) %>%
	    spread(period, value)
	
#add future pds back in
	source(here("Scripts", "futurefiller.R"))
	df_ppr <- fill_future_pds(df_ppr, curr_fy, curr_q)

#add cumulative value for fy
	source(here("Scripts", "cumulative.R"))
	df_ppr <- cumulative(df_ppr, curr_fy, curr_q)
	
#replace all 0's with NA
	df_ppr[df_ppr==0] <- NA


#set today's date for saving
	date <- format(Sys.Date(), format="%Y%m%d")

#export datasets
	source(here("Scripts", "export.R"))
	
	#global
  if(output_global == TRUE){
    export("GLOBAL")
  }
  
	#countries
  if(output_ctry == TRUE){
    ou_list <- df_ppr %>% 
      distinct(operatingunit) %>% 
      arrange(operatingunit)
    purrr::map(.x = ou_list, .f = ~ export(.x))
  }
	