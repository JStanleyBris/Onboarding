from ehrql import INTERVAL, case, create_measures, codelist_from_csv, months, when 
from ehrql.tables.tpp import medications, patients, practice_registrations

# Every measure definitions file must include this line
measures = create_measures()

# Disable disclosure control for demonstration purposes.
# Values will neither be suppressed nor rounded.
measures.configure_disclosure_control(enabled=False) #change to true when running. Ok as false for now
measures.configure_dummy_data(population_size=1000)

#De novo dataset generation for measures here - but could make external file for queries that would be shared by both

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
    numerator= fluoroquinolone_rx.exists_for_patient(), #countforpatient(?) - to consider
    denominator=practice_registrations.spanning(INTERVAL.start_date, INTERVAL.end_date).exists_for_patient(), #eg all patients - is it possible to make this all patients registered at that timepoint? Eg /
                                                #practice_registrations.for_patient_on(INTERVAL).exists_for_patient() - 
                                                #  ?practice registrations is own table
    intervals=months(120).starting_on("2010-12-01"), #Q - can this be linked to start_date in dataset_definition?
    #Q2 - can we make this 3 months (or 365.25/4 days?) - input start_date as a runtime argument and supply it the action 
    #Make the variable - in the same file as shared queries put shared variables - put this in analysis

)
