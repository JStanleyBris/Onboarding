from ehrql import INTERVAL, case, create_measures, months, when
from ehrql.tables.core import medications, patients

# Every measure definitions file must include this line
measures = create_measures()

# Disable disclosure control for demonstration purposes.
# Values will neither be suppressed nor rounded.
measures.configure_disclosure_control(enabled=False)

# Codelist

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
    denominator=patients.exists_for_patient(),
    intervals=months(3).starting_on("2018-01-01"),
)
