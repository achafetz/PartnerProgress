#' Generate NET_NEW variable
#'
#' @param df dataset to use/bind net new to
#' 
#' @export
#' 
#' @importFrom dplyr %>%
#' 
#' @examples
#' \dontrun{
#' df_mer <- netnew(df_mer) }
#' 
netnew <- function(df){
  
  #filter df, keeping just TX_CURR, replacing NA with 0 (for calculation), and renameing TX_NET_NEW
    df_netnew <- df %>%
      dplyr::mutate_at(vars(dplyr::starts_with("fy2")), ~ ifelse(is.na(.),0,.)) %>% 
      dplyr::filter(indicator=="TX_CURR") %>%
      dplyr::mutate(indicator = "TX_NET_NEW") 
    
  #create a net new variable, pd - L.pd (prior to FY17 pd - 2L.pd); target = target - L.fyq4
    df_netnew <- df_netnew %>%
      dplyr::mutate(fy2015q4_nn =  fy2015q4 - fy2015q2,
                    fy2016q2_nn =  fy2016q2 - fy2015q4,
                    fy2016q4_nn =  fy2016q4 - fy2016q2,
                    fy2017q1_nn =  fy2017q1 - fy2016q4,
                    fy2017q2_nn =  fy2017q2 - fy2017q1,
                    fy2017q3_nn =  fy2017q3 - fy2017q2,
                    fy2017q4_nn =  fy2017q4 - fy2017q3,
                    fy2017_targets_nn = fy2017_targets - fy2016q4,
                    fy2018q1_nn =  fy2018q1 - fy2017q4,
                    fy2018q2_nn =  fy2018q2 - fy2018q1,
                    fy2018q3_nn =  fy2018q3 - fy2018q2,
                    fy2018q4_nn =  fy2018q4 - fy2018q3,
                    fy2018_targets_nn = fy2018_targets - fy2017q4)
    
  #replace current values (TX_CURR) with the NET_NEW values
    df_netnew <- df_netnew %>%
      dplyr::mutate(fy2015q2 = 0, 
                    fy2015q3 = 0,
                    fy2015q4 =  fy2015q4_nn,
                    fy2015apr = 0,
                    fy2016_targets = 0,
                    fy2016q1 =  0,
                    fy2016q2 =  fy2016q2_nn,
                    fy2016q3 =  0,
                    fy2016q4 =  fy2016q4_nn,
                    fy2016apr = fy2016q2_nn + fy2016q4_nn, 
                    fy2017q1 =  fy2017q1_nn,
                    fy2017q2 =  fy2017q2_nn,
                    fy2017q3 =  fy2017q3_nn,
                    fy2017q4 =  fy2017q4_nn,
                    fy2017apr = fy2017q1_nn + fy2017q2_nn + fy2017q3_nn + fy2017q4_nn,
                    fy2017_targets = fy2017_targets_nn,
                    fy2018q1 =  fy2018q1_nn,
                    fy2018q2 =  fy2018q2_nn,
                    fy2018q3 =  fy2018q3_nn,
                    fy2018q4 =  fy2018q4_nn,
                    fy2018apr = fy2018q1_nn + fy2018q2_nn + fy2018q3_nn + fy2018q4_nn,
                    fy2018_targets = fy2018_targets_nn) %>%
  #remove original calculation
      dplyr::select(-ends_with("_nn"))
    
  #replace future quarters with zero (will get values for pd+1 and target/apr)
    df_netnew <- fill_future_pds(df_netnew, curr_fy, curr_q)
    
  #append TX_NET_NEW onto main dataframe
    df <- bind_rows(df, df_netnew)
}