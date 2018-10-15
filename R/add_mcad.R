#' Add MCAD variables for FY18 
#'
#' @param df data frame to add 
#'
#' @export
#' @importFrom dplyr %>%
#' 
#' @examples
#' \dontrun{
#' df_mer <- add_mcad(df_mer) }


add_mcad <- function(df){
  
  #keep only MCAD variables
    df_mcad <- dplyr::filter(df, ismcad == "Y")
  
  #identify variables to drop (due to uniqueness) before aggregation which will be added back in at end for rbind
    vars_drop <- df_mcad %>% 
      dplyr::select(c(disaggregate, categoryoptioncomboname, 
                      ageasentered, agefine, agesemifine,  
                      coarsedisaggregate, coarsedisaggregate),
                    dplyr::starts_with("fy2017")) %>% 
      names()
 
  #drop above variables               
    df_mcad <- df_mcad %>% 
      dplyr::select(-dplyr::one_of(vars_drop))

  #covert standard disaggs to match FY17 data to work over time and for aggregation
    df_mcad <- df_mcad %>% 
      dplyr::mutate(standardizeddisaggregate = ifelse(indicator %in% c("TX_CURR", "TX_NEW", "TX_NET_NEW"), 
                                                                "MostCompleteAgeDisagg", 
                                                                "Modality/MostCompleteAgeDisagg")) 
  #identify numeric variables to aggregate
    vars_num <- df_mcad %>% 
      dplyr::select(dplyr::starts_with("fy")) %>% 
      names()
    
  #collapse up to MCAD levels (with removed indicators and using agecoarse)
    df_mcad <- df_mcad %>%
      dplyr::group_by_if(is.character) %>% 
      dplyr::summarise_at(dplyr::vars(vars_num), ~ sum(., na.rm = TRUE)) %>% 
      dplyr::ungroup()

  #add dropped variables back on - add results on as double, everything else as character
    for (v in vars_drop){
      if(grepl("fy", v) == TRUE){
        df_mcad <- dplyr::mutate(df_mcad, !!v := as.double(NA))
      } else {
        df_mcad <- dplyr::mutate(df_mcad, !!v := as.character(NA))
      }
    }

  #arrange 
    vars_arrange <- names(df) #order of orig df
    df_mcad <- df_mcad %>% 
      dplyr::arrange_(.dots = vars_arrange)

  #append
    df <- dplyr::bind_rows(df, df_mcad)

}



