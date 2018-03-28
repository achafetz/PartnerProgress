#' Add cumulative value for current FY
#'
#' @param df data frame to apply
#' @param fy current fiscual year
#' @param qtr current quarter
#'
#' @export
#'
#' @importFrom dplyr %>%
#' @importFrom dplyr vars
#'
#' @examples
#' \dontrun{
#' df_mer <- cumulative(cumulative, 2018, 1)}


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

    #identify "metadata" columns to keep
      lst_meta <- df %>%
        dplyr::select_if(is.character) %>%
        names()
    #aggregate curr fy quarters via reshape and summarize
      df_cum <- df %>%
        #keep "metadata" and any quarterly values from current fy
        dplyr::select(lst_meta, dplyr::starts_with(fy_str))  %>%
        #reshape long (and then going to aggregate)
        tidyr::gather(pd, !!varname, dplyr::starts_with(fy_str), na.rm  = TRUE) %>%
        #aggregating over all quaters, so remove
        dplyr::select(-pd) %>%
        #group by meta data
        dplyr::group_by_if(is.character) %>%
        #aggregate to create cumulative value
        dplyr::summarise_at(dplyr::vars(!!varname), ~ sum(.)) %>% 
        dplyr::ungroup()

     #merge cumulative back onto main df
      df <- dplyr::full_join(df, df_cum)

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
