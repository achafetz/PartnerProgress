## Partner Progress Report

The package is used to create the data output that underlies the ICPI Partner Progress Reports (PPRs) which are generated twice a quarter (initial and post-cleaning). Historically, the data was [created in Stata](https://github.com/achafetz/PartnerProgress/tree/master/Archive_Stata) and required slight tweaks every quarter. Starting with FY18Q1, the scripts were converted into a automated package. The output is then used to populate an Excel template via [VBA](https://github.com/achafetz/PartnerProgress/tree/master/VBA) and the reports are then posted to [PEPFAR Sharepoint](https://www.pepfar.net/OGAC-HQ/icpi/Products/Forms/AllItems.aspx?RootFolder=%2FOGAC-HQ%2Ficpi%2FProducts%2FICPI%20Approved%20Tools%20%28Most%20Current%20Versions%29%2FPPR&FolderCTID=0x0120004DAC66286D0B8344836739DA850ACB95&View=%7B58E3102A-C027-4C66-A5C7-84FEBE208B3C%7D).

### Create the PPR dataset

1) Install the package

```
#install
  install.packages("devtools")
  library("devtools")
  install_github("achafetz/PartnerProgress")
#load package
  library("genPPR")
```

2) Setup folder - Clone this repository to your local machine to have most of the folder structure and some data. Download the current ICPI MER Structured PSNUxIM dataset from the [Data Store on PEPFAR Sharepoint](https://www.pepfar.net/OGAC-HQ/icpi/Products/Forms/AllItems.aspx?RootFolder=%2FOGAC-HQ%2Ficpi%2FProducts%2FICPI%20Data%20Store%2FMER&FolderCTID=0x0120004DAC66286D0B8344836739DA850ACB95&View=%7B58E3102A-C027-4C66-A5C7-84FEBE208B3C%7D). You will need to convert it to an RDS file prior to running this package.

```
#convert Fact Viewv from .txt to .RDS
  devtools::install_github("ICPI/ICPIutilities")
  ICPIutilities::read_msd("~/Data/ICPI_MER_Structured_Dataset_OU_IM_FY17-18_20180515_v1_1")
#setup any missing folders
  initialize_fldr("PartnerProgress", "~/GitHub", "RawData", "Documents", "R", "ExcelOutput")
```

3) Create the PPR dataset - run the main script, `genPPR()` from the package to create the underlying dataset that feeds into the template

```
#create global and OU output
  genPPR("~/ICPI/Data", folderpath_output = "~/Reports")
  
#alternatively, you can just create a specific OU output
  genPPR("~/ICPI/Data", 
         output_global = FALSE, 
         output_ctry_all = FALSE, 
         df_return = FALSE, 
         folderpath_output = "~/Reports",
         output_subset_type = "ou", 
           "Kenya")

#or generate "global" files that contain one or many implementing partners
  genPPR("~/ICPI/Data", 
         output_global = FALSE, 
         output_ctry_all = FALSE, 
         df_return = FALSE, 
         folderpath_output = "~/Reports", 
         output_subset_type = "mechid", 
           c("18045", "17097")
       )
#or just the global output
  genPPR("~/ICPI/Data", output_ctry_all = FALSE, folderpath_output = "~/Reports",)
```

===

Disclaimer: The findings, interpretation, and conclusions expressed herein are those of the authors and do not necessarily reflect the views of United States Agency for International Development, Centers for Disease Control and Prevention, Department of State, Department of Defense, Peace Corps, or the United States Government. All errors remain our own.
