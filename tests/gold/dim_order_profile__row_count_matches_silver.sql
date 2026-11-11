-- Returns a row (= fails) if dim_order_profile does not have exactly one row per silver order
-- profile, plus the 2 default rows (-1 Missing, -2 Not Applicable) added by upsert_default_rows.
select
    silver_profiles.n as silver_rows,
    dim_rows.n as dim_rows
from (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__order_profile') }}) as silver_profiles
cross join (select count(*) as n from {{ ref('gld_dim_order_profile') }}) as dim_rows
where dim_rows.n != silver_profiles.n + 2
