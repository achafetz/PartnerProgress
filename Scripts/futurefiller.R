#' Create/Fill future period columns with zero as placeholders
#'
#' @param df dataset to add future columns to
#'
#' @importFrom dplyr everything
#' 
#' @examples
#' df_mer <- fill_future_pds(df_mer)
#' 
fill_future_pds <- function(df){
  
  #find current quarter & fy
  source(here("Scripts", "currentperiod.R"))
  curr_q <- currentpd(df, "quarter")
  curr_fy <- currentpd(df, "year")
  
  #add new columns if not yet at q4  
  if(curr_q != 4) {
    #n+1 quater 
    new_qs <- curr_q + 1 
    #create new columns for n+1 quater to Q4
    for(i in new_qs:4){
      #define variable name, eg fy2018q2
      varname <- paste0("fy", curr_fy, "q", i)
      #create variable
      df <- df %>% 
        dplyr::mutate(!!varname := 0)
    }
    #create apr column
    varname <- paste0(curr_fy, "apr")
    df <- df %>% 
      dplyr::mutate(!!varname := 0)
  }
}