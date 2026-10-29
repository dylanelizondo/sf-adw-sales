-- Returns a row (= fails) if gld_dim_credit_card does not have exactly one row per silver credit
-- card, plus the 2 default rows (-1 Missing, -2 Not Applicable) added by upsert_default_rows.
-- A dropped card, or a duplicate from the merge, shows up here.
select
    silver_cards.n as silver_rows,
    dim_cards.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__credit_card') }}) as silver_cards
cross join (select count(*) as n from {{ ref('gld_dim_credit_card') }}) as dim_cards
where dim_cards.n != silver_cards.n + 2
