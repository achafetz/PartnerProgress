#' Create/Fill future period columns with zero as placeholders
#'
#' @param df dataset to add future columns to
#' @param fy current fiscal year
#' @param qtr current quarter
#'
#' @importFrom dplyr everything
#' 
#' @examples
#' df_mer <- fill_future_pds(df_mer, 2018, 1)
#' 
fill_future_pds <- function(df, fy, qtr){

  #add new columns if not yet at qtr4  
  if(qtr != 4) {
    #n+1 qtruater 
    new_qtrs <- qtr + 1 
    #create new columns for n+1 quater to Q4
    for(i in new_qtrs:4){
      #define variable name, eg fy2018q2
      varname <- paste0("fy", fy, "qtr", i)
      #create variable
      df <- df %>% 
        dplyr::mutate(!!varname := 0)
    }
    #create apr column
    varname <- paste0(fy, "apr")
    df <- df %>% 
      dplyr::mutate(!!varname := 0)
  }
}