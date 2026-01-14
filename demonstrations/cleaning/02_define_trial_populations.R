# =============================================================================
# SCRIPT NAME: 02_define_trial_populations.R
# PROJECT:     TB PACTS
# AUTHOR:      Brian Aldana
# CREATED:     30-Dec-2025, 
# =============================================================================
#
# DESCRIPTION: Creates trial populations for TB PACTS dataset
#              This one works for the SimpliTB dataset, but
#              can be generalized to other datasets in CDISC format
#
# INPUTS:   ds_SimpliciTB.rds, filtered disposition dataset for SimpliciTB
#           da_SimplitiTB.rds, filtered drug adherence dataset for SimpliciTB
#           ex_SimplitiTB.rds, filtered drug dispensing dataset for SimpliciTB
#           
#       
# OUTPUTS: trial_populations, a dataframe defining the different
#                             trial populations. 
#
#
# NOTES: Depending on what is available may change what populations you are 
#        able to define. You may also define your own trial populations
#        for sub analyses using this script as a backbone.
#
# =============================================================================

# Setup
#Cleaning Environment and memory
#rm(list=ls())
#gc()

#Loading Packages
#packages <- c("here","tidyverse","assertthat", 'janitor', 'stringr', 'magrittr')

# Loads all the packages
#lapply(packages, library, character.only = TRUE)

#rm(packages)

# Step 0: Loading Datasets
disposition_df <- read_rds(here('data', 'SimpliciTB', 'ds_SimpliciTB.rds'))
adherence_df <- read_rds(here('data', 'SimpliciTB', 'da_SimpliciTB.rds'))
ex_df <- read_rds(here('data', 'SimpliciTB', 'ex_SimpliciTB.rds'))


# -----------------------------------------------------------------------------
# Define Randomized, ITT, and Safety populations from DS
# -----------------------------------------------------------------------------
# this may change depending on study definition
#for this example, I've kept it simple in that 
#everybody who enters treatment is considered part of the rand, itt, and safety populations
populations_ds <- disposition_df |>
  clean_names() |>
  filter(domain == "DS",
         epoch == "TREATMENT",
         !is.na(dsstdy),
         dsstdy >= 1) |>
  group_by(usubjid) |>
  summarise(randomized = TRUE,
            itt        = TRUE,   # ITT, intent to treat.
            safety     = TRUE,   # proxy via treatment epoch presence for now
            first_dsstdy = min(dsstdy),
            last_dsstdy  = max(dsstdy),
            .groups = "drop")

# -----------------------------------------------------------------------------
# Define interim PP flag from DA (visit-level % compliance)
# -----------------------------------------------------------------------------
populations_da <- adherence_df |>
  clean_names() |>
  filter(domain == "DA",
         dacat == "STUDY MEDICATION",
         datestcd == "COMPL",
         !is.na(dastresn)) |>
  mutate(dastresn = pmin(dastresn, 100)) |>
  group_by(usubjid) |>
  summarise(mean_compl_pct = mean(dastresn),
            min_compl_pct  = min(dastresn),
            n_compl_visits = n(),
            pp_adherent    = mean_compl_pct >= 80,
            .groups = "drop")

# -----------------------------------------------------------------------------
# Define exposure summary from EX (treatment exposure proxy)
# -----------------------------------------------------------------------------
populations_ex <- ex_df |>
  clean_names() |>
  filter(domain == "EX",
         epoch == "TREATMENT",
         !is.na(exstdy),
         !is.na(exendy),
         !is.na(exdose)) |>
  group_by(usubjid) |>
  summarise(first_exstdy = min(exstdy),
            last_exendy  = max(exendy),
            n_ex_records = n(),
            n_dispensing = sum(exact == "SCHEDULED DISPENSING", na.rm = TRUE),
            .groups = "drop")

# -----------------------------------------------------------------------------
# Define final trial populations
# -----------------------------------------------------------------------------
# Per-protocol (PP) population is defined conservatively for demonstration:
# subjects must have entered treatment (safety population) and must not show
# evidence of clear non-adherence. Evidence of non-adherence is defined as any
# observed compliance assessment <50%. Subjects with missing compliance data
# are retained in PP, for demonstration purposes.
#
# This definition is intended for illustration purposes
# the SAP will define the PP population for the trial, but 
# you may wish to define it differently for your analyses.

trial_populations <- populations_ds |>
  left_join(populations_ex, by = "usubjid") |>
  left_join(populations_da, by = "usubjid") |>
  transmute(subject_id       = usubjid,
            randomized_flag = randomized,
            itt_flag        = itt,
            safety_flag     = safety,
            pp_flag         = safety &
                              (is.na(min_compl_pct) | min_compl_pct >= 50))