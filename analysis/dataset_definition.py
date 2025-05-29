######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

#Jack Stanley

#opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py

######################################

#COuld this be one dataset and then another one for CTC?

from ehrql import create_dataset, codelist_from_csv, months, weeks, days, show
from ehrql.tables.tpp import patients, medications, practice_registrations, addresses, clinical_events, apcs
from codelists import *

#show(dataset) - how do I get show to work?

dataset = create_dataset()

start_date = "2010-12-01" ##TBC
end_date = "2024-08-01"  ##TBC

#Exposure codes

amoxicillin_codes = codelist_from_csv("codelists/opensafely-amoxicillin-oral.csv", column = "code")
amox_clavulanicacid_codes = codelist_from_csv("codelists/opensafely-co-amoxiclav-oral.csv", column = "code")
cefalexin_codes = codelist_from_csv("codelists/opensafely-cefalexin-oral.csv", column = "code")
trimethoprim_codes = codelist_from_csv("codelists/opensafely-trimethoprim.csv", column = "code")
trim_sulfa_codes = codelist_from_csv("codelists/user-jacklsbrist-trimethoprimsulfamethoxazole-dmd.csv", column = "code")

fluoroquinolone_codes = codelist_from_csv("codelists/user-jacklsbrist-fluoroquinolones-dmd.csv", column = "code")

all_abx_codes = amoxicillin_codes + amox_clavulanicacid_codes + cefalexin_codes + trimethoprim_codes + trim_sulfa_codes +fluoroquinolone_codes

cohort_abx_codes = amox_clavulanicacid_codes + fluoroquinolone_codes

#Outcome codes

tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")
neuropathy_newdx_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")

#Covariate/demographic codes

ethnicity_codelist = codelist_from_csv("codelists/opensafely-ethnicity-snomed-0removed.csv", column="snomedcode", category_column = "Grouping_16")
smoking_clear_codelist = codelist_from_csv("codelists/opensafely-smoking-clear.csv", column = "CTV3Code", category_column = "Category")
smoking_unclear_codelist = codelist_from_csv("codelists/opensafely-smoking-unclear.csv", column = "CTV3Code", category_column = "Category")

#both_smoking_codes = smoking_clear_codelist + smoking_unclear_codelist - why does this not work? Combining elsewhere works

#COmorbidity codes

diabetes_codelist = codelist_from_csv("codelists/opensafely-diabetes.csv", column = "CTV3ID")
dementia_codelist = codelist_from_csv("codelists/opensafely-dementia.csv", column = "CTV3ID")

comorbidity_codelists_ctv3 = {
    "diabetes":diabetes_codelist,
    "dementia":dementia_codelist
}

has_any_studyabx_prescription = medications.where(
        medications.dmd_code.is_in(all_abx_codes)
).where(
        medications.date.is_on_or_between(start_date, end_date)
)


index_date = has_any_studyabx_prescription.sort_by(medications.date).first_for_patient().date #First prescription date - will need to alter this depending 
#upon analysis approach - need to ensure this is extracting patient specific

first_cohort_abx_rx = medications.where(
    medications.dmd_code.is_in(cohort_abx_codes)).where( #Set this to be the first date of receipt of any study antibiotic
        medications.date.is_on_or_after(start_date)
).sort_by(
        medications.date
).first_for_patient().date


has_registration = practice_registrations.for_patient_on(
    index_date
).exists_for_patient()

#Exclusion criteria

prior_tendinitis = clinical_events.where(
        clinical_events.snomedct_code.is_in(tendinitis_codes) #Exclude those with pre-existing diagnosis of tendinitis
).where(
        clinical_events.date.is_on_or_before(start_date)
).exists_for_patient()

dataset.define_population(
     (patients.exists_for_patient()) &
    (has_any_studyabx_prescription.exists_for_patient()) & #Only patients with at least one study antibiotic prescription
    ~(prior_tendinitis)
    )


dataset.configure_dummy_data(population_size=10)

        #Demographics
dataset.sex = patients.sex
dataset.age = patients.age_on(index_date)
dataset.date_of_birth = patients.date_of_birth #Likely to need to calculate age at time of prescription later on
dataset.imd = addresses.for_patient_on(index_date).imd_rounded
patient_address = addresses.for_patient_on(index_date)
dataset.imd_decile = patient_address.imd_decile
#BMI - is it possible to get the numeric value for bmi? https://www.opencodelists.org/codelist/primis-covid19-vacc-uptake/bmi/v2.5/#full-list
#Smoking - ctv3 or snomedct? Do I need to use both? Or just one? - https://www.opencodelists.org/codelist/opensafely/smoking-clear/2020-04-29/#full-list
#Alcohol - possible to just get number of units or categorise into none, within normal limits, heavy, v heavy or similar - https://www.opencodelists.org/codelist/nhsd-primary-care-domain-refsets/alc_cod/20241205/#full-list
dataset.latest_ethnicity_code =(
    clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist))
    .where(clinical_events.date.is_on_or_before(end_date))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)
dataset.latest_ethnicity_group = dataset.latest_ethnicity_code.to_category(
    ethnicity_codelist
)

smoking_events = (
    clinical_events.where(clinical_events.ctv3_code.is_in(smoking_clear_codelist)) #Need to update when I can combine with smoking_unclear
.where(clinical_events.date.is_on_or_before(first_cohort_abx_rx)
           ).sort_by(clinical_events.date)
)
dataset.latest_smoking_code = smoking_events.last_for_patient().ctv3_code
dataset.latest_smoking_status = dataset.latest_smoking_code.to_category(smoking_clear_codelist)
dataset.ever_smoker_or_ex = smoking_events.where(
    clinical_events.ctv3_code.to_category(smoking_clear_codelist).is_in(["S", "E"])
).exists_for_patient()


#dataset.derived_smoking_status = (dataset.__dict__latest_smoking_status.where("S", then="S")
 #       .where("E", then="E")
  #      .where("N", then=dataset.ever_smoker_or_ex.where(True, then="E").otherwise("N"))
   #     .otherwise("UNKNOWN")
    #)


        #Frailty indicators


#n hosp appt last 6 months - these will need to be dynamically set based on when the individual is entered into the study.
#Cohort this = date of first prescription of either FQ or comparator. SCCS this is date of first tendinitis/peripheral neuropathy
dataset.n_hosp_appt_6m = apcs.where(apcs.admission_date.is_on_or_between(
    (first_cohort_abx_rx - months(6)), (first_cohort_abx_rx - days(1)) 
)).count_for_patient()
#n GP appt last 6 months 
        #Nb to d/w Will/Rose as per here - https://docs.opensafely.org/ehrql/reference/schemas/tpp/#appointments

        #Comorbidities
#?need codelists - ctv3. Or snomed. Or both?
#TO put start date as date of rx for cohort (and event for CTC). Loop over these - need to do separately depending on whether using ctv3 or other

for condition, codelist in comorbidity_codelists_ctv3.items():
    setattr(
        dataset,
        f"has_{condition}",
        clinical_events.where(
            clinical_events.ctv3_code.is_in(codelist)
        ).where(
            clinical_events.date.is_before(first_cohort_abx_rx)
        ).exists_for_patient()
    )




        #Indication for antibiotic treatment

        #Time
##Year exposure (cohort) or event (SCCS) - should be able to extract in R


        #Specific covariates -

#Corticosteroid last 60d
#Nitrofurantoin, phenytoin, metronidazole, amiodarone last 90d


#Medication options

#This extracts first date of FQ prescription
dataset.first_fluoroquinolone_date = medications.where(
        medications.dmd_code.is_in(fluoroquinolone_codes)
).where(
        medications.date.is_on_or_after(start_date)
).sort_by(
        medications.date
).first_for_patient().date

dataset.first_co_amox_date = medications.where(
        medications.dmd_code.is_in(amox_clavulanicacid_codes)
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

dataset.first_neuropathy_diagnosis_date = clinical_events.where(
        clinical_events.snomedct_code.is_in(neuropathy_newdx_codes)
).where(
        clinical_events.date.is_on_or_after(start_date)
).sort_by(
        clinical_events.date
).first_for_patient().date
