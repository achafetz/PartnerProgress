
#' Append NET_NEW target
#'
#' @param df data frame to add NET_NEW Targets onto 
#'
#' @importFrom dplyr %>% 
#' @export


include_nn_targets <- function(df){
  
  #identify current targets and prior q4 for calculation
    curr_trgt <- ICPIutilities::identifypd(df, pd_type = "target")
    prior_fy <- ICPIutilities::identifypd(df, pd_type = "year", pd_prior = TRUE)
    prior_q4 <- paste0("fy", prior_fy, "q4")
  
  #identify all character columns to keep  
    meta <- df %>% 
      dplyr::select_if(is.character) %>% 
      names() 
    
  #aggregate first so all mech values will be on same line
    df_agg <- df %>% 
      #filter for TX_CURR (NN_Target = TX_CURR_Target - TX_CURR_PRIOR_APR)
      dplyr::filter(indicator == "TX_CURR") %>% 
      #limit to all character cols and cols for calulation 
      dplyr::select_at(dplyr::vars(meta, prior_q4, curr_trgt)) %>%
      #aggregate
      dplyr::group_by_if(is.character) %>% 
      dplyr::summarise_if(is.numeric, sum, na.rm = TRUE) %>%
      dplyr::ungroup() 
  
  #setup formula and name for calculating with mutate_
    var_name <- curr_trgt
    fcn <- paste0(curr_trgt, "-", prior_q4)
    
  #gen net new target for all mechanisms 
    df_nn <- df_agg %>%
      #rename indicator TX_NET_NEW
      dplyr::mutate(indicator = "TX_NET_NEW") %>%
      #apply function from above
      dplyr::mutate_(.dots = setNames(fcn, var_name)) %>%
      #filter out any targets of 0 to save space
      dplyr::filter_if(is.numeric, dplyr::any_vars(.!= 0)) %>% 
      #remove prior APR
      dplyr::select(-!!prior_q4) 
  
  #append net new onto main df
    df <- dplyr::bind_rows(df, df_nn)
}
