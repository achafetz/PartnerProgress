#' Export as base dataset(s) for PPR template
#'
#' @param df dataframe to export
#' @param opunit which operatingunit should an output be created for?
#' @param savepd period to add to file name, eg FY2018Q1
#' 
#' @export
#' 
#' @importFrom dplyr %>%
#' 
#' @examples 
#' \dontrun{
#'  export(df_mer, "Kenya", "FY2018Q1") }
#'  
export <- function(df, opunit, savepd, folderpath_output){

  print(paste("export dataset:", opunit))
  filename <- 
    paste0("PPRdata_", opunit,"_", savepd, ".csv") 
  
  if(stringr::str_detect(opunit, "GLOBAL") == FALSE) {
    df %>% 
      dplyr::filter(operatingunit == opunit) %>% 
    readr::write_csv(file.path(folderpath_output, filename), na = "")
    invisible(df)
  } else {
    readr::write_csv(df, file.path(folderpath_output, filename), na = "")
  }
    
}


