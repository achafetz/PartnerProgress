#' Add cumulative value for current FY
#'
#' @param df data frame to apply 
#' @param fy current fiscual year
#' @param q current quarter
#'
#' @importFrom dplyr %>%
#'
#' @examples
#' df_mer <- cumulative(cumulative, 2018, 1)


cumulative <- function(df, fy, q){
  
  #contatenate variable name, eg fy2018cum
    varname <- paste0("fy", fy, "cum")
  #add q to end of fyfr select function
    fy <- paste0("fy", fy, "q")
  #generate cumulative value 
    #if its Q4, just use APR value
    if(q == 4){
      df <- df %>% 
        mutate(!!varname := get(paste0("fy", fy, "apr")))
    } else {
      df_cum <- df %>% 
        #keep "meta" data and any quarterly values from current fy
        dplyr::select(region:ismcad, dplyr::starts_with(curr_fy)) %>% 
        #reshape long (and then going to aggregate)
        tidyr::gather(pd, !!varname, dplyr::starts_with(curr_fy), na.rm  = TRUE) %>% 
        #convert to character  for grouping
        dplyr::mutate(coarsedisaggregate = as.character(coarsedisaggregate)) %>% 
        #aggregating over all quaters, so remove
        dplyr::select(-pd) %>% 
        #group by meta data
        dplyr::group_by_if(is.character) %>% 
        #aggregate to create cumulative value
        dplyr::summarise_at(vars(!!varname), ~ sum(.)) %>% 
        dplyr::ungroup() %>% 
        #convert back to logical for merging
        dplyr::mutate(coarsedisaggregate = as.logical(coarsedisaggregate))
        
     #merge cumulative back onto main df 
      df <- full_join(df, df_cum)
    }
    
}
