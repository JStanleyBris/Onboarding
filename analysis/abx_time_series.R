library('tidyverse')
library(lubridate)

abx_list<-c("fluoroquinolone_trends","amoxicillin_trends")
outcome_list <- c("tendinitis_trends")

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
ungroup()

#Plot of abx over time

plot_abx_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% abx_list) #restrict to abx only
), aes(x = quarter_start, y = ratio_mean)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter")

#Plot of outcomes over time

plot_outcome_quarter <- ggplot(data = (df_quarter %>% 
filter(measure %in% outcome_list) #restrict to abx only
), aes(x = quarter_start, y = ratio_mean)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter")

ggsave(
    plot = plot_abx_quarter,
filename = "abx_quarter_time_plot.png",
path = here::here("output")
)

ggsave(
    plot = plot_outcome_quarter,
filename = "outcome_quarter_time_plot.png",
path = here::here("output")
)