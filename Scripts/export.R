#' Export as base dataset(s) for PPR template
#'
#' @param opunit which operatingunit should an output be created for?
#'
#' @return
#' @export 
#' 
#' @importFrom dplyr %>%
#'
#' @examples
#'  df_mer <- export("Kenya")
#'  
export <- function(opunit){

  print(paste("export dataset:", opunit))
  filename <- 
    paste("PPRdata", opunit, fy_save, date, sep = "_") %>% 
    paste0(., ".csv")
  
  if(opunit != "GLOBAL") {
    df_x <- df_ppr %>% 
      dplyr::filter(operatingunit == opunit) 
    readr::write_csv(df_x, here::here("ExcelOutput", filename))
  } else {
    readr::write_csv(df_ppr, here::here("ExcelOutput", filename))
  }
    
}


