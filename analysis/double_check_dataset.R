df <- readr::read_csv("output/dataset.csv.gz")

table <- df %>%
summarise(
    coamox_exp_n = sum(coamox_exp == "TRUE"),
    fq_exp_n = sum(fluoroquinolone_exp == "TRUE"),
    both_exp_shouldbe0 = sum((coamox_exp == "TRUE") & (fluoroquinolone_exp == "TRUE"))
)

