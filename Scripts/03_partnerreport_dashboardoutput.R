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
	date = format(Sys.Date(), format="%Y%b%d")

#import/open data	
	fvdata <- read_rds(Sys.glob(file.path(datafv, "ICPI_FactView_PSNU_IM_*.Rds")))

#identify current fy
	curr_fy <- headers[str_detect(headers, "q(?=[:digit:])")] %>% 
	  tail(., n =1) %>% 
	  str_sub(1, -3)
	
#identify current period
	headers <- names(fvdata)
	curr_q <- headers[str_detect(headers, "q(?=[:digit:])")] %>% 
	  tail(., n =1) %>% 
	  str_sub(-1) %>% 
	  as.integer(.)

	rm(headers)

#add new columns if not yet at q4
	if(curr_q != 4) {
	  #n+1 quater 
	  new_qs <- curr_q + 1 
	  #create new columns for n+1 quater to Q4
	  for(i in new_qs:4){
	    #define variable name, eg fy2018q2
	    varname <- paste0(curr_fy, "q", i)
	    #create variable
	    df_netnew <- df_netnew %>% 
	      mutate(!!varname := 0)
	  }
	  #create apr column
	  varname <- paste0(curr_fy, "apr")
	  df_netnew <- df_netnew %>% 
	    mutate(!!varname := 0)
	}
	
#SNU prioritizations
	df_ppr <- fvdata %>% 
    mutate(currentsnuprioritization = ifelse(is.na(currentsnuprioritization),"[not classified]", currentsnuprioritization))
	
#create new indicator variable for only the ones of interest for analysis
	#rename denominator values _D
	df_ppr <- fvdata %>% 
	  mutate(indicator = ifelse((indicator=="TB_ART" & disaggregate=="Total Denominator"),"TB_ART_D",indicator),
	       indicator = ifelse((indicator=="TB_STAT" & disaggregate=="Total Denominator"),"TB_STAT_D",indicator),
	       disaggregate = ifelse((indicator %in% c("TB_ART_D", "TB_STAT_D")),"Total Numerator",disaggregate))
	#indicators to keep
	#q1 
	  ind_q1 <- c("HTS_TST", "TX_NEW", "PMTCT_EID", "HTS_TST_POS", "PMTCT_STAT", 
	         "PMTCT_STAT_POS", "TX_NET_NEW", "TX_CURR", "PMTCT_ART", "VMMC_CIRC")
	#q2
	  ind_q2 <- c(ind_q1, "KP_PREV", "PP_PREV", "OVC_HIVSTAT", "OVC_SERV",
	            "TB_ART", "TB_STAT", "TB_STAT_POS", "TB_ART_D", "TB_STAT_D", "TX_TB")
	#q3
	  ind_q3 <- c(ind_q2)
	
	#q4 
	  ind_q4 <- c(ind_q3, "GEND_GBV", "PMTCT_FO", "TX_RET", "KP_MAT")
	  
	#filter
	df_ppr <- fvdata %>% 
	  filter(((indicator %in% get(paste0("ind_q", curr_q)) ) & disaggregate=="Total Numerator") |
	         ((standardizeddisaggregate %in% c("MostCompleteAgeDisagg", "Modality/MostCompleteAgeDisagg")) & 
	           indicator!="HTS_TST_NEG") & sex!="" & (age %in% c("<15", "15+")))
  	rm(list = ls(pattern = "^ind")) 
	
	#############################################
  source(here("Scripts", "officialnames.R"))
	 
	 ###########################################
	 
   #create age/sex disagg
	  mutate(disagg = ifelse(ismcad=="Y", paste(age, sex, sep="/"), "Total")) %>%
	  
  #aggregate by subset variable list
    group_by(operatingunit, countryname, psnu, psnuuid, currentsnuprioritization,
                  fundingagency, primepartner, mechanismid, implementingmechanismname,
                  indicator, disagg) %>%
   summarize_at(vars(starts_with("fy")), funs(sum(., na.rm=TRUE))) %>%
   ungroup()

#####
 
#NET NEW
	
#####   

	#create cumulative indicator
	df_ppr[is.na(df_ppr)] <- 0
	df_ppr <- df_ppr %>% 
	  mutate(fy2017cum = ifelse(indicator=="TX_CURR", fy2017q3, 
	                            ifelse(indicator %in% c("KP_PREV","PP_PREV", "OVC_HIVSTAT", "OVC_SERV", 
	                                                    "TB_ART", "TB_STAT", "TX_TB", "GEND_GBV", "PMTCT_FO", 
	                                                    "TX_RET", "KP_MAT"), 
	                                   fy2017q2, fy2017q1 + fy2017q2 + fy2017q3 + fy2017q4)))
	
	
	df_ppr[df_ppr==0] <- NA
	
	df_ppr <- df_ppr %>%
	    gather(period, value, contains("fy")) %>%
	    drop_na(value) %>%
	    spread(period, value) %>%
	  #add future periods if they don't yet exist
	  mutate(fy2017q4 = NA) %>%
	    select(operatingunit, countryname, psnu, psnuuid, currentsnuprioritization,
	           fundingagency, primepartner, mechanismid, implementingmechanismname,
	           indicator, disagg, fy2015q2, fy2015q3, fy2015q4, fy2015apr, fy2016_targets,
	           fy2016q1, fy2016q2, fy2016q2, fy2016q3, fy2016q4, fy2016apr, fy2017_targets,
	           fy2017q1, fy2017q2, fy2017q3, fy2017q4, fy2017cum)
	    
	
	
	test<- df_ppr %>% drop_na(fy2015q2:fy2017cum)