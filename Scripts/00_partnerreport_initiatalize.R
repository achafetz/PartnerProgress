# Partner Performance by SNU
# A.Chafetz, USAID
# Purpose: initialize packages, folder structure, and global file paths
# Adapted from T. Essam, USAID
# Updated: 8/29/17 


## DEPENDENT PACKAGES ##
lib <- c("plyr", "tidyverse", "readxl", "readr", "ggplot2")
lapply(lib, require, character.only = TRUE)

## FILE PATHS ##
#  must be run each time R project is opened
# Choose the project path location to where you want the project parent 
#   folder to go on your machine.
projectpath <- "C:/Users/achafetz/Documents/GitHub"
setwd(projectpath)

# Run a macro to set up study folder
pfolder <- "PartnerProgress" # Name the folder name here
dir.create(file.path(pfolder), showWarnings = FALSE)
setwd(file.path(projectpath, pfolder))

#Run initially to set up folder structure
#Choose your folders to createa and and stored as values
folderlist <- c("RawData", "Documents", "Scripts", "ExcelOutput", "StataOutput")
for (f in folderlist){
  dir.create(file.path(projectpath, pfolder, f))
  assign(tolower(f), file.path(projectpath, pfolder, f,"/"))
}
#additional folders outside of project folder (due to large file size)
datafv <- "C:/Users/achafetz/Documents/ICPI/Data/"

#clean up stored values
rm(lib, projectpath, pfolder, folderlist, f)