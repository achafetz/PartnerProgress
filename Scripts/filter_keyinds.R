#' Identify indicators of interest 
#' 
#' @param qtr current quarter
#'
#' @examples
#' df_mer <- key_ind(1)
#' 

key_ind <- function(qtr){
  #q1 
  ind <- c("HTS_TST", "TX_NEW", "PMTCT_EID", "HTS_TST_POS", "PMTCT_STAT", 
           "PMTCT_STAT_POS", "TX_NET_NEW", "TX_CURR", "PMTCT_ART", "VMMC_CIRC")
  #q2 & q3
  if(qtr > 1) {
    ind <- c(ind, "KP_PREV", "PP_PREV", "OVC_HIVSTAT", "OVC_SERV", "TB_ART", 
             "TB_STAT", "TB_STAT_POS", "TB_ART_D", "TB_STAT_D", "TX_TB")
  }
  
  #q4 
  if(qtr == 4) {
    ind <- c(ind, "GEND_GBV", "PMTCT_FO", "TX_RET", "KP_MAT")
  }
  
  return(ind)
}




#' Subset dataframe to just relevant indicators
#'
#' @param df dataframe to subset
#' @param qtr current quarter
#'
#' @importFrom dplyr %>%
#'
#' @examples
#' df_ppr <- filter_keyinds(df_mer, 1)
#' 


filter_keyinds <- function(df, qtr){
  #create new indicator variable for only the ones of interest for analysis
  #rename denominator values _D
  df <- df %>% 
    dplyr::mutate(indicator = ifelse((indicator=="TB_ART" & disaggregate=="Total Denominator"),"TB_ART_D",indicator),
           indicator = ifelse((indicator=="TB_STAT" & disaggregate=="Total Denominator"),"TB_STAT_D",indicator),
           disaggregate = ifelse((indicator %in% c("TB_ART_D", "TB_STAT_D")),"Total Numerator",disaggregate))
  
  #indicators to keep (based on the current quarter)
   ind_list <- key_ind(qtr)
  
  #filter to select indicators (based on quarter)
  df_keyind <- df %>% 
    dplyr::filter(((indicator %in% ind_list) & disaggregate=="Total Numerator") |
             ((standardizeddisaggregate %in% c("MostCompleteAgeDisagg", "Modality/MostCompleteAgeDisagg")) & 
                indicator!="HTS_TST_NEG") & sex!="" & (age %in% c("<15", "15+"))) 
  
    #dplyr::filter(otherdisaggregate!="Unknown Sex")
}

#rm(list = ls(pattern = "^ind"))