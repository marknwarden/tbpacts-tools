# =============================================================================
# SCRIPT NAME: 01_km_ttcc.R
# PROJECT:     TB PACTS
# AUTHOR:      Brian Aldana
# CREATED:     14-Jan-2026
# =============================================================================
#
# DESCRIPTION:
#   Generates a Kaplan-Meier curve for TTCC by treatment arm.
#
# INPUTS:
#   dm_df               – Demographics (arm assignment)
#   trial_populations   – Subject-level analysis populations
#   bs_ttcc             – Time-to-event TTCC dataset
#
# OUTPUTS:
#   km_fit              - survfit object
#
# NOTES:
#   For demonstration purposes only.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Stand-alone execution setup (omit when sourced via main workflow)
# -----------------------------------------------------------------------------

rm(list = ls())
gc()

packages <- c("here","tidyverse","assertthat","janitor","stringr","magrittr","survival", 'ggplot2', "survminer")
lapply(packages, library, character.only = TRUE)
rm(packages)

# -----------------------------------------------------------------------------
# Load datasets
# -----------------------------------------------------------------------------

dm_df <- read_rds(here::here("data", "SimpliciTB", "dm_SimpliciTB.rds"))
source(here::here("cleaning", "02_define_trial_populations.R"))
source(here::here('functions', 'create_efficacy_measures.R'))

# -----------------------------------------------------------------------------
# Get arm assignment
# -----------------------------------------------------------------------------

arm_df <- dm_df |>
  clean_names() |>
  transmute(subject_id = usubjid,
            arm = arm) |>
  distinct()

# -----------------------------------------------------------------------------
# Build analysis dataset (ITT)
# -----------------------------------------------------------------------------

km_df <- bs_ttcc |>
  transmute(subject_id = usubjid,
            t,
            conv_censored) |>
  left_join(trial_populations, by = "subject_id") |>
  left_join(arm_df, by = "subject_id") |>
  filter(itt_flag)

#renaming arms for conciseness
km_df <- km_df |>
  mutate(arm = recode(arm,
                      "Drug Resistant TB: BPaMZ daily for 26 weeks (6 months)" =
                        "BPaMZ (DR, 26w)",
                      "Drug Sensitive TB: BPaMZ daily for 17 weeks (4 months)" =
                        "BPaMZ (DS, 17w)",
                      "Drug Sensitive TB: HRZE/HR combination tablets daily for 26 weeks (6 months)" =
                        "HRZE/HR (DS, 26w)"))

# -----------------------------------------------------------------------------
# KM fit + plot
# -----------------------------------------------------------------------------
km_fit <- survfit(Surv(t, conv_censored) ~ arm, data = km_df)

km_plot <- ggsurvplot(
  km_fit,
  data = km_df,
  risk.table = TRUE,
  censor = TRUE,
  break.time.by = 7,
  xlim = c(0, 112),
  xlab = "Days from Randomization",
  ylab = "Cumulative proportion without culture conversion\nin MGIT liquid media",
  legend.title = "Trial Arm",
  ggtheme = theme_bw(),
  risk.table.height = 0.25
)

km_plot
