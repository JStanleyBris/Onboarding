library(readr)
library(tidyverse)
library(dplyr)
library(tidyr)
library(stringr)
library(epitools) # for oddsratio()

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
  summarise( #Get rough numbers as an oversight
    n_risk_only = sum(risk & !reference),
    n_reference_only = sum(!risk & reference),
    n_both = sum(risk & reference),
    .groups = "drop"
  ) %>%
  arrange(outcome, antibiotic) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/ctc_abx_risk_ref_summary.md")

 
#Generate sign for those with multiple antibiotics in risk or reference period
# Step 1: Add indiv_id to track rows - this needs to be done separately to allow L join later

df <- df %>%
  mutate(indiv_id = row_number())

# Step 2: Generate outcome-specific flags for each person
 
multi_abx_flags <- df %>%
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
  group_by(indiv_id, outcome) %>%
  summarise(
    multi_abx_risk = sum(risk, na.rm = TRUE) > 1,
    multi_abx_reference = sum(reference, na.rm = TRUE) > 1,
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = outcome,
    values_from = c(multi_abx_risk, multi_abx_reference),
    names_glue = "{.value}_{outcome}"
  )

# Step 3: Join flags back to original df
df <- df %>%
  left_join(multi_abx_flags, by = "indiv_id")

# Step 4: (Optional) Count exclusions
df %>%
  summarise(
    n_exclude_risk_tend = sum(multi_abx_risk_tendinitis, na.rm = TRUE),
    n_exclude_ref_tend = sum(multi_abx_reference_tendinitis, na.rm = TRUE),
    n_exclude_risk_neur = sum(multi_abx_risk_neuropathy, na.rm = TRUE),
    n_exclude_ref_neur = sum(multi_abx_reference_neuropathy, na.rm = TRUE)
  ) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/ctc_multi_abx_exclusion_counts.md")

#Now look at generating OR

# Function to calculate OR from paired data
calc_or_sccs <- function(df, risk_col, ref_col) {
  # Create 2x2 table of discordant pairs
  tbl <- table(
    Risk_Exposed = df[[risk_col]],
    Reference_Exposed = df[[ref_col]]
  )
  
 tbl<- table(
     Risk_Exposed = df[["fluoroquinolones_risk_tendinitis"]],
     Reference_Exposed = df[["fluoroquinolones_reference_tendinitis"]]
   )


  # Check if table has all cells
  if (all(dim(tbl) == c(2,2))) {
    or_result <- oddsratio(tbl, method = "wald")
    return(data.frame(
      OR = or_result$measure[2,1],
      Lower_CI = or_result$measure[2,2],
      Upper_CI = or_result$measure[2,3]
    ))
  } else {
    return(data.frame(
      OR = NA,
      Lower_CI = NA,
      Upper_CI = NA
    ))
  }
}

#Remove those with multiple abx in risk or ref

df_analysis <- df %>%
  filter(
    !multi_abx_risk_tendinitis,
    !multi_abx_reference_tendinitis,
    !multi_abx_risk_neuropathy,
    !multi_abx_reference_neuropathy
  )

# Calculate OR for neuropathy
or_neuropathy <- calc_or_sccs(df_analysis, 
                              risk_col = "fluoroquinolones_risk_neuropathy", 
                              ref_col = "fluoroquinolones_reference_neuropathy")

# Calculate OR for tendinitis
or_tendinitis <- calc_or_sccs(df_analysis, 
                              risk_col = "fluoroquinolones_risk_tendinitis", 
                              ref_col = "fluoroquinolones_reference_tendinitis")

# Combine results
results <- bind_rows(
  neuropathy = or_neuropathy,
  tendinitis = or_tendinitis,
  .id = "Outcome"
)%>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/ctc_simple_or.md")

