## Partner Progress Report

[![Build Status](https://travis-ci.org/achafetz/PartnerProgress.svg?branch=master)](https://travis-ci.org/achafetz/PartnerProgress)

The package is used to create the data output that underlies the ICPI Partner Progress Reports (PPRs) which are generated twice a quarter (initial and post-cleaning). Historically, the data was [created in Stata](https://github.com/achafetz/PartnerProgress/tree/master/Archive_Stata) and required slight tweaks every quarter. Starting with FY18Q1, the scripts were converted into a automated package. The output is then used to populate an Excel template via [VBA](https://github.com/achafetz/PartnerProgress/tree/master/VBA) and the reports are then posted to [PEPFAR Sharepoint](https://www.pepfar.net/OGAC-HQ/icpi/Products/Forms/AllItems.aspx?RootFolder=%2FOGAC-HQ%2Ficpi%2FProducts%2FICPI%20Approved%20Tools%20%28Most%20Current%20Versions%29%2FPPR&FolderCTID=0x0120004DAC66286D0B8344836739DA850ACB95&View=%7B58E3102A-C027-4C66-A5C7-84FEBE208B3C%7D).

### Create the PPR dataset

1) Install the package

```{r}
#install
  install.packages("devtools")
  devtools::install_github("achafetz/PartnerProgress")
#load package
  library("genPPR")
```

2) Setup folder - [Clone this repository](https://github.com/achafetz/PartnerProgress/archive/master.zip) to your local machine to have most of the folder structure and some data. 

```{r}
#setup any missing folders
  initialize_fldr(projectname = "PartnerProgress", #don't change this line
                  projectpath"~/GitHub", #change to match where you want the project folder created locally
                  "RawData", "Documents", "R", "ExcelOutput", "Reports") #don't change this line
```

3) Download the current ICPI MER Structured PSNUxIM dataset from the [Data Store on PEPFAR Sharepoint](https://www.pepfar.net/OGAC-HQ/icpi/Products/Forms/AllItems.aspx?RootFolder=%2FOGAC-HQ%2Ficpi%2FProducts%2FICPI%20Data%20Store%2FMER&FolderCTID=0x0120004DAC66286D0B8344836739DA850ACB95&View=%7B58E3102A-C027-4C66-A5C7-84FEBE208B3C%7D). You will need to convert it to an rds file prior to running this package. You can save the rds file in the `RawData` folder.

```{r}
#convert MSD from .txt to .rds
  devtools::install_github("ICPI/ICPIutilities")
  ICPIutilities::read_msd("~/Data/ICPI_MER_Structured_Dataset_OU_IM_FY17-18_20180515_v1_1")
```
If you want to run this with an inprocess dataset from DATIM, you will need to [run the `match_msd()` function from `ICPIUtilities`](https://github.com/ICPI/ICPIutilities#match_msd) to have the correct file name and saved as an rds.

```{r}
#ALTERNATIVE: IF USING IN PROCESS DATA FROM DATIM
  devtools::install_github("ICPI/ICPIutilities")
  ICPIutilities::match_msd("~/Downloads/PEPFAR-Data-Genie-OUByIMs-2018-11-13.zip")
PEPFAR-Data-Genie-OUByIMs-2018-11-13
```

4) Create the PPR dataset - run the main script, `genPPR()` from the package to create the underlying dataset that feeds into the template

```{r}
#create global and OU output
  genPPR("~/ICPI/Data", folderpath_output = "~/ExcelOutput")
  
#alternatively, you can just create a specific OU output
  genPPR("~/ICPI/Data", 
         output_global = FALSE, 
         output_ctry_all = FALSE, 
         df_return = FALSE, 
         folderpath_output = "~/ExcelOutput",
         output_subset_type = "ou", 
           "Kenya")

#or generate "global" files that contain one or many implementing partners
  genPPR("~/ICPI/Data", 
         output_global = FALSE, 
         output_ctry_all = FALSE, 
         df_return = FALSE, 
         folderpath_output = "~/ExcelOutput", 
         output_subset_type = "mechid", 
           c("18045", "17097")
       )
#or just the global output
  genPPR("~/ICPI/Data", output_ctry_all = FALSE, folderpath_output = "~/ExcelOutput",)
```

===

Disclaimer: The findings, interpretation, and conclusions expressed herein are those of the authors and do not necessarily reflect the views of United States Agency for International Development, Centers for Disease Control and Prevention, Department of State, Department of Defense, Peace Corps, or the United States Government. All errors remain our own.
