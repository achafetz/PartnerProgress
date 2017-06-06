## DEPENDENT LIBRARIES ##
library("tidyverse")
library("readxl")
library("ggplot2")



qtl_1 <- .25
qtl_2 <- .4
qtl_3 <- .6

setwd("C:/Users/achafetz/Documents/GitHub/PartnerProgress/ExcelOutput")

df_mwi <- read.csv("ICPIFactView_SNUbyIM_6Jun2017_Malawi.csv", header = TRUE, sep = ",")

df_mwi_usaid<- df_mwi %>%
  filter(indicator %in% c("HTS_TST_POS", "TX_NEW", "TX_NET_NEW", "VMMC_CIRC", "OVC_SERV"),
         fundingagency=="USAID", disagg=="Total") %>%
  select(indicator, fy2017cum, fy2017_targets) %>%
  group_by(indicator) %>%
  summarize_each(funs(sum(., na.rm=TRUE))) %>%
  mutate(achieve = fy2017cum/fy2017_targets, 
         ach_col = ifelse(achieve <= qtl_1, 1,
                          ifelse(achieve>qtl_1 & achieve<=qtl_2, 2,
                                 ifelse(achieve>qtl_2 & achieve<=qtl_3, 3,
                                        ifelse(achieve>qtl_3,4,NA)
                                        )
                                 )
                          )

ggplot(df_mwi_usaid,aes(reorder(indicator, achieve), achieve)) + 
  geom_bar(stat="identity") + 
  labs(x = "", y ="Achievement") +
  scale_y_continuous(labels = scales::percent) + 
  coord_flip() +
  scale_fill_manual()


df_mwi_key<- df_mwi %>%
  filter(indicator %in% c("HTS_TST_POS", "TX_NEW", "TX_NET_NEW", "VMMC_CIRC", "OVC_SERV"),
         fundingagency %in% c("USAID", "HHS/CDC"), disagg=="Total") %>%
  select(indicator, fundingagency, fy2017cum, fy2017_targets) %>%
  group_by(indicator, fundingagency) %>%
  summarize_each(funs(sum(., na.rm=TRUE))) %>%
  mutate(achieve = fy2017cum/fy2017_targets)
  
  
ggplot(df_mwi_key,aes(indicator, achieve)) + 
  geom_bar(stat="identity") + 
  scale_y_continuous(labels = scales::percent) + 
  coord_flip()


df_mwi_usaid <- mutate(df_mwi_usaid, 
        ach_qtl = ifelse(achieve <= qtl_1, 1,
                    ifelse((achieve > qtl_1) & (achieve <= qtl_2), 2,
                        ifelse((achieve >  qtl_2) & (achieve <= qtl_3), 3,
                            ifelse(achieve > qtl_3, 4, NA)
                        )
                    )
                 )
        )