##   Partner Performance by SNU
##   COP FY17
##   Aaron Chafetz
##   Purpose: generate output for Excel monitoring dashboard
##   Date: June 20, 2016 (STATA)
##   Updated: 8/29/17

## NOTES
#   - Data source: ICPI_Fact_View_PSNU_IM  [ICPI Data Store]
#   - Report aggregates DSD and TA
#   - Report uses Totals and MCAD

######################################################################################


#Which outputs to produce? 0 = No, 1 = Yes
  #global_output <-  1 //full global dataset
  #equip_output <- 0 //full global dataset
  #ctry_output <- 1 	//one dataset for every OU
  #sel_output <- 0	//just an outut for select OU specified below
  #sel_output_list <- "Zambia"  //OU selection

#set today's date for saving
	date = format(Sys.Date(), format="%Y%b%d")

#set date of frozen instance - needs to be changed w/ updated data
	datestamp = "20170815_v1_1"

#import/open data	
	fvdata <- read_delim(file.path(datafv, paste("ICPI_FactView_PSNU_IM_", datestamp, ".txt", sep="")), 
	                     "\t", escape_double = FALSE, trim_ws = TRUE)
	
# change all header names to lower case to make it easier to use
	names(fvdata) <- tolower(names(fvdata))
	
#SNU prioritizations
	fvdata <- fvdata %>% 
	  select(-fy16snuprioritization) %>%
    rename(snuprioritization=fy17snuprioritization) %>%
    mutate(snuprioritization = ifelse(is.na(snuprioritization),"[not classified]", snuprioritization))	%>%
	
#create new indicator variable for only the ones of interest for analysis
	# for most indicators we just want their Total Numerator reported
	# additional indicators for Q4 - ("GEND_GBV", "PMTCT_FO", "TX_RET", "KP_MAT")	
	  filter(
	        ((indicator %in% c("HTS_TST", "HTS_TST_POS", "PMTCT_STAT", "PMTCT_STAT_POS", "PMTCT_ART",
	        "PMTCT_EID", "TX_NEW", "TX_CURR", "VMMC_CIRC", "KP_PREV", "PP_PREV", "OVC_HIVSTAT", "OVC_SERV",
	        "TB_ART", "TB_STAT", "TB_STAT_POS", "TX_TB")) & disaggregate=="Total Numerator") |
	         ((indicator %in% c("TB_STAT", "TB_ART")) & disaggregate=="Total Denominator") |
	         ((standardizeddisaggregate %in% c("MostCompleteAgeDisagg", "Modality/MostCompleteAgeDisagg")) & 
	         indicator!="HTS_TST_NEG")) %>%
	
	 #rename denominator values _D
	  mutate(indicator = ifelse((indicator=="TB_ART" & disaggregate=="Total Denominator"),"TB_ART_D",indicator), 
	         indicator = ifelse((indicator=="TB_STAT" & disaggregate=="Total Denominator"),"TB_STAT_D",indicator)) %>%

	 #add future periods if they don't yet exist
	  mutate(fy2017q4 = 0, fy2017apr = 0) 
	 
	 #create cumulative indicator
	  fvdata[is.na(fvdata)] <- 0
	  fvdata <- fvdata %>% 
	      mutate(fy2017cum = ifelse(indicator=="TX_CURR", fy2017q3, 
	                         ifelse(indicator %in% c("KP_PREV","PP_PREV", "OVC_HIVSTAT", "OVC_SERV", 
	                                                 "TB_ART", "TB_STAT", "TX_TB", "GEND_GBV", "PMTCT_FO", 
	                                                 "TX_RET", "KP_MAT"), 
	                         fy2017q2, fy2017q1 + fy2017q2 + fy2017q3 + fy2017q4))) %>%
    #create age/sex disagg
	      mutate(disagg = ifelse(ismcad=="Y", paste(age, sex, sep="/"), "Total"))
	  
	  #keep only necessary variables
	  fvdata <- fvdata %>%  
	    select(operatingunit, countryname, psnu, psnuuid, snuprioritization,
	               fundingagency, primepartner, mechanismid, implementingmechanismname,
	               indicator, disagg, fy2015q2, fy2015q3, fy2015q4, fy2015apr, fy2016_targets,
	               fy2016q1, fy2016q2, fy2016q2, fy2016q3, fy2016q4, fy2016apr, fy2017_targets,
	               fy2017q1, fy2017q2, fy2017q3, fy2017q4, fy2017cum)
	    
	#replace partner and IM with official names from FACTS Info
	  df_names <- read_excel(file.path(rawdata,"FY12-16 Standard COP Matrix Report-20170822.xls"), skip = 1)
	  
	  #rename variables
	  names(df_names) <- c("operatingunit", "mechanismid", "primepartner_2014", "implementingmechanismname_2014", 
	                       "primepartner_2015", "implementingmechanismname_2015", "primepartner_2016", "implementingmechanismname_2016",
	                       "primepartner_2017", "implementingmechanismname_2017")
	  #figure out latest name for IM and partner (should both be from the same year)
	  df_names <- df_names %>%
	      gather(type, name, primepartner_2014, implementingmechanismname_2014, 
	              primepartner_2015, implementingmechanismname_2015, primepartner_2016, implementingmechanismname_2016,
	             primepartner_2017, implementingmechanismname_2017) %>%
	      separate(type, c("type", "year"), sep="_") %>%
	      filter(!is.na(name)) %>%
	      group_by(operatingunit, mechanismid, type) %>%
        filter(year==max(year)) %>%
	      ungroup() %>%
	      spread(type, name) %>%
	      select(mechanismid, implementingmechanismname, primepartner)
	      


	
#TX_NET_NEW indicator
	#subset to just TX_CURR which will become NET NEW
	df_netnew <- fvdata %>%
	  filter(indicator=="TX_CURR") %>%
	  mutate(indicator = "TX_NET_NEW") 
	
	#replace all NAs with zero to calculate 
	df_netnew[is.na(df_netnew)] <- 0
	
	#create net new variable
	df_netnew <- df_netnew %>%
	  mutate(fy2015q4_cc =  fy2015q4 - fy2015q2,
	         fy2016q2_cc =  fy2016q2 - fy2015q4,
	         fy2016q4_cc =  fy2016q4 - fy2016q2,
	         fy2017q1_cc =  fy2017q1 - fy2016q4,
	         fy2017q2_cc =  fy2017q2 - fy2017q1,
	         fy2017q3_cc =  fy2017q3 - fy2017q2,
	         fy2017_targets_cc = fy2017_targets - fy2016q4) %>%
	  mutate(fy2015q2 = NA, 
	         fy2015q3 = NA,
	         fy2015q4 =  fy2015q4_cc,
	         fy2015apr = NA,
	         fy2016_targets = NA,
	         fy2016q1 =  NA,
	         fy2016q2 =  fy2016q2_cc,
	         fy2016q3 =  NA,
	         fy2016q4 =  fy2016q4_cc,
	         fy2016apr = fy2016q2_cc + fy2016q4_cc, 
	         fy2017q1 =  fy2017q1_cc,
	         fy2017q2 =  fy2017q2_cc,
	         fy2017q3 =  fy2017q3_cc,
	         fy2017_targets = fy2017_targets_cc) %>%
	  select(-ends_with("_cc"))
	
	df_netnew[df_netnew==0] <- NA
	  

	
	
	
	
	