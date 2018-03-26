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
#'  export("Kenya")
#'  
export <- function(opunit){

  print(paste("export dataset:", opunit))
  filename <- 
    paste0("PPRdata_", opunit,"_", fy_save, ".csv") 
  
  if(opunit != "GLOBAL") {
    df_ppr %>% 
      dplyr::filter(operatingunit == opunit) %>% 
    readr::write_csv(here::here("ExcelOutput", filename), na = "")
    invisible(df)
  } else {
    readr::write_csv(df_ppr, here::here("ExcelOutput", filename), na = "")
  }
    
}


