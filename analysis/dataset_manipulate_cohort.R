library(tidyverse)
library(readr)
library(survival)
library(dplyr)
library(lubridate)

#Ensure data read in in correct format

df <- readr::read_csv("output/dataset.csv.gz", col_types = readr::cols(
    first_co_amox_date = col_date(format = "%Y-%m-%d"),
    first_fluoroquinolone_date = col_date(format = "%Y-%m-%d"),
    first_tendinitis_diagnosis_date = col_date(format = "%Y-%m-%d"),
    first_neuropathy_diagnosis_date = col_date(format = "%Y-%m-%d"),
    date_cohort_prescription = col_date(format = "%Y-%m-%d"),
    date_of_death = col_date(format = "%Y-%m-%d"),
    coamox_exp = col_logical(),
    fluoroquinolone_exp = col_logical()
    )
    )

#Need to separately make imd_decile an ordered factor
df$imd_decile <- factor(df$imd_decile,
                        levels = as.character(1:10),
                        ordered = TRUE)



df <- df %>%
mutate(
    # Exclude tendinitis diagnoses that occur before prescription
    tendinitis_post_rx = if_else(
      !is.na(first_tendinitis_diagnosis_date) & first_tendinitis_diagnosis_date >= date_cohort_prescription,
      first_tendinitis_diagnosis_date,
      as.Date(NA)
    ),
# Calculate 30-day censoring date
    censor_30d = date_cohort_prescription + days(30),
# Compute the censoring date: the earliest of event, death, or 30-day censor
    censor_date_tendinitis = pmin(tendinitis_post_rx, date_of_death, censor_30d, na.rm = TRUE),
      # Create event indicator: 1 if event occurred on or before censoring, 0 otherwise
    event_tendinitis = if_else(
      !is.na(first_tendinitis_diagnosis_date) & #Those with a tendinitis event
      first_tendinitis_diagnosis_date > date_cohort_prescription & #Those that did not occur before or on same day as prescription
      first_tendinitis_diagnosis_date <= censor_date_tendinitis, #Those where it did not occur after censorship
      1, 0
    ),
    # Time from entry to censoring (in days)
    time_tendinitis = as.numeric(difftime(censor_date_tendinitis, date_cohort_prescription, units = "days"))
)

readr::write_csv(df, here::here("output", "dataset_formatted_cohort.csv"))