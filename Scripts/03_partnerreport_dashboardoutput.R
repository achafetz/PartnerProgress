##   Partner Performance by SNU
##   COP FY17
##   Aaron Chafetz
##   Purpose: generate output for Excel monitoring dashboard
##   Date: June 20, 2016 (STATA)
##   Updated: 8/31/17


### NOTES

#   - Data sources: 
#     - ICPI_Fact_View_PSNU_IM  [ICPI Data Store]
#     - FY12-16 Standard COP Matrix Report [FACTS Info]
#   - Report aggregates DSD and TA
#   - Report uses Totals and MCAD

######################################################################################



### SETUP

# Which outputs to produce? 0 = No, 1 = Yes
  global_output   <- 0  #full global dataset
  equip_output    <- 1  #full global dataset
  ctry_output     <- 1 	#one dataset for every OU
  sel_output      <- 1	#just an outut for select OU specified below
  sel_output_list <- c("Zambia")  #OU selection (countries in quotes with commas in between countries)
  
#set today's date for saving
  date = format(Sys.Date(), format="%d%b%Y")
  
#set date of frozen instance - needs to be changed w/ updated data
  datestamp = "20170815_v1_1"


  	
### KEY VARIABLES SUBSETTING
	
  #import/open data	
  	fvdata <- read_delim(file.path(datafv, paste("ICPI_FactView_PSNU_IM_", datestamp, ".txt", sep="")), 
  	                     "\t", escape_double = FALSE, trim_ws = TRUE)
  	
  # change all header names to lower case to make it easier to use
  	names(fvdata) <- tolower(names(fvdata))
  	
  #SNU prioritizations - remove FY16, rename FY17, and change missing to [not classified]
  	df_ppr <- fvdata %>% 
  	  select(-fy16snuprioritization) %>%
      rename(snuprioritization=fy17snuprioritization) %>%
      mutate(snuprioritization = ifelse(is.na(snuprioritization),"[not classified]", snuprioritization))	%>%
  	  
  	 rm(fvdata)
  	
  #create new indicator variable for only the ones of interest for analysis
  	# for most indicators we just want Total Numerator; include MCAD for HTS, HTS_POS, TX_NEW, and TX_CURR; include denominators for TB_STAT and TB_ART
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
  	       indicator = ifelse((indicator=="TB_STAT" & disaggregate=="Total Denominator"),"TB_STAT_D",indicator))
   

  	
### OFFICIAL NAMES
	
  #import official mech and partner names; source: FACTS Info
  	df_names <- read_excel(file.path(rawdata,"FY12-16 Standard COP Matrix Report-20170822.xls"), skip = 1)
  	
  #rename variables
  	names(df_names) <- c("operatingunit", "mechanismid", "primepartner_2014", "implementingmechanismname_2014", 
  	                     "primepartner_2015", "implementingmechanismname_2015", "primepartner_2016", "implementingmechanismname_2016",
  	                     "primepartner_2017", "implementingmechanismname_2017")
  	
  #figure out latest name for IM and partner (should both be from the same year)
  	df_names <- df_names %>%
  	  
  	  #reshape long
  	    gather(type, name, primepartner_2014, implementingmechanismname_2014, 
  	         primepartner_2015, implementingmechanismname_2015, primepartner_2016, implementingmechanismname_2016,
  	         primepartner_2017, implementingmechanismname_2017) %>%
  	  
  	  #split out type and year (eg type = primeparnter_2015 --> type = primepartner,  year = 2015)
  	    separate(type, c("type", "year"), sep="_") %>%
  	  
  	  #drop lines/years with missing names
  	    filter(!is.na(name)) %>%
  	  
  	  #group to figure out latest year with names and keep only latest year's names (one obs per mech)
    	  group_by(operatingunit, mechanismid, type) %>%
    	  filter(year==max(year)) %>%
    	  ungroup() %>%
  	  
  	  #reshape wide so primepartner and implementingmechanismname are two seperate columsn to match fact view dataset
  	    spread(type, name) %>%
  	  
  	  #keep names with mechid (converted to string) for merging into main df, renaming (_F) to identify as from FACTS
    	  select(mechanismid, implementingmechanismname, primepartner) %>%
    	  mutate(mechanismid =  as.character(mechanismid)) %>%
    	  rename(implementingmechanismname_F = implementingmechanismname, primepartner_F = primepartner)
  	  
  #merge in official names
    df_ppr <- left_join(df_ppr, df_names, by="mechanismid")
    rm(df_names)
     
  #replace prime partner and mech names with official names
  	df_ppr <- df_ppr %>%
  	   mutate(implementingmechanismname = ifelse(is.na(implementingmechanismname_F), implementingmechanismname, implementingmechanismname_F), 
  	                  primepartner = ifelse(is.na(primepartner_F), primepartner, primepartner_F)) %>%
  	   select(-ends_with("_F")) %>%
  	 
  	   
  	   
### CLEANING 
	 
  #create single, standardized age/sex disagg for MCAD
	  mutate(disagg = ifelse(ismcad=="Y", paste(age, sex, sep="/"), "Total")) %>%
	  
  #aggregate by subset variable list so only one line per mech/psnu/ind/disagg
    group_by(operatingunit, countryname, psnu, psnuuid, snuprioritization,
             fundingagency, primepartner, mechanismid, implementingmechanismname,
             indicator, disagg) %>%
    summarize_at(vars(starts_with("fy")), funs(sum(., na.rm=TRUE))) %>%
    ungroup()
  	 

  	 
### TX_NET_NEW CREATION
 
  #subset to just TX_CURR which will become NET NEW
  	df_netnew <- df_ppr %>%
  	  filter(indicator=="TX_CURR") %>%
  	  mutate(indicator = "TX_NET_NEW") %>%
	
	#create net new variables (_nn) 
	    mutate(fy2015q4_nn =  fy2015q4 - fy2015q2,
	           fy2016q2_nn =  fy2016q2 - fy2015q4,
	           fy2016q4_nn =  fy2016q4 - fy2016q2,
	           fy2017q1_nn =  fy2017q1 - fy2016q4,
	           fy2017q2_nn =  fy2017q2 - fy2017q1,
	           fy2017q3_nn =  fy2017q3 - fy2017q2,
	           fy2017_targets_nn = fy2017_targets - fy2016q4) %>%
  	  
	 #replace actual periods with net_new values calculated
  	  mutate(fy2015q2 = 0, 
  	         fy2015q3 = 0,
  	         fy2015q4 =  fy2015q4_nn,
  	         fy2015apr = 0,
  	         fy2016_targets = 0,
  	         fy2016q1 =  0,
  	         fy2016q2 =  fy2016q2_nn,
  	         fy2016q3 =  0,
  	         fy2016q4 =  fy2016q4_nn,
  	         fy2016apr = fy2016q2_nn + fy2016q4_nn, 
  	         fy2017q1 =  fy2017q1_nn,
  	         fy2017q2 =  fy2017q2_nn,
  	         fy2017q3 =  fy2017q3_nn,
  	         fy2017_targets = fy2017_targets_nn) %>%
  	  
    #drop calculated indicators
	    select(-ends_with("_nn")) 
	  
	  #append TX_NET_NEW onto main dataframe
  	  df_ppr <-  bind_rows(df_ppr, df_netnew)
	    rm(df_netnew)
	
### FINAL CLEANUP 

  #create cumulative indicator (replace NAs with zero to calculate sum in mutate)
    #change TX_CURR to current period (snapshot rather than cumulative)
    #other snapshot indicators should be either NA, Q2 or Q4 depending on point in year
	  #all other indicators are cumulative, add in quarters each pd
    df_ppr[is.na(df_ppr)] <- 0
  	df_ppr <- df_ppr %>% 
	  mutate(fy2017cum = ifelse(indicator=="TX_CURR", fy2017q3, 
	                     ifelse(indicator %in% c("KP_PREV","PP_PREV", "OVC_HIVSTAT", "OVC_SERV", 
	                                             "TB_ART", "TB_STAT", "TX_TB", "GEND_GBV", "PMTCT_FO", 
	                                             "TX_RET", "KP_MAT"), fy2017q2, 
	                            fy2017q1 + fy2017q2 + fy2017q3)))
	
  #return the missing/0 values back to NA
	  df_ppr[df_ppr==0] <- NA
	
	#remove rows with all missing values via reshape long and then back to wide
	  df_ppr <- df_ppr %>%
	    gather(period, value, contains("fy")) %>%
	    drop_na(value) %>%
	    spread(period, value) %>%
	  
	  #add future periods if they don't yet exist
	    mutate(fy2017q4 = NA) %>%
	  
	#reorder for output
    select(operatingunit, countryname, psnu, psnuuid, snuprioritization,
           fundingagency, primepartner, mechanismid, implementingmechanismname,
           indicator, disagg, fy2015q2, fy2015q3, fy2015q4, fy2015apr, fy2016_targets,
           fy2016q1, fy2016q2, fy2016q2, fy2016q3, fy2016q4, fy2016apr, fy2017_targets,
           fy2017q1, fy2017q2, fy2017q3, fy2017q4, fy2017cum)
	    

	
### EXPORT
	  
	  
  #global
	  if (global_output==1){
	    print("GLOBAL OUTPUT")
	    write.csv(df_ppr, file.path(exceloutput, paste("ICPIFactView_SNUbyIM_", date, "_GLOBAL.csv", sep="")), na="")
	  }
	  	 	  
	#determine country(s) for export - if selected country(s), used those, otherwise all OUs  
	  if(sel_output==1){
	    ou_list <- sel_output_list
	  } else{
	    ou_list <- levels(factor(df_ppr$operatingunit))
	  }
	  
	 #individual country files
	  if(ctry_output==1 | sel_output==1) {
	    for (ou in ou_list){
	      print(ou)
	      df_ou_temp <- df_ppr %>%
	        filter(operatingunit == ou)
	        write.csv(df_ou_temp, file.path(exceloutput, paste("ICPIFactView_SNUbyIM_", date, "_", ou,".csv", sep="")), na="")
	      rm(df_ou_temp)
	    }
	  }
	    
	  
	  
	 #EQUIP only
	  if (equip_output==1){
	    print("EQUIP OUTPUT")
	    
	    #import list of EQUIP mechanisms
	    equip_list <- read_csv(file.path(rawdata,"equip_mech_list.csv"))
	    
	    #clean up to just mechanism and concert to string
	    equip_list <- equip_list %>%
	      select(mechanismid)%>%
	      mutate(mechanismid = as.character(mechanismid))
	    df_equip <- right_join(df_ppr, equip_list, by = "mechanismid")
	    
	    #export
	    write.csv(df_equip, file.path(exceloutput, paste("ICPIFactView_SNUbyIM_", date, "_EQUIP.csv", sep="")), na="")
	    rm(df_equip)
	  }
	  

	  
	  
	  
	  
	  
	
