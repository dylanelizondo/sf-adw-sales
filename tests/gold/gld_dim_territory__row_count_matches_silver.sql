-- Returns a row (= fails) if gld_dim_territory does not have exactly one row per silver territory
-- plus the 2 default rows (-1 Missing, -2 Not Applicable) added by upsert_default_rows.
select
    silver_territories.n as silver_rows,
    dim_territories.n as dim_rows
from (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__sales_territory') }}) as silver_territories
cross join (select count(*) as n from {{ ref('gld_dim_territory') }}) as dim_territories
where dim_territories.n != silver_territories.n + 2
