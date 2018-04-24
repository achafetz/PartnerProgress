#' Add net new to dataset
#'
#' @param df dataframe to create net new from and add it on
#'
#' @export
#' 
#' @importFrom dplyr %>%
#'
#' @examples
#' \dontrun{
#' df_msd <- combine_netnew(df_msd)}
#' 
#' 
combine_netnew <- function(df){
  
  #save column names/order for binding at end
  msd_order <- names(df)
  
  #keep TX_CURR to create net_new off of  
  df <- df %>% 
    dplyr::filter(indicator == "TX_CURR")
  #ensure coarsedisggregate is a character for grouping
  dplyr::mutate(coarsedisaggregate = as.character(coarsedisaggregate))
  
  #create net new values for results and targets
  df_nn_result <- gen_netnew(df, type = "result")
  df_nn_target <- gen_netnew(df, type = "target")
  
  #create new new for apr by aggregating results data
  df_nn_apr <- df_nn_result %>% 
    #reshape long so years can be aggregated together
    tidyr::gather(pd, val, starts_with("fy2")) %>%
    #remove period, leaving just year to be aggregated together
    dplyr::mutate(pd = stringr::str_remove(pd, "q[:digit:]"),
                  pd = as.character(pd)) %>% 
    #aggregate 
    dplyr::group_by_if(is.character) %>%
    dplyr::summarise(val = sum(val, na.rm = TRUE)) %>% 
    dplyr::ungroup() %>% 
    #rename year with apr to match structured dataset & replace 0's
    dplyr::mutate(pd = paste0(pd, "apr"),
                  val = ifelse(val==0, NA, val)) %>% 
    #reshape wide to match MSD
    tidyr::spread(pd, val)
  
  #join all net new pds/targets/apr together
  df_combo <- full_join(df_nn_result, df_nn_target)
  df_combo <- full_join(df_combo, df_nn_apr)
  
  #add dropped values back in and reoder to append onto original dataframe
  df_combo <- df_combo %>% 
    dplyr::mutate(dataelementuid = NA,
                  categoryoptioncombouid = NA,
                  fy2015q3 = NA,
                  fy2016q1 = NA,
                  fy2016q3 = NA) %>% 
    dplyr::select(msd_order)
  
  #append TX_NET_NEW onto main dataframe
  df_nn <- dplyr::bind_rows(df, df_combo)
  
  return(df_nn)
  
}



#' Create Net New Variable
#'
#' @param df data frame to use
#' @param type either result or target, default = result
#'
#' @export
#' 
#' @importFrom dplyr %>%
#'
#' @examples
#' \dontrun{
#' df_mds_results <- gen_netnew(df_mds, type = "result")}

gen_netnew <- function(df, type = "result"){
  
  #for results, only want to keep quarterly data; for targets, calc off targets and priod q4
    if(type == "result") {
      df_nn <- df %>% 
        dplyr::select(-dplyr::ends_with("targets"), -fy2015q3, -fy2016q1, -fy2016q3)
    } else {
      df_nn <- df %>% 
        dplyr::select(-dplyr::ends_with("q1"), -dplyr::ends_with("q2"), -dplyr::ends_with("q3")) 
      
    }
    
  #aggregate so only one line per mech/geo/disagg
    df_nn <- df_nn %>% 
      #remove uids that different between targets/results and no need for apr value
      dplyr::select(-dataelementuid, -categoryoptioncombouid, -dplyr::ends_with("apr")) %>% 
      #aggregate all quartertly data
      dplyr::group_by_if(is.character) %>% 
      dplyr::summarize_at(dplyr::vars(dplyr::starts_with("fy2")), ~ sum(., na.rm = TRUE)) %>% 
      dplyr::ungroup()
  
  #reshape long to subtract prior pd (keeping full set of pds to ensure nn = pd - pd_lag.1)
    df_nn <- df_nn %>% 
      tidyr::gather(pd, val, dplyr::starts_with("fy2"), factor_key = TRUE) %>% 
      #fill all NAs with zero so net new can be calculated
      dplyr::mutate(val = ifelse(is.na(val), 0, val))
  
  #create new new variables
    df_nn <- df_nn %>%
      #group by all meta data and then order by period within each group
      dplyr::group_by_if(is.character) %>%
      dplyr::arrange(pd) %>% 
      dplyr::mutate(netnew = val - dplyr::lag(val)) %>% 
      dplyr::ungroup() %>% 
      #replace all 0's with NA and change ind name from TX_CURR to TX_NET_NEW
      dplyr::mutate(netnew = ifelse(netnew==0, NA, netnew),
             indicator = "TX_NET_NEW") %>% 
      #remove val since just need net new
      dplyr::select(-val) %>% 
      #reshape wide to bind back onto main data frame
      tidyr::spread(pd, netnew)
   
  #remove Q4 for targets since just needed for target calc and q4 net new here is meaningless/wrong 
    if(type == "target"){
      df_nn <- df_nn %>% 
        dplyr::select(-dplyr::ends_with("q4"))
    }
    
    return(df_nn)
}


