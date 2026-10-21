{{ config(
    alias="dim_sales_person",
    materialized='incremental',
    unique_key='business_entity_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('business_entity_id') }}"
    )
}}

-- dim_sales_person
-- ONE row per salesperson (17, equal to slv_adventure_works_sales__sales_person) plus the
-- two default rows (-1 Missing, -2 Not Applicable) that upsert_default_rows adds in the
-- post_hook, so facts with no assigned salesperson (for example online orders) still join.
--
-- Type 1: merge keyed on business_entity_id, so a changed salesperson overwrites their row
-- in place and no history is kept. Straight select from ONE silver model, no JOINs in gold:
-- the display name is resolved in silver (same pattern as
-- slv_dim_adventure_works_sales__store_join_person) rather than joined here, keeping this a
-- star-schema dimension with no gold-to-gold FK.

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['business_entity_id']) }} as sales_person_key,
    sp.business_entity_id,

    -- identity ----------------------------------------------------------------
    sp.sales_person_full_name,

    -- territory reference (plain attribute -- territory_id already lives on fct_order_header,
    -- kept here only to describe which territory this salesperson is assigned to) ------------
    sp.territory_id,

    -- performance ---------------------------------------------------------------
    sp.sales_quota,
    sp.bonus,
    sp.commission_pct,
    sp.sales_ytd,
    sp.sales_last_year,

    -- audit -------------------------------------------------------------------
    sp.sales_person_modified_date

from {{ ref('slv_dim_adventure_works_sales__sales_person_join_person') }} as sp
