
#' Limit 
#'
#' @description Velcro identifies generic variable columns - last 6 pds, prior APR value, current cumulative 
#'   value, and current FY targets - and then limits output dataset to 
#' 
#' @param df data frame to apply
#' @param fy current fy, eg 2018
#'
#' @export
#'
#' @importFrom dplyr %>%
#'
#' @examples
#' \dontrun{
#' df_output <- limit(df_mer, 2018)}


limit <- function(df, fy){

  #identify and store all meta data column names
    col_str <- df %>% 
      dplyr::select(-dplyr::starts_with("fy")) %>% 
      names()
  
  #identify and store current quarter and 5 prior quarters
    headers <- names(df)
    col_pds <- headers[stringr::str_detect(headers, "q(?=[:digit:])")] %>% 
      tail(., n =6L)
  
  #identify and store this year's target
    col_fytarget_curr <- paste0("fy", fy, "_targets")
    
  #identify and store last year's apr value
    col_fycum_lag.1 <- paste0("fy", fy - 1, "apr")
  
  #identify and store this year's cum value
    col_fycum_curr <- paste0("fy", fy, "cum")
  
  #list of values to keep and order
    tokeep_order <- c(col_str, col_pds, col_fycum_lag.1, col_fycum_curr, col_fytarget_curr)
  
  #keep just selected value columns  
  df <- df %>% 
    dplyr::select(tokeep_order)
}

