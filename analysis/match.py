from pathlib import Path
import pandas as pd

# Define DATAFRAME_READER dict as per the official utils
DATAFRAME_READER = {
    ".csv": ("read_csv", {"engine": "pyarrow"}),
    ".arrow": ("read_feather", {}),
}

def file_suffix(file_path: Path):
    return "".join(file_path.suffixes)

def load_dataframe(file_path: Path):
    suffix = file_suffix(file_path).split(".gz")[0]
    read_method, kwargs = DATAFRAME_READER[suffix]
    dataframe = getattr(pd, read_method)(file_path, **kwargs)
    dataframe.set_index("patient_id", inplace=True)
    return dataframe

# Now use load_dataframe for your files
case_df = load_dataframe(Path("output/ctc_data.csv.gz"))
control_df = load_dataframe(Path("output/ctc_data_controls.csv.gz"))

# Proceed with your matching call here
from osmatching import match


match(
   case_df=case_df,
    match_df=control_df,
    matches_per_case=3 ,
    match_variables={
        "age": 5,
    },
    index_date_variable="potential_case_date",
)