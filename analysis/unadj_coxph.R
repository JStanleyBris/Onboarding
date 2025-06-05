library(tidyverse)
library(readr)
library(survival)
library(dplyr)
library(lubridate)

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

df <- df %>%
mutate(
# Calculate 30-day censoring date
    censor_30d = date_cohort_prescription + days(30),
# Compute the censoring date: the earliest of event, death, or 30-day censor
    censor_date = pmin(first_tendinitis_diagnosis_date, date_of_death, censor_30d, na.rm = TRUE),
      # Create event indicator: 1 if event occurred on or before censoring, 0 otherwise
    event = if_else(
      !is.na(first_tendinitis_diagnosis_date) & first_tendinitis_diagnosis_date <= censor_date,
      1, 0
    ),
    # Time from entry to censoring (in days)
    time = as.numeric(difftime(censor_date, date_cohort_prescription, units = "days"))
)

summary(df$time)
table(df$event, useNA = "ifany")

cox_model <- coxph(Surv(time, event) ~ fluoroquinolone_exp, data = df)
summary(cox_model)