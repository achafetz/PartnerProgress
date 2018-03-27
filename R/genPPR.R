#' Generate PPR export data file
#'
#' Purpose: generate output for Excel monitoring dashboard
#' NOTES
#'   - Data source: ICPI_Fact_View_PSNU_IM  [ICPI Data Store]
#'   - Need current COP Matrix report (renaming to official names)
#'   - Report aggregates DSD and TA
#'   - Report looks at only Totals and MCAD
#'   
#' @param datapathfv what is the file path to the Fact View dataset? eg "~/ICPI/Data"
#' @param output_global export full dataset? logical, default = TRUE
#' @param output_ctry_all export each country? logicial, default = TRUE
#' @param output_subset_type select only subset, either "ou" or "mechid"
#' @param ... add list of countries or mechanisms for `output_subset_type`, eg "18841", "14421"
#' 
#' @export
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
#'   genPPR("~/ICPI/Data", output_global = FALSE, output_ctry_all = FALSE, output_subset_type = "ou", "Kenya", "Malawi")
#' #export two mechanims
#'   genPPR("~/ICPI/Data", output_global = FALSE, output_ctry_all = FALSE, output_subset_type = "mechid", "18234", "18544") }
#'   

genPPR <- function(datapathfv, output_global = TRUE, output_ctry_all = TRUE, output_subset_type = NULL, ...){
  
  sel_group <- dplyr::quos(...)
  
  #import/open data	
  	df_mer <- readr::read_rds(Sys.glob(file.path(datapathfv, "ICPI_FactView_PSNU_IM_*.Rds")))
  	
  #find current quarter & fy
  	source(here::here("R", "currentperiod.R"))
  	curr_q <- currentpd(df_mer, "quarter")
  	curr_fy <- currentpd(df_mer, "year")
  	fy_save <- 
  	  currentpd(df_mer, "full") %>% 
  	  toupper()
  	
  #create future filler columns
  	source(here::here("R", "futurefiller.R"))
  	df_mer <- fill_future_pds(df_mer, curr_fy, curr_q)
  	
  #subset to indicators of interest
  	source(here::here("R", "filter_keyinds.R"))
  	df_ppr <- filter_keyinds(df_mer, curr_q)
  	
  #create net new and bind it on
  	source(here::here("R", "netnew.R"))
  	df_ppr <- netnew(df_ppr)
  
  #apply offical names before aggregating (since same mech id may have multiple partner/mech names)  
    source(here::here("R", "officialnames.R"))
    df_ppr <- officialnames(df_ppr, here::here("RawData"))  
    
  #clean up - create age/sex disagg & replace missing SNU prioritizations
    df_ppr <- df_ppr %>% 
      dplyr::mutate(disagg = ifelse(ismcad=="Y", paste(age, sex, sep="/"), "Total"),
             currentsnuprioritization = ifelse(is.na(currentsnuprioritization),"[not classified]", currentsnuprioritization))
    
  #aggregate by subset variable list
    df_ppr <- df_ppr %>%  
      dplyr::group_by(operatingunit, countryname, psnu, psnuuid, currentsnuprioritization,
                fundingagency, primepartner, mechanismid, implementingmechanismname,
                indicator, disagg) %>%
      dplyr::summarize_at(vars(starts_with("fy")), ~ sum(., na.rm=TRUE)) %>%
      dplyr::ungroup()
  
  #drop missing rows
  	df_ppr <- df_ppr %>%
  	  tidyr::gather(period, value, starts_with("fy"), na.rm = TRUE, factor_key = TRUE) %>%
  	  dplyr::mutate(value = ifelse(value == 0, NA, value)) %>% 
  	  tidyr::drop_na(value) %>%
  	  tidyr::spread(period, value)
  	
  #add future pds back in
  	source(here::here("R", "futurefiller.R"))
  	df_ppr <- fill_future_pds(df_ppr, curr_fy, curr_q)
  
  #add cumulative value for fy
  	source(here::here("R", "cumulative.R"))
  	df_ppr <- cumulative(df_ppr, curr_fy, curr_q)
  	
  #replace all 0's with NA
  	df_ppr[df_ppr==0] <- NA
  
  #export datasets
  	source(here::here("R", "export.R"))
  	
  	#global
    if(output_global == TRUE){
      export(df_ppr, "GLOBAL", fy_save)
    }
    
  	#countries
    if(output_ctry_all == TRUE && output_subset_type != "ou"){
      ou_list <- unique(df_ppr$operatingunit)
      purrr::map(.x = ou_list, .f = ~ export(df_ppr, .x, , fy_save))
    }
  	
  	#select output -  OUs or mechs
  	if(!is.null(output_subset_type) && output_subset_type == "ou"){
  	  ou_list <- C(!!! sel_group)
  	  purrr::map(.x = ou_list, .f = ~ export(df_ppr, .x, fy_save))
  	} else if(!is.null(output_subset_type) && output_subset_type == "mechid"){
  	  dplyr::filter(mechanismid %in% c(!!! sel_group)) %>% 
  	  export(df_ppr, "GLOBAL_SelectMechs", fy_save)   
  	}
  	
}