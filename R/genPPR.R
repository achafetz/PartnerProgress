#' Generate PPR export data file
#'
#' Purpose: generate output for Excel monitoring dashboard
#' NOTES
#'   - Data source: MER Structured Dataset PSNUxIM  [ICPI Data Store]
#'   - Report aggregates DSD and TA
#'   - Report looks at only Totals and coarse age (<15/15+) for testing and treatment
#'
#' @param filepath_msd what is the file path to the MER Structured dataset? eg "~/ICPI/Data/MER_Structured_Dataset_OU_IM_FY17-19_20190517_v1_1.rds"
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
#'   genPPR("~/ICPI/Data/MER_Structured_Dataset_OU_IM_FY17-19_20190517_v1_1.rds", output_ctry_all = FALSE)
#' #view global file
#'   df_ppr <- genPPR("~/ICPI/Data/MER_Structured_Dataset_OU_IM_FY17-19_20190517_v1_1.rds", output_global = FALSE, output_ctry_all = FALSE)
#' #export global and country specific files to populate PPR
#'   genPPR("~/ICPI/Data/MER_Structured_Dataset_OU_IM_FY17-19_20190517_v1_1.rds")
#' #export just Malawi and Kenya
#'   genPPR("~/ICPI/Data/MER_Structured_Dataset_OU_IM_FY17-19_20190517_v1_1.rds", output_global = FALSE, output_ctry_all = FALSE, folderpath_output = "ExcelOutput", output_subset_type = "ou", "Kenya", "Malawi")
#' #export two mechanims
#'   genPPR("~/ICPI/Data/MER_Structured_Dataset_OU_IM_FY17-19_20190517_v1_1.rds", output_global = FALSE, output_ctry_all = FALSE, folderpath_output = "ExcelOutput", output_subset_type = "mechid", "18234", "18544") }
#'

genPPR <- function(filepath_msd, output_global = TRUE, output_ctry_all = TRUE, df_return = FALSE, folderpath_output = "ExcelOutput", output_subset_type = NULL, ...){

  if(tools::file_ext(filepath_msd) != "rds")
    stop("File must be a rds file. From the ICPI/ICPIutilities repo, run read_msd()")
  
  #import/open data
  	df_mer <- readr::read_rds(filepath_msd)
  	
  #find current quarter & fy
  	curr_q  <- ICPIutilities::identifypd(df_mer, "quarter")
  	curr_fy <- ICPIutilities::identifypd(df_mer, "year")
  	fy_save <- ICPIutilities::identifypd(df_mer, "full") %>%
  	           toupper()
  	
  #subset to indicators of interest
  	df_ppr <- filter_keyinds(df_mer, curr_q)
  	
  	rm(df_mer)
  	
  #clean up - create age/sex disagg & replace missing SNU prioritizations
    df_ppr <- df_ppr %>%
      dplyr::mutate(sex = ifelse(trendscoarse == "<15", 
                                 stringr::str_replace(sex, "Female|Male", "Unknown Sex"), 
                                 sex),
                    disagg = ifelse(trendscoarse %in% c("<15", "15+"), 
                                    paste(trendscoarse, sex, sep="/"), 
                                    "Total"),
                    snuprioritization = ifelse(snuprioritization %in% c("~", NA),
                                               "[not classified]", 
                                               snuprioritization)) %>% 
      dplyr::filter(disagg != "15+/Unknown Sex") #only want Male/Female 15+

  #aggregate by subset variable list
    df_ppr <- df_ppr %>%
      dplyr::group_by(operatingunit, countryname, psnu, psnuuid, snuprioritization,
                fundingagency, primepartner, mech_code, mech_name,
                indicator, disagg, fiscal_year) %>%
      dplyr::summarize_at(dplyr::vars(targets:cumulative), sum, na.rm=TRUE) %>%
      dplyr::ungroup()
    
  #reshape wide to match old MSD
    df_ppr <- ICPIutilities::reshape_msd(df_ppr, "wide")
    
  #adjust prioritizations to represent current year targeting
    df_ppr <- reprioritize(df_ppr)
    
  #apply offical names before aggregating (since same mech id may have multiple partner/mech names)
    df_ppr <- ICPIutilities::rename_official(df_ppr)
    
  #include Net New targets (not included in DATIM)
    df_ppr <- include_nn_targets(df_ppr)
    
  #replace all 0's with NA
  	df_ppr[df_ppr==0] <- NA
  
  #subset dataframe to just include needed value columns
  	df_ppr <- limit(df_ppr, curr_fy)
  
  #drop missing rows
  	df_ppr <- dplyr::filter_if(df_ppr, is.numeric, dplyr::any_vars(!is.na(.) & . != 0))
  	
  #export datasets
    #change directory if the directory does not exist
  	if(!dir.exists(folderpath_output))
  	  folderpath_output <- dirname(filepath_msd)
  	
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
