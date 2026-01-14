# =============================================================================
# SCRIPT NAME: create_efficacy_measures.R
# PROJECT:     TB PACTS
# AUTHOR:      Brian Aldana
# CREATED:     14-Jan-2026
# =============================================================================
#
# DESCRIPTION:
#   Derives participant-level efficacy measures for TB PACTS:
#     • Time to Culture Conversion (TTCC)
#     • (Optional) Time to Positivity (TTP)
#
#   For this example, metrics are computed using liquid culture (MGIT) data only.
#
# INPUTS:
#   mb_df                – Liquid culture results (MGIT)
#   trial_populations    – Subject-level analysis populations
#
# OUTPUTS:
#   ttcc_results         - subject-level TTCC results
#   bs_ttcc              - time-to-event dataset with t and conv_censored
#
# NOTES:
#   For demonstration purposes only.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Stand-alone execution setup (omit when sourced via main workflow)
# -----------------------------------------------------------------------------

#rm(list = ls())
#gc()

#packages <- c("here","tidyverse","assertthat","janitor","stringr","magrittr")
#lapply(packages, library, character.only = TRUE)
#rm(packages)

#source(here::here("cleaning", "02_define_trial_populations.R"))


# -----------------------------------------------------------------------------
# Load ms (microbio specemins), which has TTP data
# -----------------------------------------------------------------------------

mb_raw <- read_rds(here::here('data', 'SimpliciTB', 'mb_SimpliciTB.rds')) #TTP and TTCC data

# -----------------------------------------------------------------------------
# Prepare MGIT MTB culture growth results (MB)
# -----------------------------------------------------------------------------
mgit_culture <- mb_raw |>
  clean_names() |>
  filter(domain == "MB",
         spdevid == "MGIT",
         mbtestcd == "MTB",
         mbtstdtl == "Culture Growth",
         mbspec == "SPUTUM",
         mbstresc %in% c("POSITIVE", "NEGATIVE"),
         !is.na(mbdy)) |>
  transmute(usubjid,
            mbdy,
            visitnum,
            visit,
            result = mbstresc)

# -----------------------------------------------------------------------------
# Prepare time-to-positvity.
# -----------------------------------------------------------------------------
mgit_ttp <- mb_raw |>
  clean_names() |>
  filter(domain == "MB",
         spdevid == "MGIT",
         mbtestcd == "MTB",
         mbtstdtl == "Time to Detection",
         !is.na(mbdy),
         !is.na(mbstresc)) |>
  mutate(ttp = as.numeric(mbstresc)) |>
  filter(!is.na(ttp)) |>
  group_by(usubjid, mbdy) |>
  summarise(ttp_mean = mean(ttp),
            .groups = "drop")


# -----------------------------------------------------------------------------
# Function for calculating the mgit results
# -----------------------------------------------------------------------------

arbitrate_ttcc <- function(df) {
  df |>
    group_by(usubjid, mbdy) |>
    summarise(final_result = case_when(
      any(result == "POSITIVE") ~ "Positive",
      all(result == "NEGATIVE") ~ "Negative",
      TRUE ~ "Unknown"
    ),
    .groups = "drop")
}

# -----------------------------------------------------------------------------
# Get final MGIT result per timepoint
# -----------------------------------------------------------------------------
ttcc_results <- arbitrate_ttcc(mgit_culture)

# -----------------------------------------------------------------------------
# Join TTP (day-level) after arbitration and apply negative coding
# -----------------------------------------------------------------------------
ttcc_results <- ttcc_results |>
  left_join(mgit_ttp, by = c("usubjid", "mbdy")) |>
  mutate(ttp = case_when(final_result == "Negative" ~ 42,
                         final_result == "Positive" ~ ttp_mean,
                         TRUE ~ NA_real_)) |>
  select(usubjid, mbdy, final_result, ttp)


# -----------------------------------------------------------------------------
# Restrict to randomized list (analysis set)
# -----------------------------------------------------------------------------
ttcc_results <- trial_populations |>
  transmute(usubjid = subject_id,
            randomized_flag) |>
  filter(randomized_flag) |>
  left_join(ttcc_results, by = "usubjid")

# -----------------------------------------------------------------------------
# Derive TTCC (first of 2 consecutive negatives)
# contaminated does not break consecutiveness (not applicable here)
# -----------------------------------------------------------------------------
bs_ttcc <- ttcc_results |>
  group_by(usubjid) |>
  arrange(usubjid, mbdy) |>
  mutate(next_result = lead(final_result),
         next_day    = lead(mbdy)) |>
  filter(final_result == "Negative" & next_result == "Negative") |>
  summarise(t = min(mbdy, na.rm = TRUE),
            conv_censored = 1L,
            .groups = "drop")

# -----------------------------------------------------------------------------
# Add censored subjects (no conversion)
# -----------------------------------------------------------------------------
bs_ttcc <- ttcc_results |>
  group_by(usubjid) |>
  summarise(last_day = max(mbdy, na.rm = TRUE),
            .groups = "drop") |>
  left_join(bs_ttcc, by = "usubjid") |>
  mutate(conv_censored = if_else(!is.na(t), conv_censored, 0L),
         t = if_else(!is.na(t), t, last_day)) |>
  select(usubjid, t, conv_censored)

#rm(arbitrate_ttcc, ms3_raw, ttp_ttcc_long, consecutive_negative, no_cens, ttcc_cens)

# -----------------------------------------------------------------------------
# Clean up intermediate objects
# -----------------------------------------------------------------------------
rm(mgit_culture, mgit_ttp)