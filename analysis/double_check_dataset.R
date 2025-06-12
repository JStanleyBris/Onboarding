library(readr)
library(tidyverse)

df <- readr::read_csv("output/dataset_formatted_cohort.csv")

#Overall count
overall_summary <- df %>%
group_by(fluoroquinolone_exp) %>%
summarise(count = n()) %>%
  pivot_wider(
    names_from = fluoroquinolone_exp,
    values_from = count) %>%
    rename(
        `Fluoroquinolone exposed` = "TRUE",
        `Amoxicillin-clavulanic acid exposed` = "FALSE"
    ) %>%
    mutate(variable = "Overall") %>%
    select(c(variable, `Fluoroquinolone exposed`, `Amoxicillin-clavulanic acid exposed`))

# List of binary variables to summarize
categorical_vars <- df %>% 
  select(starts_with("has_"), #All comorbidities start _has
    any_of(c("corticosteroid_60d_before_abx", "drug_linked_to_neuropathy_60d_before_abx", "harmful_alcohol"))
   ) %>% 
  names() 

# Function to summarize one variable at a time
summarise_categorical <- function(var) {
  df %>%
    group_by(fluoroquinolone_exp, value = .data[[var]]) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(fluoroquinolone_exp) %>%
    mutate(percent = round(count / sum(count) * 100, 2)) %>%
    mutate(variable = var) %>%
    rename(level = value) %>%
    select(variable, level, fluoroquinolone_exp, count, percent)
}

# Apply across all categorical variables and combine
summary_table <- map_dfr(categorical_vars, summarise_categorical) %>%
  pivot_wider(
    names_from = fluoroquinolone_exp,
    values_from = c(count, percent),
    names_glue = "{.value}_FQ_{fluoroquinolone_exp}"
  ) %>%
  filter(level == "TRUE") %>%
  mutate(`Fluoroquinolone exposed` = paste0(count_FQ_TRUE, "(", percent_FQ_TRUE, "%)"),
  `Amoxicillin-clavulanic acid exposed` = paste0(count_FQ_FALSE, "(", percent_FQ_FALSE, "%)")) %>%
  select(c(variable, `Fluoroquinolone exposed`, `Amoxicillin-clavulanic acid exposed`))


# List of continuous variables to summarize
continuous_vars <- c("age", "last_bmi", "imd_decile", "n_hosp_appt_6m")

# Function to summarise one continuous variable at a time
summarise_continuous <- function(var) {
  df %>%
    group_by(fluoroquinolone_exp) %>%
    summarise(
      median = median(.data[[var]], na.rm = TRUE),
      lq = quantile(.data[[var]], probs = 0.25, na.rm = TRUE),
      uq = quantile(.data[[var]], probs = 0.75, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      variable = var,
      exposure_group = case_when(
        fluoroquinolone_exp == TRUE  ~ "Fluoroquinolone exposed",
        fluoroquinolone_exp == FALSE ~ "Amoxicillin-clavulanic acid exposed"
      )
    ) %>%
    select(variable, exposure_group, median, lq, uq)
}

# Apply function to each variable
continuous_summary_long <- map_dfr(continuous_vars, summarise_continuous)

# Pivot wider so each exposure group is in its own column
continuous_summary_wide <- continuous_summary_long %>%
  pivot_wider(
    names_from = exposure_group,
    values_from = c(median, lq, uq),
    names_glue = "{exposure_group}_{.value}"
  ) %>%
  mutate(`Fluoroquinolone exposed` = paste0(`Fluoroquinolone exposed_median`, "(", `Fluoroquinolone exposed_lq`, "-", `Fluoroquinolone exposed_uq`, ")"),
`Amoxicillin-clavulanic acid exposed` = paste0(`Amoxicillin-clavulanic acid exposed_median`, "(", `Amoxicillin-clavulanic acid exposed_lq`, "-", `Amoxicillin-clavulanic acid exposed_uq`, ")")
) %>%
  select(c(variable, `Fluoroquinolone exposed`, `Amoxicillin-clavulanic acid exposed`))


#Now look at multilevel categorical vars 
df$latest_ethnicity_group <- as.character(df$latest_ethnicity_group)

multi_categorical_vars <- c("sex", "latest_ethnicity_group")  # add more if needed

summarise_multilevel_categorical <- function(var) {
  df %>%
    group_by(fluoroquinolone_exp, level = .data[[var]]) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(fluoroquinolone_exp) %>%
    mutate(percent = round(100 * count / sum(count), 1)) %>%
    ungroup() %>%
    pivot_wider(
      names_from = fluoroquinolone_exp,
      values_from = c(count, percent),
      names_glue = "{.value}_FQ_{fluoroquinolone_exp}"
    ) %>%
    mutate(
      variable = var,
      `Fluoroquinolone exposed` = paste0(count_FQ_TRUE, " (", percent_FQ_TRUE, "%)"),
      `Amoxicillin-clavulanic acid exposed` = paste0(count_FQ_FALSE, " (", percent_FQ_FALSE, "%)")
    ) %>%
    select(variable, level, `Fluoroquinolone exposed`, `Amoxicillin-clavulanic acid exposed`)
}

combined_summary_multilevelcat <- (map_dfr(multi_categorical_vars, summarise_multilevel_categorical)) %>%
mutate(variable = paste0(variable, level)) %>%
select(-c(level))

#Save output - separately for now then remove once happy
summary_table %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/summary_table_categoricals.md")

continuous_summary_wide %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/summary_table_continuous.md")

overall_summary %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/total_table.md")

combined_summary_multilevelcat %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/multilevelcat_table.md")

rbind(overall_summary, continuous_summary_wide, combined_summary_multilevelcat, summary_table) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/overall_table1.md")