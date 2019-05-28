#' Identify indicators of interest 
#' 
#' @param qtr current quarter
#' 
#' @export
#' 
#' @examples
#' \dontrun{
#' df_mer <- key_ind(1) }
#' 

key_ind <- function(qtr){
  #q1
  ind <- c("HTS_TST", "TX_NEW", "PMTCT_EID", "HTS_TST_POS", "PMTCT_STAT", 
           "PMTCT_STAT_POS", "TX_CURR", "PMTCT_ART", "VMMC_CIRC", "TX_NET_NEW",
           "TB_ART", "TB_STAT", "TB_STAT_POS", "TB_ART_D", "TB_STAT_D",
           "HTS_INDEX_COM", "HTS_INDEX_FAC")
  #q2 & q3
  if(qtr > 1) {
    ind <- c(ind, "KP_PREV", "PP_PREV", "OVC_HIVSTAT", "OVC_SERV",  "TX_TB")
  }
  
  #q4 
  if(qtr == 4) {
    ind <- c(ind, "GEND_GBV", "PMTCT_FO", "KP_MAT")
  }
  
  return(ind)
}




#' Subset dataframe to just relevant indicators
#'
#' @param df dataframe to subset
#' @param qtr current quarter
#'
#' @export
#' @importFrom dplyr %>%
#'
#' @examples
#' \dontrun{
#' df_ppr <- filter_keyinds(df_mer, 1)  }
#' 


filter_keyinds <- function(df, qtr){
  #create new indicator variable for only the ones of interest for analysis
  #rename denominator values _D
  df <- df %>% 
    dplyr::mutate(indicator = ifelse(indicator %in% c("TB_ART","TB_STAT") &  standardizeddisaggregate=="Total Denominator", paste0(indicator, "_D"), indicator),
                  standardizeddisaggregate = ifelse((indicator %in% c("TB_ART_D", "TB_STAT_D")),"Total Numerator",standardizeddisaggregate))
  
  #indicators to keep (based on the current quarter)
   ind_list <- key_ind(qtr)
  
  #filter to select indicators (based on quarter)
  df_keyind <- df %>% 
    dplyr::filter(indicator %in% ind_list,
                  standardizeddisaggregate=="Total Numerator")
  
  #filter a secondary df that contains age/sex disaggs for select in available quarterly
  df_keyind_disaggs <- df %>% 
    dplyr::filter(dplyr::filter(indicator %in% c("HTS_TST", "HTS_TST_POS", "TX_NEW", "TX_CURR", "TX_NET_NEW"),
                                stringr::str_detect(standardizeddisaggregate, "Sex"),
                                sex!="",
                                trendscoarse %in% c("<15", "15+")))
  
  #join
  df_keyind <- dplyr::bind_rows(df_keyind,df_keyind_disaggs)
  
  return(df_keyind)
}