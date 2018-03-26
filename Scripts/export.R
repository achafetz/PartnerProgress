#' Export as base dataset(s) for PPR template
#'
#' @param df dataframe to export
#' @param opunit which operatingunit should an output be created for?
#'
#' @return
#' @export 
#' 
#' @importFrom dplyr %>%
#'
#' @examples
#'  export(df_mer, "Kenya")
#'  
export <- function(df, opunit){

  print(paste("export dataset:", opunit))
  filename <- 
    paste0("PPRdata_", opunit,"_", fy_save, ".csv") 
  
  if(stringr::str_detect(opunit, "GLOBAL") == FALSE) {
    df %>% 
      dplyr::filter(operatingunit == opunit) %>% 
    readr::write_csv(here::here("ExcelOutput", filename), na = "")
    invisible(df)
  } else {
    readr::write_csv(df, here::here("ExcelOutput", filename), na = "")
  }
    
}


