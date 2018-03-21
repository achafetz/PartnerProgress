# Partner Performance by SNU
# A.Chafetz, USAID
# Purpose: initialize packages, folder structure, and global file paths
# Adapted from T. Essam, USAID
# Updated: 8/31/17 

#' Initialize folder structure with sub folders
#'
#' @details 
#' Adapted from T. Essam, USAID [Stata]
#' @param projectname name of the project
#' @param projectpath path to the folder where you want your project to sit
#' @param ... subfolders to add in list, c("x", "y")
#'
#' @examples
#' initialize_fldr("NewProject", "~/GitHub", "RawData", "Documents", "Scripts", "Output")

initialize_fldr <- function(projectname, projectpath, ...){

## FILE PATHS ##
  #  must be run each time R project is opened
  # Choose the project path location to where you want the project parent folder to go on your machine.
    setwd(projectpath)

  # Set up project folder
    dir.create(file.path(projectname), showWarnings = FALSE)
    setwd(file.path(projectpath, projectname))

  # Run initially to set up folder structure
    folderlist <- list(...)
    for (f in folderlist){
      dir.create(file.path(projectpath, projectname, f))
      #assign(tolower(f), file.path(projectpath, projectname, f))
    }
  
  # assign additional folders outside of project folder (due to large file size)
    #datafv <- "C:/Users/achafetz/Documents/ICPI/Data/"

}   
    
