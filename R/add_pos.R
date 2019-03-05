#' Add missing HTS_TST_POS, PMTCT_STAT_POS, or TB_STAT_POS
#'
#' @param df dataframe with missing _POS
#' @param ind indicator: HTS_TST, PMTCT_STAT, or TB_STAT
#' @param pd period to add _POS to
#'
#' @export
#' @importFrom magrittr %>%

add_pos <- function(df, ind, pd = fy2019_targets){
  
  #quote period (to run with NSE)
  pd <- dplyr::enquo(pd)
  
  #identify the disagg to keep based on the indicator supplied
  disagg <- dplyr::case_when(ind == "PMTCT_STAT" ~ "Age/Sex/KnownNewResult",
                             ind == "HTS_TST" ~ c("Modality/Age/Sex/Result",
                                                  "Modality/Age Aggregated/Sex/Result"),
                             ind == "TB_STAT" ~ c("Age Aggregated/Sex/KnownNewPosNeg",
                                                  "Age/Sex/KnownNewPosNeg"))
  #name of the _POS indicator
  ind_pos <- paste0(ind, "_POS")
  
  #filter to correct indicator and disagg, summarize to keep just the correct period
  df_pos <- df %>% 
    dplyr::filter(indicator == ind,
                  standardizeddisaggregate %in% disagg,
                  resultstatus == "Positive") %>%
    dplyr::group_by(operatingunit, countryname, psnu, psnuuid, snuprioritization,
                    fundingagency, primepartner, mechanismid, implementingmechanismname,
                    indicator, standardizeddisaggregate, sex, agecoarse) %>% 
    dplyr::summarise_at(dplyr::vars(!!pd), sum, na.rm = TRUE) %>% 
    dplyr::ungroup() %>% 
    dplyr::filter_at(dplyr::vars(!!pd), ~ . > 0) %>% 
    dplyr::mutate(indicator = ind_pos)
  
  #create a total numerator from the above
  df_pos_tn <- df_pos %>% 
    dplyr::mutate(standardizeddisaggregate = "Total Numerator") %>% 
    dplyr::group_by(operatingunit, countryname, psnu, psnuuid, snuprioritization,
                    fundingagency, primepartner, mechanismid, implementingmechanismname,
                    indicator, standardizeddisaggregate) %>% 
    dplyr::summarise_at(dplyr::vars(!!pd), sum, na.rm = TRUE) %>% 
    dplyr::ungroup()
  
  #bind numerator and disagg onto main data frame 
  if(ind == "HTS_TST")
    df <- dplyr::mutate(df, fy2019_targets = ifelse(indicator == "HTS_TST_POS" & standardizeddisaggregate == "Total Numerator", NA, fy2019_targets))
  
  df <- dplyr::bind_rows(df, df_pos_tn)
  
  if(ind != "HTS_TST")
    df <- dplyr::bind_rows(df, df_pos)
  
  return(df)
}
