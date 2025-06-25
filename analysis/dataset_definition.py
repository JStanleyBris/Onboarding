######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

#Jack Stanley

#opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py

######################################

#COuld this be one dataset and then another one for CTC?

from ehrql import create_dataset, codelist_from_csv, years, months, weeks, days, show
from ehrql.tables.tpp import patients, medications, practice_registrations, addresses, clinical_events, apcs, ons_deaths
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

combo_outcome_codes = tendinitis_codes + neuropathy_newdx_codes

#Covariate/demographic codes

ethnicity_codelist = codelist_from_csv("codelists/opensafely-ethnicity-snomed-0removed.csv", column="snomedcode", category_column = "Grouping_16")
smoking_clear_codelist = codelist_from_csv("codelists/opensafely-smoking-clear.csv", column = "CTV3Code", category_column = "Category")
bmi_codelist = codelist_from_csv("codelists/primis-covid19-vacc-uptake-bmi.csv", column = "code")
harmful_alcohol_codelist = codelist_from_csv("codelists/opensafely-hazardous-alcohol-drinking.csv", column = "code")

#Comorbidity codes

        #ctv3
diabetes_codelist = codelist_from_csv("codelists/opensafely-diabetes.csv", column = "CTV3ID")
dementia_codelist = codelist_from_csv("codelists/opensafely-dementia-complete.csv", column = "code")
hiv_codelist = codelist_from_csv("codelists/opensafely-heart-failure.csv", column = "CTV3ID")
heart_failure_codelist = codelist_from_csv("codelists/opensafely-hiv.csv", column = "CTV3ID")
chronic_liver_disease_codelist = codelist_from_csv("codelists/opensafely-chronic-liver-disease.csv", column = "CTV3ID")
multiple_sclerosis_codelist = codelist_from_csv("codelists/opensafely-multiple-sclerosis.csv", column = "CTV3ID")
rheumatoid_arthritis_codelist = codelist_from_csv("codelists/opensafely-rheumatoid-arthritis.csv", column = "CTV3ID")
solid_organ_transplant_codelist = codelist_from_csv("codelists/opensafely-solid-organ-transplantation.csv", column = "CTV3ID")
lung_cancer_codelist = codelist_from_csv("codelists/opensafely-lung-cancer.csv", column = "CTV3ID")
notlung_nothaem_cancer_codelist = codelist_from_csv("codelists/opensafely-cancer-excluding-lung-and-haematological.csv", column = "CTV3ID")
haem_cancer_codelist = codelist_from_csv("codelists/opensafely-haematological-cancer.csv", column = "CTV3ID")
stroke_codelist = codelist_from_csv("codelists/opensafely-incident-non-traumatic-stroke.csv", column = "CTV3ID")
tia_codelist = codelist_from_csv("codelists/opensafely-transient-ischaemic-attack.csv", column = "code")
chronic_resp_exc_asthma_codelist = codelist_from_csv("codelists/opensafely-chronic-respiratory-disease.csv", column = "CTV3ID")
asthma_codelist = codelist_from_csv("codelists/opensafely-asthma-diagnosis.csv", column = "CTV3ID")
hemiplegia_codelist = codelist_from_csv("codelists/user-jacklsbrist-hemiplegia.csv", column = "code")

all_cancer_codelist = lung_cancer_codelist + notlung_nothaem_cancer_codelist + haem_cancer_codelist
stroke_tia_codelist = stroke_codelist + tia_codelist
chronic_resp_codelist = chronic_resp_exc_asthma_codelist + asthma_codelist

        #ctv3 dictionary
comorbidity_codelists_ctv3 = {
    "had_cancer":all_cancer_codelist,
    "chronic_liver_disease":chronic_liver_disease_codelist,
    "chronic_resp_disease":chronic_resp_codelist,
    "diabetes":diabetes_codelist,
    "dementia":dementia_codelist,
    "hiv":hiv_codelist,
    "heart_failure":heart_failure_codelist,
    "hemiplegia":hemiplegia_codelist,
    "multiple_sclerosis":multiple_sclerosis_codelist,
    "rheumatoid_arthritis":rheumatoid_arthritis_codelist,
    "solid_organ_transplant":solid_organ_transplant_codelist,
    "stroke_tia":stroke_tia_codelist
}

        #snomed
coronary_hd_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-chd_cod.csv", column = "code")
hypertension_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-hyp_cod.csv", column = "code")
ckd_codelist =codelist_from_csv("codelists/primis-covid19-vacc-uptake-old-ckd15_cod.csv", column = "code")
pvd_codelist = codelist_from_csv("codelists/qcovid-has_peripheral_vascular_disease.csv", column = "code")
aaa_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-aaa_cod.csv", column = "code")
peptic_ulcer_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-peptic-ulceration-codes.csv", column = "code")

        #snomed dictionary
comorbidity_codelists_snomedct = {
    "aaa":aaa_codelist,
    "ckd":ckd_codelist,
    "coronary_hd":coronary_hd_codelist,
    "hypertension":hypertension_codelist,
    "peptic_ulcer":peptic_ulcer_codelist,
    "pvd":pvd_codelist
}

#Non-abx prescription codes
        #Need more when available

corticosteroid_codes = codelist_from_csv("codelists/qcovid-is_prescribed_oral_steroids.csv", column = "code")

phenytoin_codes = codelist_from_csv("codelists/user-jacklsbrist-phenytoin-dmd.csv", column = "code")
amiodarone_codes = codelist_from_csv("codelists/pincer-amio.csv", column = "code")
metronidazole_codes = codelist_from_csv("codelists/ukhsa-metronidazole-tinidazole-and-ornidazole-antibacterials.csv", column = "code")
nitrofurantoin_codes = codelist_from_csv("codelists/user-jacklsbrist-nitrofurantoin-dmd.csv", column = "code")

drug_causes_of_neuropathy_codes = phenytoin_codes  + amiodarone_codes + metronidazole_codes + nitrofurantoin_codes

#Allergy codes

fluoroquinolone_allergy_codes = codelist_from_csv("codelists/user-jacklsbrist-allergy-to-fluoroquinolones.csv", column = "code")
co_amox_allergy_codes = codelist_from_csv("codelists/user-jacklsbrist-allergy-to-co-amoxiclav.csv", column = "code")

cohort_abx_allergy_codes = fluoroquinolone_allergy_codes + co_amox_allergy_codes

#This is date of first prescription of study abx for cohort

first_cohort_abx_rx = medications.where(
    medications.dmd_code.is_in(cohort_abx_codes)).where( #Set this to be the first date of receipt of any study antibiotic
        medications.date.is_on_or_between(start_date, end_date)
).sort_by(
        medications.date
).first_for_patient().date


has_registration_1y_before_cohort_abx =  (
    practice_registrations.where(practice_registrations.start_date <= (first_cohort_abx_rx + years(1)))
    .except_where(practice_registrations.end_date < end_date)
    .exists_for_patient()
)

#Exclusion criteria

prior_tendinitis_or_neuropathy = clinical_events.where(
        clinical_events.snomedct_code.is_in(combo_outcome_codes) #Exclude those with pre-existing diagnosis of tendinitis
).where(
        clinical_events.date.is_on_or_before(first_cohort_abx_rx)
).exists_for_patient()

cohort_abx_allergy = clinical_events.where(
    clinical_events.snomedct_code.is_in(cohort_abx_allergy_codes)
).where(
    clinical_events.date.is_on_or_before(first_cohort_abx_rx) #Exclude allergies coded prior to receipt of drug
).exists_for_patient()

#Cohort definition

dataset.define_population(
     (patients.exists_for_patient()) &
     (has_registration_1y_before_cohort_abx) &
    ~(cohort_abx_allergy) &
    ~(prior_tendinitis_or_neuropathy) 
    )


dataset.configure_dummy_data(population_size=1000)

        #Medication options

#This extracts first date of FQ prescription
first_fluoroquinolone_date = medications.where(
        medications.dmd_code.is_in(fluoroquinolone_codes)
).where(
        medications.date.is_on_or_after(first_cohort_abx_rx)
).sort_by(
        medications.date
).first_for_patient().date

first_co_amox_date = medications.where(
        medications.dmd_code.is_in(amox_clavulanicacid_codes)
).where(
        medications.date.is_on_or_after(first_cohort_abx_rx)
).sort_by(
        medications.date
).first_for_patient().date

dataset.first_fluoroquinolone_date = first_fluoroquinolone_date
dataset.first_co_amox_date = first_co_amox_date

        #Exposed or not - all 0s therefore should be coamox. But for sanity to check by coding coamox and comparing once generated

dataset.fluoroquinolone_exp = (
    first_fluoroquinolone_date.is_not_null()
)

dataset.coamox_exp = (
    first_co_amox_date.is_not_null()
)

#Outcome options - ICD-10 or SNOMED - any benefit to either cf the other? - Leave coded as start_date for now to check for santiy. 
# We should not be getting any coming up before the date of prescription of either

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


        #Demographics
dataset.sex = patients.sex
dataset.age = patients.age_on(first_cohort_abx_rx)
dataset.date_of_birth = patients.date_of_birth #Likely to need to calculate age at time of prescription later on
dataset.imd = addresses.for_patient_on(first_cohort_abx_rx).imd_rounded
patient_address = addresses.for_patient_on(first_cohort_abx_rx)
dataset.imd_decile = patient_address.imd_decile
dataset.date_of_death = ons_deaths.date
#BMI - is this best way to get bmi
dataset.last_bmi = (
    clinical_events.where(
        clinical_events.snomedct_code.is_in(bmi_codelist))
        .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx)) #filter to be before date of prescribing
        .sort_by(clinical_events.date)
        .last_for_patient()
        .numeric_value
)

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

#Smoking - ctv3 or snomedct? Do I need to use both? Or just one?
#This works but could be improved with a boolean string for never smokers. Q for Will/Rose. Is it possible here to dynamically assign smoking status to N/E/S based on boolean logic and dates?
# Or do I need to set three columns for never, ex, smoker all T/f
dataset.latest_smoking_code =(
    clinical_events.where(clinical_events.ctv3_code.is_in(smoking_clear_codelist))
    .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .ctv3_code
)
dataset.latest_smoking_group = dataset.latest_smoking_code.to_category(
    smoking_clear_codelist #Here i would like to say - if this code = N then look at all patient events in smoking clear and check if there is an E or S
)

dataset.never_smoker = ( 
    clinical_events.where(clinical_events.ctv3_code.is_in(smoking_clear_codelist))
    .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx))
    .where(
        (clinical_events.ctv3_code.to_category(smoking_clear_codelist) == "N") & 
        (~clinical_events.ctv3_code.to_category(smoking_clear_codelist).is_in(["E","S"]))
)
.exists_for_patient() #So here we want 'N' only if they have never had a smoking status entered in error
)

last_ex_smoke_date =(
    clinical_events.where(clinical_events.ctv3_code.is_in(smoking_clear_codelist))
    .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx))
    .where(
        (clinical_events.ctv3_code.to_category(smoking_clear_codelist) == "E")
    )
    .date
)

last_smoke_date =(
    clinical_events.where(clinical_events.ctv3_code.is_in(smoking_clear_codelist))
    .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx))
    .where(
        (clinical_events.ctv3_code.to_category(smoking_clear_codelist) == "S")
    )
    .date
)

dataset.harmful_alcohol =(
    clinical_events.where(clinical_events.ctv3_code.is_in(harmful_alcohol_codelist))
    .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx))
    .exists_for_patient()
) #Think this is best option - just find those with ever harmful alcohol use


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

for condition, codelist in comorbidity_codelists_snomedct.items():
    setattr(
        dataset,
        f"has_{condition}",
        clinical_events.where(
            clinical_events.snomedct_code.is_in(codelist)
        ).where(
            clinical_events.date.is_before(first_cohort_abx_rx)
        ).exists_for_patient()
    )

        #Indication for antibiotic treatment

        #Time
##Year exposure (cohort) or event (SCCS)
dataset.date_cohort_prescription = first_cohort_abx_rx
dataset.year_cohort_prescription = first_cohort_abx_rx.year


        #Specific covariates -

#Corticosteroid last 60d
#Nitrofurantoin, phenytoin, metronidazole, amiodarone last 60d

dataset.corticosteroid_60d_before_abx = medications.where(
    medications.dmd_code.is_in(corticosteroid_codes)
).where(
    medications.date.is_on_or_between(
        (first_cohort_abx_rx - days(60)), 
        (first_cohort_abx_rx - days(1))
)
).exists_for_patient()

dataset.drug_linked_to_neuropathy_60d_before_abx = medications.where(
    medications.dmd_code.is_in(drug_causes_of_neuropathy_codes)
).where(
    medications.date.is_on_or_between(
        (first_cohort_abx_rx - days(60)), 
        (first_cohort_abx_rx - days(1))
)
).exists_for_patient()


