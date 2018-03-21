#' Add cumulative value for current FY
#'
#' @param df data frame to apply 
#' @param fy current fiscual year
#' @param qtr current quarter
#'
#' @importFrom dplyr %>%
#'
#' @examples
#' df_mer <- cumulative(cumulative, 2018, 1)


cumulative <- function(df, fy, qtr){
  
  #contatenate variable name, eg fy2018cum
    varname <- paste0("fy", fy, "cum")
  #add q to end of fyfr select function
    fy_str <- paste0("fy", fy, "q")
  #generate cumulative value 
    #if its Q4, just use APR value
    if(qtr == 4){
      df <- df %>% 
        mutate(!!varname := get(paste0("fy", fy, "apr")))
        return(df)
    } else {
    
    #keep "meta" data 
      df_meta <- df %>% 
        dplyr::select_if(is.character)
    #and any quarterly values from current fy
      df_data <- df %>% 
        dplyr::select(dplyr::starts_with(fy_str)) 
    #join together
      df_cum <- dplyr::bind_cols(df_meta, df_data)
      
      df_cum <- df_cum %>% 
        #reshape long (and then going to aggregate)
        tidyr::gather(pd, !!varname, dplyr::starts_with(fy_str), na.rm  = TRUE) %>% 
        #aggregating over all quaters, so remove
        dplyr::select(-pd) %>% 
        #group by meta data
        dplyr::group_by_if(is.character) %>% 
        #aggregate to create cumulative value
        dplyr::summarise_at(vars(!!varname), ~ sum(.)) %>% 
        dplyr::ungroup()

     #merge cumulative back onto main df 
      df <- full_join(df, df_cum)
      
      #adjust semi annual indicators
      semi_ann <- c("KP_PREV", "PP_PREV", "OVC_HIVSTAT", "OVC_SERV", "TB_ART",
                    "TB_STAT", "TX_TB", "GEND_GBV", "PMTCT_FO", "TX_RET", "KP_MAT")
      if(qtr %in% c(2, 3)) {
        df <- dplyr::mutate(df, !!varname := ifelse(indicator %in% semi_ann, get(paste0(fy_str, "2")), get(!!varname)))
      }
      
      #adjust snapshot indicators to equal current quarter
      snapshot <- c("TX_CURR")
      df <- dplyr::mutate(df, !!varname := ifelse(indicator %in% snapshot, get(paste0(fy_str, qtr)), get(!!varname)))
      
      return(df)
    }
    
}
