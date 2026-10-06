-- The declared grain: one rate per business date and currency pair.
--
-- Written as a singular test instead of dbt_utils.unique_combination_of_columns so the
-- silver layer does not need a package installed to have a grain test (backlog B-03 is
-- still open). Verified 2026-09-28: 13,532 distinct triples in 13,532 rows, 0 failures.

select
      currency_rate_date
    , from_currency_code
    , to_currency_code
    , count(*) as n_rows
from {{ ref('slv_adventure_works_sales__currency_rate') }}
group by 1, 2, 3
having count(*) > 1
