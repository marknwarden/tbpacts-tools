# =============================================================================
# SCRIPT NAME: 01_trial_data_extractor.R
# PROJECT:     TB Pacts Hackaton
# AUTHOR:      Mark Warden, updated by BHA
# CREATED:     23-June-2025, Updated 3-Nov-2025
# Description: Takes the TB Pacts Dataset, and makes a trial specific dataset.
# Input: Requires the selected study number (usually a 4 digit number)
# Output: A folder of rds files, matching data from the TB pacts, but filtered to a 
# specific trial.
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Setup

#Cleaning Environment and memory
rm(list=ls())
gc()

#Loading Packages
packages <- c("here","tidyverse","assertthat", 'janitor', 'stringr', 'magrittr')

# Loads all the packages
lapply(packages, library, character.only = TRUE)

rm(packages)

# 0. User input ------------------------------------------------

# Where the input data exists (cleaned data)
input <- here::here('data', 'cleaned data', 'tb pacts data')

# Study of Interest
selected_studies <- c(1037) #SimpliciTB trial number, can modify for other trial(s)


# 1. Load packages, preparing work space, and loading data  ----------------------------------

# Reading in raw data
dataset_list<-list.files(input, 
           pattern = '\\.rds$', 
           full.names = T)
raw_data<-lapply(dataset_list,readRDS)
dataset_list<-list.files(input, 
                         pattern = '\\.rds$', 
                         full.names = F)
dataset_list %<>% str_remove(pattern=".rds")
names(raw_data) <- dataset_list

# Cleaning up workspace
rm(dataset_list)
rm(input)

# Creating the study list
selected_studies <- str_c("TB-",selected_studies)
raw_data %<>% lapply(function(x){x %<>% filter(studyid %in% selected_studies)})
rm(selected_studies)

# Filtering out empty datasets
raw_data[names(which((raw_data %>% sapply(nrow))==0))] <-NULL

# Filtering out variables in the datasets that are empty
raw_data <- lapply(raw_data,\(z){z[,names(which(z %>% sapply(\(x){all(x=="" | is.na(x))})))] <- NULL
z %<>% arrange(studyid)})
output_dir <- here::here("data", "SimpliciTB")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

for (nm in names(raw_data)) {
  saveRDS(
    raw_data[[nm]],  
    file.path(output_dir, paste0(nm, "_SimpliciTB.rds"))
  )
}

# 4. Optional: load into environment ------------------------------------------

list2env(raw_data, envir = .GlobalEnv)
rm(raw_data)
gc()
