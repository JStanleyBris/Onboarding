from ehrql import INTERVAL, case, create_measures, codelist_from_csv, months, when 
from ehrql.tables.tpp import medications, patients, practice_registrations

# Every measure definitions file must include this line
measures = create_measures()

# Disable disclosure control for demonstration purposes.
# Values will neither be suppressed nor rounded.
measures.configure_disclosure_control(enabled=False)
measures.configure_dummy_data(population_size=1000)

# Codelist - do we need to redo this or can we link it to the dataset_definition?

fluoroquinolone_codes = codelist_from_csv("codelists/user-jacklsbrist-fluoroquinolones-dmd.csv", column = "code")

# The use of the special INTERVAL placeholder below is the key part of
# any measure definition as it allows the definition to be evaluated
# over a range of different intervals, rather than a fixed pair of dates
rx_in_interval = medications.where(
    medications.date.is_during(INTERVAL)
)

fluoroquinolone_rx = rx_in_interval.where(
    medications.dmd_code.is_in(fluoroquinolone_codes)
)

measures.define_measure(
    name="fluoroquinolone_trends",
    numerator= fluoroquinolone_rx.exists_for_patient(),
    denominator=patients.exists_for_patient(), #eg all patients - is it possible to make this all patients registered at that timepoint? Eg /
                                                #patients.practice_registrations.for_patient_on(INTERVAL).exists_for_patient()
    intervals=months(120).starting_on("2010-12-01"), #Q - can this be linked to start_date in dataset_definition?
    #Q2 - can we make this 3 months (or 365.25/4 days?)

)
