library('tidyverse')
library(lubridate)

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

plot_abx <- ggplot(data = df_input, aes(x = interval_start, y = ratio)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal()

plot_abx_quarter <- ggplot(data = df_quarter, aes(x = quarter_start, y = ratio_mean)) +
geom_point() +
geom_line() + 
facet_wrap(~ measure, scales = "free_y") + 
theme_minimal() +
labs(x = "Quarter")


ggsave(
    plot = plot_abx,
filename = "fq_time_plot.png",
path = here::here("output")
)

ggsave(
    plot = plot_abx_quarter,
filename = "abx_quarter_time_plot.png",
path = here::here("output")
)