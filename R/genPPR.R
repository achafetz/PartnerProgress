#' Generate PPR export data file
#'
#' Purpose: generate output for Excel monitoring dashboard
#' NOTES
#'   - Data source: ICPI_MER_Structured_Dataset_PSNU_IM  [ICPI Data Store]
#'   - Need current COP Matrix report (renaming to official names)
#'   - Report aggregates DSD and TA
#'   - Report looks at only Totals and MCAD
#'
#' @param folderpath_msd what is the folder path to the ICPI MER Structured dataset? eg "~/ICPI/Data"
#' @param archived_msd_folderpath if importing FY16Q4 data for NET_NEW, identify the folder path where archived file with FY15-16 data sits
#' @param output_global export full dataset? logical, default = TRUE
#' @param output_ctry_all export each country? logicial, default = TRUE
#' @param df_return return a dataframe in R session, default = FALSE
#' @param folderpath_output where do you want the output saved?, default = "ExcelOutput"
#' @param output_subset_type select only subset, either "ou" or "mechid"
#' @param ... add list of countries or mechanisms for `output_subset_type`, eg "18841", "14421"
#'
#' @export
#'
#' @importFrom dplyr %>%
#' @importFrom dplyr vars
#'
#' @examples
#' \dontrun{
#' #export global file
#'   genPPR("~/ICPI/Data", output_ctry_all = FALSE)
#' #view global file
#'   df_ppr <- genPPR("~/ICPI/Data", output_global = FALSE, output_ctry_all = FALSE)
#' #export global and country specific files to populate PPR
#'   genPPR("~/ICPI/Data")
#' #export just Malawi and Kenya
#'   genPPR("~/ICPI/Data", output_global = FALSE, output_ctry_all = FALSE, folderpath_output = "ExcelOutput", output_subset_type = "ou", "Kenya", "Malawi")
#' #export two mechanims
#'   genPPR("~/ICPI/Data", output_global = FALSE, output_ctry_all = FALSE, folderpath_output = "ExcelOutput", output_subset_type = "mechid", "18234", "18544") }
#'

genPPR <- function(folderpath_msd, archived_msd_folderpath = NULL, output_global = TRUE, output_ctry_all = TRUE, df_return = FALSE, folderpath_output = "ExcelOutput", output_subset_type = NULL, ...){

  #import/open data
  	df_mer <- readr::read_rds(Sys.glob(file.path(folderpath_msd, "MER_Structured_Dataset_PSNU_IM_*.Rds")))

  #find current quarter & fy
  	curr_q  <- currentpd(df_mer, "quarter")
  	curr_fy <- currentpd(df_mer, "year")
  	fy_save <- currentpd(df_mer, "full") %>%
  	           toupper()
  
  #add MCAD variable for FY18 (only present prior to FY18)
  	df_ppr <- add_mcad(df_mer)
  	
  #subset to indicators of interest
  	df_ppr <- filter_keyinds(df_ppr, curr_q)

  #apply offical names before aggregating (since same mech id may have multiple partner/mech names)
  	df_ppr <- ICPIutilities::rename_official(df_ppr)
  	
  #create net new and bind it on
  	df_ppr <- combine_netnew(df_ppr, archived_msd_folderpath)

  #clean up - create age/sex disagg & replace missing SNU prioritizations
    df_ppr <- df_ppr %>%
      dplyr::mutate(sex = ifelse(agecoarse == "<15", stringr::str_replace(sex, "Female|Male", "Unknown Sex"), sex),
                    disagg = ifelse(ismcad=="Y", paste(agecoarse, sex, sep="/"), "Total"),
                    snuprioritization = ifelse(is.na(snuprioritization),"[not classified]", snuprioritization)) %>% 
      dplyr::filter(disagg != "15+/Unknown Sex") #only want Male/Female 15+

  #aggregate by subset variable list
    df_ppr <- df_ppr %>%
      dplyr::group_by(operatingunit, countryname, psnu, psnuuid, snuprioritization,
                fundingagency, primepartner, mechanismid, implementingmechanismname,
                indicator, disagg) %>%
      dplyr::summarize_at(dplyr::vars(dplyr::starts_with("fy")), ~ sum(., na.rm=TRUE)) %>%
      dplyr::ungroup()

  #add cumulative value for fy
  	df_ppr <- cumulative(df_ppr, curr_fy, curr_q)

  #replace all 0's with NA
  	df_ppr[df_ppr==0] <- NA
  
  #subset dataframe to just include needed value columns
  	df_ppr <- limit(df_ppr, curr_fy)
  
  #drop missing rows
  	df_ppr <- df_ppr %>%
  	  tidyr::gather(period, value, dplyr::starts_with("fy"), na.rm = TRUE, factor_key = TRUE) %>%
  	  dplyr::mutate(value = ifelse(value == 0, NA, value)) %>%
  	  tidyr::drop_na(value) %>%
  	  tidyr::spread(period, value)
  	
  #export datasets

  	#global
    if(output_global == TRUE){
      export(df_ppr, "GLOBAL", fy_save, folderpath_output)
    }

  	#countries
    if(output_ctry_all == TRUE){
      ou_list <- unique(df_ppr$operatingunit)
      purrr::map(.x = ou_list, .f = ~ export(df_ppr, .x, fy_save, folderpath_output))
    }

  	#capture selection to filter df to
  	group <- dplyr::quos(...)
  	
  	#export selection
  	if(!is.null(output_subset_type) && output_subset_type == "ou"){
  	  purrr::map(.x = group, .f = ~ export(df_ppr, .x, fy_save, folderpath_output))
  	} else if(!is.null(output_subset_type) && output_subset_type == "mechid"){
  	  dplyr::filter(df_ppr, mechanismid %in% c(!!!group)) %>%
  	    export("GLOBAL_SelectMechs", fy_save, folderpath_output)
  	}
  
  	#output data frame
  	if(df_return == TRUE) {
  	  return(df_ppr)
    }
}
