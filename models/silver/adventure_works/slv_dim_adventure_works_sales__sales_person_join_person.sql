-- slv_dim_adventure_works_sales__sales_person_join_person
-- ONE row per salesperson. Row count equals slv_adventure_works_sales__sales_person (17),
-- enforced by tests/silver/slv_dim_adventure_works_sales__sales_person_join_person__row_count_matches_source.sql.
--
-- Resolves the salesperson's display name from adw_core's person model so gld_dim_sales_person
-- is a straight select. LEFT join, so a salesperson with no matching person row is kept (with a
-- null name) instead of silently disappearing. No surrogate key is minted here: business_entity_id
-- is the natural key and gold mints its own sales_person_key.
{{ config(alias="stg_dim_sales_person_join_person") }}

select
    -- keys ----------------------------------------------------------------
    sp.business_entity_id,

    -- identity --------------------------------------------------------------
    p.person_full_name                      as sales_person_full_name,

    -- assignment and targets --------------------------------------------------
    sp.territory_id,
    sp.sales_quota,
    sp.bonus,
    sp.commission_pct,

    -- pre-aggregated source totals (not additive) -----------------------------
    sp.sales_ytd,
    sp.sales_last_year,

    -- audit -------------------------------------------------------------------
    sp.modified_date                        as sales_person_modified_date

from {{ ref('slv_adventure_works_sales__sales_person') }} as sp
left join {{ ref('adw_core', 'slv_adventure_works_person__person') }} as p
    on sp.business_entity_id = p.business_entity_id
