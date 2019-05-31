
#' Append NET_NEW target
#'
#' @param df data frame to add NET_NEW Targets onto 
#'
#' @importFrom dplyr %>% 
#' @export


include_nn_targets <- function(df){
  
  #identify current targets and prior q4 for calculation
    curr_trgt <- ICPIutilities::identifypd(df, pd_type = "target") %>% dplyr::sym()
    prior_fy <- ICPIutilities::identifypd(df, pd_type = "year", pd_prior = TRUE) 
    prior_q4 <- paste0("fy", prior_fy, "q4") %>% dplyr::sym()
  
  #adjust for under 15 sex being unknown before FY19Q1
    df <- dplyr::mutate(df, sex = ifelse(trendscoarse == "<15", 
                                     stringr::str_replace(sex, "Female|Male", "Unknown Sex"), 
                                     sex))
  #remove for grouping by coarse age
    df <- dplyr::select(df,-c(categoryoptioncomboname, ageasentered, trendsfine, trendssemifine))
  
  #aggregate first so all mech values will be on same line
    df_agg <- df %>% 
      #filter for TX_CURR (NN_Target = TX_CURR_Target - TX_CURR_PRIOR_APR)
      dplyr::filter(indicator == "TX_CURR") %>% 
      #aggregate
      dplyr::group_by_if(is.character) %>% 
      dplyr::summarise_at(vars(!!prior_q4, !!curr_trgt), sum, na.rm = TRUE) %>%
      dplyr::ungroup()  
  
  #setup formula and name for calculating with mutate
    var_name <- dplyr::enquo(curr_trgt)
    
  #gen net new target for all mechanisms 
    df_nn <- df_agg %>%
      #rename indicator TX_NET_NEW
      dplyr::mutate(indicator = "TX_NET_NEW") %>%
      #apply function from above
      dplyr::mutate(!!var_name := !!curr_trgt - !!prior_q4) %>%
      #filter out any targets of 0 to save space
      dplyr::filter_if(is.numeric, dplyr::any_vars(.!= 0)) %>% 
      #remove prior APR
      dplyr::select(-!!prior_q4) 
  
  #append net new onto main df
    df <- dplyr::bind_rows(df, df_nn)
}
