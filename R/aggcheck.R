
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

  here::here()

  df_check <- readr::read_rds(filepath_fv) %>%
    dplyr::filter(operatingunit == opunit)

  pd <- currentpd(df_check, "full")
  ind <-
    currentpd(df_check, "quarter") %>%
    key_ind(.)

  df_check %>%
    dplyr::filter(indicator %in% ind, standardizeddisaggregate %in% c("Total Numerator","MostCompleteAgeDisagg", "Modality/MostCompleteAgeDisagg")) %>%
    dplyr::group_by(indicator, standardizeddisaggregate, age, sex) %>%
    dplyr::summarise(!!pd := sum(!!pd, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(indicator) %>%
    tidyr::unite(disagg, age, sex, sep = "/") %>%
    dplyr::mutate(disagg = ifelse(stringr::str_detect(disagg, "NA"), "Total", disagg)) %>%
    dplyr::filter(fy2018q1!=0, !is.na(disagg), !stringr::str_detect(disagg, "Unknown Age")) %>%
    knitr::kable(format.args = list(big.mark = ",", zero.print = FALSE))
}
