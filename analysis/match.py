from osmatching import match
from osmatching.utils import load_dataframe

match(
    case_df=load_dataframe("output/ctc_data.csv.gz"),
    match_df=load_dataframe("output/ctc_data_controls.csv.gz"),
    matches_per_case=3,
    match_variables={
        "sex": "category",
        "age": 5,
    },
    index_date_variable="potential_case_date",
)