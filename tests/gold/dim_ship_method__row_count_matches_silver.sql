-- Returns a row (= fails) if gld_dim_ship_method does not have exactly one row per silver shipping
-- method, plus the 2 default rows (-1 Missing, -2 Not Applicable) added by upsert_default_rows.
-- A dropped method, or a duplicate from the merge, shows up here.
select
    silver_methods.n as silver_rows,
    dim_methods.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_purchasing__ship_method') }}) as silver_methods
cross join (select count(*) as n from {{ ref('gld_dim_ship_method') }}) as dim_methods
where dim_methods.n != silver_methods.n + 2
