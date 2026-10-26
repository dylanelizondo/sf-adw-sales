{{ config(
    alias="dim_sales_person",
    materialized='incremental',
    unique_key='business_entity_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('business_entity_id', {
        'SALES_QUOTA': [none, none],
        'BONUS': [none, none],
        'COMMISSION_PCT': [none, none],
        'SALES_YTD': [none, none],
        'SALES_LAST_YEAR': [none, none],
    }) }}"
    )
}}

-- dim_sales_person
-- ONE row per salesperson (17) plus the two default rows (-1 Missing, -2 Not Applicable) that
-- upsert_default_rows adds in the post_hook. Row count equals
-- slv_dim_adventure_works_sales__sales_person_join_person + 2, enforced by
-- tests/gold/dim_sales_person__row_count_matches_silver.sql.
--
-- Type 1: merge keyed on business_entity_id, so a changed salesperson overwrites its row in place
-- and no history is kept. Straight select from ONE silver model, no JOINs: the name is already
-- resolved in silver.
--
-- The facts point online sales (no salesperson) at the -2 "Not Applicable" row. The money and
-- rate columns are overridden to NULL on both default rows, otherwise they would carry the
-- generic -1/-2 numbers and any commission or quota calculation on those rows would be negative.
--
-- territory_id is a flat descriptive attribute, not a relationship: the fact joins
-- dim_territory directly, there is no gold-to-gold foreign key.

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['business_entity_id']) }} as sales_person_key,
    c.business_entity_id,

    -- identity --------------------------------------------------------------
    c.sales_person_full_name,

    -- assignment and targets --------------------------------------------------
    c.territory_id,
    c.sales_quota,
    c.bonus,
    c.commission_pct,

    -- pre-aggregated source totals (not additive) -----------------------------
    c.sales_ytd,
    c.sales_last_year,

    -- audit -------------------------------------------------------------------
    c.sales_person_modified_date

from {{ ref('slv_dim_adventure_works_sales__sales_person_join_person') }} as c
