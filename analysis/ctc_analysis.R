library(readr)
library(tidyverse)
library(dplyr)
library(tidyr)
library(stringr)

df <- readr::read_csv("output/ctc_data.csv.gz")

#Get some rough numbers - is it ok that there are lots with both diagnosis?
summary <- df %>%
  summarise(
    total = n(),
    n_neuropathy = sum(!is.na(incident_neuropathy)),
    n_tendinitis = sum(!is.na(incident_tendinitis)),
    n_either = sum(!is.na(incident_neuropathy) | !is.na(incident_tendinitis)),
    n_both = sum(!is.na(incident_neuropathy) & !is.na(incident_tendinitis))
  ) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/ctc_overall_summary.md")

#Now look at groupings risk:ref neuropathy

df %>%
  mutate(indiv_id = row_number()) %>%
  # Select all risk/reference cols for neuropathy or tendinitis
  select(indiv_id, contains("risk_neuropathy") | contains("reference_neuropathy") |
                    contains("risk_tendinitis") | contains("reference_tendinitis")) %>%
  pivot_longer(-indiv_id, names_to = "column", values_to = "value") %>%
  mutate(
    period = case_when(
      str_detect(column, "risk") ~ "risk",
      str_detect(column, "reference") ~ "reference"
    ),
    outcome = case_when(
      str_detect(column, "neuropathy") ~ "neuropathy",
      str_detect(column, "tendinitis") ~ "tendinitis"
    ),
    antibiotic = column %>%
      str_remove("_risk_neuropathy") %>%
      str_remove("_reference_neuropathy") %>%
      str_remove("_risk_tendinitis") %>%
      str_remove("_reference_tendinitis")
  ) %>%
  group_by(indiv_id, antibiotic, period, outcome) %>%
  summarise(value = any(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = period, values_from = value, values_fill = FALSE) %>%
  group_by(antibiotic, outcome) %>%
  summarise(
    n_risk_only = sum(risk & !reference),
    n_reference_only = sum(!risk & reference),
    n_both = sum(risk & reference),
    .groups = "drop"
  ) %>%
  arrange(outcome, antibiotic) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/ctc_abx_risk_ref_summary.md")

  #Need to think Monday about what we will do with those with multiple antibiotics in the risk period and reference period

