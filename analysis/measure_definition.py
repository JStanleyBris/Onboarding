from ehrql import INTERVAL, case, create_measures, codelist_from_csv, months, when 
from ehrql.tables.tpp import medications, patients, practice_registrations, clinical_events

measures = create_measures()

# Disable disclosure control for demonstration purposes. Values will neither be suppressed nor rounded.

measures.configure_disclosure_control(enabled=False) #change to true when running. Ok as false for now
measures.configure_dummy_data(population_size=1000)

#De novo dataset generation for measures here - but could make external file for queries that would be shared by both

#Exposures
fluoroquinolone_codes = codelist_from_csv("codelists/user-jacklsbrist-fluoroquinolones-dmd.csv", column = "code")
amoxicillin_codes = codelist_from_csv("codelists/opensafely-amoxicillin-oral.csv", column = "code")

#Outcomes
tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")

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

fluoroquinolone_rx = rx_in_interval.where(
    medications.dmd_code.is_in(fluoroquinolone_codes)
    )

amoxicillin_rx = rx_in_interval.where(
    medications.dmd_code.is_in(amoxicillin_codes)
)

#Define numerators - outcomes

tendinitis_dx = dx_in_interval.where(
    clinical_events.snomedct_code.is_in(tendinitis_codes)
)

#Define denominators

denominator_abxcount = (
    practice_registrations.spanning(INTERVAL.start_date, INTERVAL.end_date).exists_for_patient()
    )


measures.define_measure(
    name="fluoroquinolone_trends",
    numerator= fluoroquinolone_rx.count_for_patient(), #this runs and works - and only counts by patient within interval I think because of rx_in_interval
    denominator=denominator_abxcount, 
)

measures.define_measure( #Is this the best way to work with measures here - to make multiple measures
#Or would I be better off using group_by? If so would I have to make a new group
    name="amoxicillin_trends",
    numerator= amoxicillin_rx.count_for_patient(),
    denominator=denominator_abxcount,
)
measures.define_measure(
    name="tendinitis_trends",
    numerator= tendinitis_dx.exists_for_patient(), #exists better than count here - any rpt coding would be same dx
    denominator = denominator_abxcount
)