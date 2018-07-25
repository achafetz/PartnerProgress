
#' Import FY16Q4 data for TX_NET_NEW Calculation
#'
#' @param df dataframe to add archived data onto
#' @param folderpath
#'
#' @export 
#' @importFrom dplyr %>%

import_oldtx <- function(df, folderpath){
  
  #import Archived MSD for TX_NET_NEW Calculation (need FY16Q4 to calc NET NEW in FY17Q1)
    df_tx_old <- readr::read_rds(file.path(folderpath,"ICPI_MER_Structured_Dataset_PSNU_IM_FY15-16_20180515_v1_1.Rds")) %>% 
      dplyr::filter(indicator == "TX_CURR")
    
  #limit just to just meta data (string vars), excluding partner/mech and other UIDs that may lead to misalignment in merge
    lst_meta <- df_tx_old %>% 
      dplyr::select(-c(dataelementuid, categoryoptioncombouid)) %>% 
      dplyr::select_if(is.character) %>% 
      names()
    df_tx_old <- dplyr::select(df_tx_old, lst_meta, fy2016q4)
    
  #rename offical
    df_tx_old <- officialnames(df_tx_old)
    
  #aggregate 
    df_tx_old <- df_tx_old %>% 
      dplyr::group_by_if(is.character) %>% 
      dplyr::summarise(fy2016q4 = sum(fy2016q4, na.rm = TRUE)) %>% 
      dplyr::ungroup() %>% 
      dplyr::filter(fy2016q4 != 0)
    
  #join archive data onto current dataset
    df_merge <- dplyr::full_join(df, df_tx_old)
  
  #reorder so FY16Q4 comes before FY17
    lst_meta <- df_merge %>% 
      dplyr::select_if(is.character) %>% 
      names()
    df_merge <- dplyr::select(df_merge, lst_meta, fy2016q4, dplyr::everything())
    
}
