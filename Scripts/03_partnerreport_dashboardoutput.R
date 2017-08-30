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
	         indicator = ifelse((indicator=="TB_STAT" & disaggregate=="Total Denominator"),"TB_STAT_D",indicator)
	         ) 
	  

#TX_NET_NEW indicator
	df_netnew <- fvdata %>%
	  filter(indicator=="TX_CURR") %>%
	  mutate(indicator = "TX_NET_NEW")
	
	
	
	
	
	