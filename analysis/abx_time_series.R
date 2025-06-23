library('tidyverse')
library(lubridate)

abx_list<-c( "Fluoroquinolones", "Amoxicillin","Amoxicillin + clavulanic acid",  "Cefalexin","Trimethoprim", "Trimethoprim + sulfamethoxazole")
outcome_list <- c("Tendinitis", "Neuropathy")
outcome_post_abx_list <- c("Tendinitis after Fluoroquinolone Prescription", "Tendinitis after Comparator Prescription", "Neuropathy after Fluoroquinolone Prescription", 
"Neuropathy after Comparator Prescription")

df_input <- read_csv(
    here::here("output", "measures.csv"),
    col_types = cols(
    measure = col_character(), 
    interval_start = col_date(format = "%Y-%m-%d"), 
    interval_end = col_date(format = "%Y-%m-%d"),
    ratio = col_double(),
    numerator = col_integer(),
    denominator = col_integer()
    )
)

df_quarter <- df_input %>% #Generate quarter for easier plotting
    mutate(quarter_start = floor_date(interval_start, "quarter")) %>%
    group_by(measure, quarter_start) %>%
    summarize(
        ratio_mean = mean(ratio, na.rm = TRUE),
        numerator_mean = mean(numerator, na.rm = TRUE),
        denominator_mean = mean(denominator, na.rm = TRUE)
) %>%
ungroup() %>% 
mutate(measure = recode(measure,
"fluoroquinolone_trends" = "Fluoroquinolones",
"amoxicillin_trends" = "Amoxicillin",
"coamox_trends" = "Amoxicillin + clavulanic acid", 
"cefalexin_trends" = "Cefalexin", 
"trim_trends" = "Trimethoprim", 
"co_trim_trends" = "Trimethoprim + sulfamethoxazole",
"tendinitis_trends" = "Tendinitis", 
"neuropathy_trends" = "Neuropathy",
"tendinitis_prev_fluoroquinolone_trends" = "Tendinitis after Fluoroquinolone Prescription", 
"tendinitis_prev_comparator_trends" = "Tendinitis after Comparator Prescription", 
"neuropathy_prev_fluoroquinolone_trends" = "Neuropathy after Fluoroquinolone Prescription", 
"neuropathy_prev_comparator_trends"  = "Neuropathy after Comparator Prescription"
)) %>%
mutate(ratio_mean_1000 = ratio_mean*1000) #for use with prescribing/1000 patients

#Plot of abx over time - want this /1000 patients(?)

plot_abx_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% abx_list) #restrict to abx only
), aes(x = quarter_start, y = ratio_mean_1000)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter", 
y = "Prescriptions per quarter per 1000 registered patients",
title = "Quarterly Prescribing Trends Over Time")

#Plot of outcomes over time

plot_outcome_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% outcome_list)  #restrict to outcomes only
), aes(x = quarter_start, y = ratio_mean_1000)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter",
y = "New diagnoses per 1000 registered patients",
title = "Quarterly Tendinitis and Neuropathy Trends Over Time")

#Plot of outcomes post abx rx

plot_outcome_postabx_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% outcome_post_abx_list)  #restrict to outcomes post abx only
), aes(x = quarter_start, y = ratio_mean_1000)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter",
y = "New diagnoses per 1000 prescriptions",
title = "Quarterly Tendinitis and Neuropathy in the 30 days after Antibiotic Prescription")

ggsave(
    plot = plot_abx_quarter,
filename = "abx_quarter_time_plot.png",
path = ("output/time_plot")
)

ggsave(
    plot = plot_outcome_quarter,
filename = "outcome_quarter_time_plot.png",
path = ("output/time_plot")
)

ggsave(
    plot = plot_outcome_postabx_quarter,
filename = "outcome_postabx_quarter.png",
path = ("output/time_plot")
)