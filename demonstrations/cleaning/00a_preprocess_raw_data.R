# Brian Aldana  
# Original: 24-Nov-2023 | Updated: 18-Apr-2025  
# Script Name: 00a_preprocess_raw_data.R  
# Purpose: Preprocess raw TB Pacts data by applying generic, data-agnostic cleaning steps.  
# Input: Folder containing raw CSV files  
# Output: Cleaned .RData files saved to an output folder  
# Note: Raw data is not included in the repository. Access may be requested at:  
# https://c-path.org/tools-platforms/tb-pacts/

#Cleaning Environment and memory
rm(list=ls())
gc()

#Loading Packages
packages <- c("here","tidyverse","assertthat", 'janitor')

# Confirms needed packages are installed and installs any missing packages
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Loads all the packages
lapply(packages, library, character.only = TRUE)

#Designating file location for the 'here' package

# This line of code (that begins with dput) is quite useful. It lets you copy a
# file path from file explorer or Finder. Then, this code will read the file
# path that you copied from the clipboard, convert it into a file path that R
# understands, and paste it as a string to the console. It is quite useful when
# updating files paths in scripts like this one.
#dput(normalizePath(readClipboard(),winslash="/"))

here::i_am('cleaning/00a_preprocess_raw_data.R')

#getting csv files
csv_files <- list.files(here('data', 'tb pacts data'), 
                        pattern = '\\.csv$', 
                        full.names = F)

#Creating new folder to hold data
output_folder <- here('data', 'cleaned data', 'tb pacts data') #Change this for new data (feel free to use the dput code above)

if(!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = F) #only allows the last subfolder to be created in path
}

#Main cleaning loop
for (csv_file in csv_files) {
  # Extract the part of the filename before the '.csv'
  file_name_no_ext <- sub("\\.csv$", "", csv_file) # Removes the .csv extension
  
  # Construct the RDS file name
  rds_file_name <- paste0(file_name_no_ext, '.rds') # Uses the base name for the RDS file
    
  temp_data <- read.csv(here('data', 'tb pacts data', csv_file), sep= ',') #reading in data file
    
  #makes consitent names
  clean <- clean_names(temp_data)
  
  #Saves file
  write_rds(clean, here('data', 'cleaned data', 'tb pacts data', rds_file_name))
  cat('Saved the file as .Rds:', rds_file_name, '\n') #announcer
}
    
