######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

######################################

from ehrql import (create_dataset, codelist_from_csv)
from ehrql.tables.tpp import patients, medications, practice_registrations, addresses, clinical_events
from codelists import *

##Q for Will/Rose - ehrql.tables.tpp vs core(?)
##Q for Will and Rose - studydefinition function - https://github.com/opensafely/Shared-Care-Monitoring/blob/main/analysis/study_definition.py

dataset = create_dataset()

start_date = "2010-12-01" ##TBC
end_date = "2024-08-01"  ##TBC

##Need to ensure dmd codes in codelists that I have made

amoxicillin_codes = codelist_from_csv("codelists/opensafely-amoxicillin-oral.csv", column = "code")
amox_clavulanicacid_codes = codelist_from_csv("codelists/opensafely-co-amoxiclav-oral.csv", column = "code")
cefalexin_codes = codelist_from_csv("codelists/opensafely-cefalexin-oral.csv", column = "code")
trimethoprim_codes = codelist_from_csv("codelists/opensafely-trimethoprim.csv", column = "code")
trim_sulfa_codes = codelist_from_csv("codelists/user-jacklsbrist-trimethoprimsulfamethoxazole-dmd.csv", column = "code")

fluoroquinolone_codes = codelist_from_csv("codelists/user-jacklsbrist-fluoroquinolones-dmd.csv", column = "code")

#Outcome codes

tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")

has_any_studyabx_prescription = medications.where(
        medications.dmd_code.is_in(amoxicillin_codes)|
        medications.dmd_code.is_in(cefalexin_codes)|
        medications.dmd_code.is_in(amox_clavulanicacid_codes)|
        medications.dmd_code.is_in(trimethoprim_codes)|
        medications.dmd_code.is_in(trim_sulfa_codes)|
        medications.dmd_code.is_in(fluoroquinolone_codes)
).where(
        medications.date.is_on_or_between(start_date, end_date)
).exists_for_patient()



index_date = "2024-03-31"

has_registration = practice_registrations.for_patient_on(
    index_date
).exists_for_patient()

dataset.define_population(
     (patients.exists_for_patient()) &
    (has_any_studyabx_prescription == True))

dataset.configure_dummy_data(population_size=10)

dataset.sex = patients.sex
dataset.age = patients.age_on(index_date)
dataset.date_of_birth = patients.date_of_birth #Likely to need to calculate age at time of prescription later on
dataset.imd = addresses.for_patient_on(index_date).imd_rounded
patient_address = addresses.for_patient_on(index_date)
dataset.imd_decile = patient_address.imd_decile

#Medication options

#This extracts first date of FQ prescription
dataset.first_fluoroquinolone_date = medications.where(
        medications.dmd_code.is_in(fluoroquinolone_codes)
).where(
        medications.date.is_on_or_after(start_date)
).sort_by(
        medications.date
).first_for_patient().date

#Outcome options - ICD-10 or SNOMED - any benefit to either cf the other?

dataset.first_tendinitis_diagnosis_date = clinical_events.where(
        clinical_events.snomedct_code.is_in(tendinitis_codes)
).where(
        clinical_events.date.is_on_or_after(start_date)
).sort_by(
        clinical_events.date
).first_for_patient().date

