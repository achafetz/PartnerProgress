#' Create/Fill future period columns with zero as placeholders
#'
#' @param df dataset to add future columns to
#' @param fy current fiscal year
#' @param q current quarter
#'
#' @importFrom dplyr everything
#' 
#' @examples
#' df_mer <- fill_future_pds(df_mer)
#' 
fill_future_pds <- function(df, fy, q){

  #add new columns if not yet at q4  
  if(q != 4) {
    #n+1 quater 
    new_qs <- q + 1 
    #create new columns for n+1 quater to Q4
    for(i in new_qs:4){
      #define variable name, eg fy2018q2
      varname <- paste0("fy", fy, "q", i)
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