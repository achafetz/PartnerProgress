
#' Check OU Aggregate MER Structured Dataset against PPR ouput from runPPR.R
#'
#' @param opunit operatingunit to check
#' @param filepath_fv filepath to current PSNU_IM file
#'
#' @export
#'
#' @importFrom dplyr %>%
#'
#' @examples
#' \dontrun{
#' check("ICPI/Data/ICPI_MER_Structured_Dataset_PSNU_IM_20180215_v1_3.Rds", "Malawi") }
#'
#'
pprcheck <- function(filepath_fv, opunit){

  df_check <- readr::read_rds(filepath_fv) %>%
    dplyr::filter(operatingunit == opunit)

  pd <- ICPIutilities::identifypd(df_check, "full")
  ind <-
    ICPIutilities::identifypd(df_check, "quarter") %>%
    key_ind(.)
  
  
  #calculate achievement
  df_agg <- dplyr::mutate_(df, .dots = setNames(fcn, var_name))
  
  #setup for select and calculating achievement with mutate_
  fy <- ICPIutilities::identifypd(df_check, "year")
  prior_apr <- paste0("fy", fy - 1, "apr")
  curr_cum <- paste0("fy", fy, "cum")
  curr_targets <- ICPIutilities::identifypd(df_check, "target")
  var_name <- paste0("fy", fy, "ach")
  fcn <- paste0("round(", curr_cum, "/", curr_targets, ", 2)")

  df_check %>% 
    dplyr::filter(indicator %in% ind, 
                  standardizeddisaggregate %in% c("Total Numerator", "Total Denominator")) %>% 
    ICPIutilities::add_cumulative() %>% 
    dplyr::group_by(fundingagency, indicator, numeratordenom) %>% 
    dplyr::summarize_at(dplyr::vars(prior_apr, curr_cum, curr_target), sum, na.rm = TRUE) %>% 
    dplyr::ungroup() %>% 
    dplyr::mutate(indicator = ifelse(numeratordenom == "D", paste0(indicator, "_D"), indicator)) %>% 
    dplyr::select(-numeratordenom) %>% 
    dplyr::mutate_(df, .dots = setNames(fcn, var_name)) %>% 
    dplyr::filter(is.finite(fy2018ach)) %>% 
    dplyr::arrange(indicator, fy2018ach) %>% 
    knitr::kable(format.args = list(big.mark = ",", zero.print = FALSE))
}
