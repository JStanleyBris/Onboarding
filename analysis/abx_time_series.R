library('tidyverse')

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

plot_abx <- ggplot(data = df_input, aes(x = interval_start, y = ratio)) +
geom_point() +
geom_line()


ggsave(
    plot = plot_abx,
filename = "fq_time_plot.png",
path = here::here("output")
)