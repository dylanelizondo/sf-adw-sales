-- Returns a row (= fails) if gld_dim_special_offer does not have exactly one row per silver
-- promotion, plus the 2 default rows (-1 Missing, -2 Not Applicable) added by upsert_default_rows.
-- A dropped promotion, or a duplicate from the merge, shows up here.
select
    silver_offers.n as silver_rows,
    dim_offers.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__special_offer') }}) as silver_offers
cross join (select count(*) as n from {{ ref('gld_dim_special_offer') }}) as dim_offers
where dim_offers.n != silver_offers.n + 2
