
#' Exract PLHIV and POP for PPR context
#'
#' @param folderpath file path to the folder that contains the NAT_SUBNAT file
#'
#' @return
#' @export
#'
#' @importFrom dplyr %>%
#'
#' @examples
#' df_impatt <- pull_impatt("~/ICPI/Data")
#' 
pull_impatt <- function(folderpath){

  df <- readr::read_rds(Sys.glob(file.path(folderpath, "ICPI_FactView_NAT_SUBNAT_*.Rds")))
  
  #TEMP, need updated dataset with actually names and fy18 data
    df <- df %>% 
      dplyr::rename(currentsnuprioritization = fy18snuprioritization,
                    value = fy2017)
    
  #keep just POP and PLHIV
    df <- df %>% 
      dplyr::filter(indicator %in% c("POP_NUM", "PLHIV"), disaggregate == "Total Numerator") %>% 
      dplyr::select(region, operatingunit, countryname, psnuuid, psnu, currentsnuprioritization, indicator, value) %>% 
      dplyr::filter(value!=0, !is.na(value))
    
  #export
    readr::write_csv(df, here::here("ExcelOutput", "PPRdata_impatt.csv"), na = "")
}