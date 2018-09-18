#' Change all prior prioritizations to what is set in current year
#'
#' @param df dataframe to adjust prioritizations on
#'
#' @export
#' @importFrom dplyr %>% 
#' 
reprioritize <- function(df){
  
  #identify current target period
    curr_pd <- ICPIutilities::identifypd(df, pd_type = "target")
    
  #extract psnu prioritizations that exist in current target period
    prioritizations_fy18 <- df %>% 
      dplyr::filter_at(dplyr::vars(curr_pd), dplyr::any_vars(!is.na(.) & .!=0)) %>% 
      dplyr::distinct(psnuuid, snuprioritization) %>% 
      dplyr::select(psnuuid, snuprioritization_curr = snuprioritization)
    
  #apply current prioritizations onto df
    df <- dplyr::full_join(df, prioritizations_fy18, by = "psnuuid") %>% 
      dplyr::mutate(snuprioritization = ifelse(!is.na(snuprioritization_curr), snuprioritization_curr, snuprioritization)) %>% 
      dplyr::select(-snuprioritization_curr)
  
  return(df)
  
}



