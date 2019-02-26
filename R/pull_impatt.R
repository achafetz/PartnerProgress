
#' Exract PLHIV and POP for PPR context
#'
#' @param folderpath file path to the folder that contains the NAT_SUBNAT file
#' 
#' @export
#' 
#' @importFrom dplyr %>%
#'
#' @examples
#' \dontrun{
#' df_impatt <- pull_impatt("~/ICPI/Data") }
#' 
pull_impatt <- function(folderpath){

  df <- readr::read_rds(Sys.glob(file.path(folderpath, "ICPI_MER_Structured_Dataset_NAT_SUBNAT_*.Rds")))
  
  #TEMP, need updated dataset with actually names and fy18 data
    df <- df %>% 
      dplyr::rename(snuprioritization = fy18snuprioritization,
                    value = fy2017)
    
  #keep just POP and PLHIV
    df <- df %>% 
      dplyr::filter(indicator %in% c("POP_NUM", "PLHIV"), disaggregate == "Total Numerator") %>% 
      dplyr::select(region, operatingunit, countryname, psnuuid, psnu, snuprioritization, indicator, value) %>% 
      dplyr::filter(value!=0, !is.na(value))
    
  #export
    readr::write_csv(df, "ExcelOutput/PPRdata_impatt.csv", na = "")
}