######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

######################################

from ehrql import (create_dataset, codelist_from_csv)
from ehrql.tables.tpp import patients, practice_registrations, addresses
from codelists import *

##Q for Will/Rose - ehrql.tables.tpp vs core(?)

dataset = create_dataset()

amoxicillin_codes = codelist_from_csv(
    "codelists/opensafely-amoxicillin-oral.csv", column = "code"
                                      )
cefalexin_codes = codelist_from_csv(
"codelists/opensafely-cefalexin-oral.csv", column = "code"
)

#Q for Will/Rose. Here specifying column - is this what we will use to check if they have been prescribed it?

index_date = "2024-03-31"

has_registration = practice_registrations.for_patient_on(
    index_date
).exists_for_patient()

dataset.define_population((has_registration) & (patients.date_of_birth.year == 1950))
dataset.configure_dummy_data(population_size=100)

dataset.sex = patients.sex
dataset.age = patients.age_on(index_date)
dataset.date_of_birth = patients.date_of_birth #Likely to need to calculate age at time of prescription later on
dataset.imd = addresses.for_patient_on(index_date).imd_rounded
patient_address = addresses.for_patient_on(index_date)
dataset.imd_decile = patient_address.imd_decile