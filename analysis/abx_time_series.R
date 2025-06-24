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

#Set vertical lines for plotting
MHRA_1 <- as.Date("01/03/2019", format = "%d/%m/%Y")

covid_start <- as.Date("01/03/2020", format = "%d/%m/%Y")
covid_end   <- as.Date("01/04/2022", format = "%d/%m/%Y")

MHRA_2 <- as.Date("01/01/2024", format = "%d/%m/%Y")

#Make object for break marking

 os_plots_date_pointmarkers <- list(geom_rect(
    aes(xmin = covid_start, xmax = covid_end, ymin = -Inf, ymax = Inf),
    fill = "#cce5ff",  # light blue
    alpha = 0.4,
    inherit.aes = FALSE
  ),
geom_point(),
geom_line(), 
geom_vline(xintercept = MHRA_1, linetype = "dashed", color = "red"),
geom_vline(xintercept = MHRA_2, linetype = "dashed", color = "red")
 )

#Plot of abx over time - want this /1000 patients(?)

plot_abx_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% abx_list) %>% #restrict to abx only
mutate(measure = case_when(
    measure == "Amoxicillin + clavulanic acid" ~ "Amoxicillin\n+ clavulanic acid",
    measure == "Trimethoprim + sulfamethoxazole" ~ "Trimethoprim\n+ sulfamethoxazole",
    TRUE ~ measure
  ))
), aes(x = quarter_start, y = ratio_mean_1000)) +
  os_plots_date_pointmarkers + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 60, hjust = 1),
    axis.text = element_text(size = 6, color = "black"),
    strip.text = element_text(size = 10, face = "bold", color = "black"),
    strip.background = element_rect(
      fill = "white",
      color = NA
    ),
    panel.background = element_rect(fill = "white", color = NA),  # plot area
    plot.background = element_rect(fill = "white", color = NA),   # full canvas
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank()
  ) +
  scale_x_date(
    date_breaks = "6 months",         # Show a tick every 3 months
    date_labels = "%b %Y"             # Format: "Mar 2020", "Jun 2020", etc.
  ) +
labs(x = "Quarter", 
y = "Prescriptions per quarter per 1000 registered patients",
title = "Quarterly Prescribing Trends Over Time")

#Plot of outcomes over time

plot_outcome_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% outcome_list)  #restrict to outcomes only
), aes(x = quarter_start, y = ratio_mean_1000)) +
os_plots_date_pointmarkers + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter",
y = "New diagnoses per 1000 registered patients",
title = "Quarterly Tendinitis and Neuropathy Trends Over Time")

#Plot of outcomes post abx rx

plot_outcome_postabx_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% outcome_post_abx_list)  #restrict to outcomes post abx only
), aes(x = quarter_start, y = ratio_mean_1000)) +
os_plots_date_pointmarkers + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter",
y = "New diagnoses per 1000 prescriptions",
title = "Quarterly Tendinitis and Neuropathy in the 30 days after Antibiotic Prescription")

dir.create("output/time_plot", recursive = TRUE, showWarnings = FALSE)

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