from ehrql import INTERVAL, case, create_measures, codelist_from_csv, months, weeks, days, when 
from ehrql.tables.tpp import medications, patients, practice_registrations, clinical_events

measures = create_measures()

# Disable disclosure control for demonstration purposes. Values will neither be suppressed nor rounded.

measures.configure_disclosure_control(enabled=False) #change to true when running. Ok as false for now
measures.configure_dummy_data(population_size=1000)

#De novo dataset generation for measures here - but could make external file for queries that would be shared by both

#Exposures - fq
fluoroquinolone_codes = codelist_from_csv("codelists/user-jacklsbrist-fluoroquinolones-dmd.csv", column = "code")

#Exposures - comparators
amoxicillin_codes = codelist_from_csv("codelists/opensafely-amoxicillin-oral.csv", column = "code")
cefalexin_codes = codelist_from_csv("codelists/opensafely-cefalexin-oral.csv", column = "code")
co_amox_codes = codelist_from_csv("codelists/opensafely-co-amoxiclav-oral.csv", column = "code")
trim_codes = codelist_from_csv("codelists/opensafely-trimethoprim.csv", column = "code")
co_trim_codes = codelist_from_csv("codelists/user-jacklsbrist-trimethoprimsulfamethoxazole-dmd.csv", column = "code")

all_comparator_abx = amoxicillin_codes + cefalexin_codes + co_amox_codes +trim_codes + co_trim_codes

#Outcomes
tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")
neuropathy_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")

# The use of the special INTERVAL placeholder below is the key part of
# any measure definition as it allows the definition to be evaluated
# over a range of different intervals, rather than a fixed pair of dates
rx_in_interval = medications.where(
    medications.date.is_during(INTERVAL)
)

dx_in_interval = clinical_events.where(
        clinical_events.date.is_during(INTERVAL)
)

#Define durations - saves repetition
measures.define_defaults(intervals=months(120).starting_on("2010-12-01"))

    #Define numerators - abx

#FQ
fluoroquinolone_rx = rx_in_interval.where(medications.dmd_code.is_in(fluoroquinolone_codes))

#Comparators
amoxicillin_rx = rx_in_interval.where(medications.dmd_code.is_in(amoxicillin_codes))
cefalexin_rx = rx_in_interval.where(medications.dmd_code.is_in(cefalexin_codes))
co_amox_rx = rx_in_interval.where(medications.dmd_code.is_in(co_amox_codes))
trim_rx = rx_in_interval.where(medications.dmd_code.is_in(trim_codes))
co_trim_rx = rx_in_interval.where(medications.dmd_code.is_in(co_trim_codes))

    #Define numerators - outcomes

tendinitis_dx = dx_in_interval.where(clinical_events.snomedct_code.is_in(tendinitis_codes))
neuropathy_dx = dx_in_interval.where(clinical_events.snomedct_code.is_in(neuropathy_codes))

    #Challenge of looking at outcome post antibiotic prescription - first get date of outcome. Then look 30days back for prescription

#Outcome date

first_tendinitis = clinical_events.where(
    clinical_events.snomedct_code.is_in(tendinitis_codes)).where(
        clinical_events.date.is_during(INTERVAL)).sort_by(clinical_events.date).first_for_patient().date

first_neuropathy = clinical_events.where(
    clinical_events.snomedct_code.is_in(neuropathy_codes)).where(
        clinical_events.date.is_during(INTERVAL)).sort_by(clinical_events.date).first_for_patient().date


denominator_abxcount = (
    practice_registrations.spanning(INTERVAL.start_date, INTERVAL.end_date)
    )

# #Rx 30d before outcome
#Start to make more efficient

#Dictionary

# Antibiotic codelists
antibiotics = {
    "amoxicillin": amoxicillin_codes,
    "cefalexin": cefalexin_codes,
    "co_amoxiclav": co_amox_codes,
    "trimethoprim": trim_codes,
    "co_trimoxazole": co_trim_codes,
    "fluoroquinolone": fluoroquinolone_codes,
}

# Outcome codelists
outcomes = {
    "tendinitis": tendinitis_codes,
    "neuropathy": neuropathy_codes,
}

#Extract first outcome dates - as outcomes are rare this is the best way to do it

first_outcome_dates = {}

for outcome_name, outcome_codes in outcomes.items():
    first_outcome_dates[outcome_name] = clinical_events.where(
        clinical_events.snomedct_code.is_in(outcome_codes)
    ).where(
        clinical_events.date.is_during(INTERVAL)
    ).sort_by(
        clinical_events.date
    ).first_for_patient().date

#Define window in which antibiotic can be prescribed 

window_starts = {}
window_ends = {}

for outcome_name, first_date in first_outcome_dates.items():
    window_starts[outcome_name] = first_date - days(30)
    window_ends[outcome_name] = first_date - days(1)

#Look for ab prescription

rx_pre_outcome = {}

for ab_name, ab_codes in antibiotics.items():
    for outcome_name in outcomes:
        var_name = f"{ab_name}_rx_pre_{outcome_name}"
        rx_pre_outcome[var_name] = medications.where(
            medications.dmd_code.is_in(ab_codes)
        ).where(
            medications.date.is_on_or_between(
                window_starts[outcome_name], window_ends[outcome_name]
            )
        )

# Loop through each antibiotic × outcome combination
for ab_name in antibiotics:
    for outcome_name in outcomes:

        var_name = f"{ab_name}_rx_pre_{outcome_name}"  # this was already created earlier
        measure_name = f"{outcome_name}_prev_{ab_name}_trends"

        # Define denominator: all prescriptions for that antibiotic in the interval (30-day lookback from INTERVAL.start_date)
        denominator = medications.where(
            medications.dmd_code.is_in(antibiotics[ab_name])
        ).where(
            medications.date.is_on_or_between(
                INTERVAL.start_date - days(30),
                INTERVAL.start_date - days(1),
            )
        )

        # Define measure
        measures.define_measure(
            name=measure_name,
            numerator=rx_pre_outcome[var_name].exists_for_patient(),
            denominator=denominator.exists_for_patient(),
        )


#Start with measures

#SImple abx trend  - use count_for_patient to account for repeat prescribing in 30d - likely minimal
measures.define_measure(
    name="fluoroquinolone_trends",
    numerator= fluoroquinolone_rx.count_for_patient(), #this runs and works - and only counts by patient within interval I think because of rx_in_interval
    denominator=denominator_abxcount.exists_for_patient(), 
)

measures.define_measure(
    name="amoxicillin_trends",
    numerator= amoxicillin_rx.count_for_patient(),
    denominator=denominator_abxcount.exists_for_patient(),
)

measures.define_measure(
    name="cefalexin_trends",
    numerator= cefalexin_rx.count_for_patient(),
    denominator=denominator_abxcount.exists_for_patient(),
)

measures.define_measure(
    name="coamox_trends",
    numerator= co_amox_rx.count_for_patient(),
    denominator=denominator_abxcount.exists_for_patient(),
)

measures.define_measure(
    name="trim_trends",
    numerator= trim_rx.count_for_patient(),
    denominator=denominator_abxcount.exists_for_patient(),
)

measures.define_measure(
    name="co_trim_trends",
    numerator= co_trim_rx.count_for_patient(),
    denominator=denominator_abxcount.exists_for_patient(),
)

#Simple AE trend - use exist_for_patient to restrict to 1 occurence per person
measures.define_measure(
    name="tendinitis_trends",
    numerator= tendinitis_dx.exists_for_patient(), #exists better than count here - any rpt coding would be same dx
    denominator = denominator_abxcount.exists_for_patient(),
)

measures.define_measure(
    name="neuropathy_trends",
    numerator= neuropathy_dx.exists_for_patient(), 
    denominator = denominator_abxcount.exists_for_patient(),
)