-- Returns a row (= fails) if gld_dim_currency_rate does not have exactly one row per silver
-- exchange rate, plus the 2 default rows (-1 Missing, -2 Not Applicable) added by
-- upsert_default_rows. A dropped rate, or a duplicate from the merge, shows up here.
select
    silver_rates.n as silver_rows,
    dim_rates.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__currency_rate') }}) as silver_rates
cross join (select count(*) as n from {{ ref('gld_dim_currency_rate') }}) as dim_rates
where dim_rates.n != silver_rates.n + 2
