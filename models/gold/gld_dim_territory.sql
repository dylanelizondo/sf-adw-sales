{{ config(
    alias="dim_territory",
    materialized='incremental',
    unique_key='territory_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('territory_id') }}"
    )
}}

-- dim_territory
-- ONE row per sales territory (10) plus the two default rows (-1 Missing, -2 Not Applicable)
-- that upsert_default_rows adds in the post_hook. Row count equals
-- slv_dim_adventure_works_sales__sales_territory + 2, enforced by
-- tests/gold/gld_dim_territory__row_count_matches_silver.sql.
--
-- Type 1: merge keyed on territory_id, so a changed territory overwrites its row in place
-- and no history is kept. Straight select from ONE silver model, no JOINs.
--
-- The *_YTD / *_LAST_YEAR columns are pre-aggregated source snapshots flagged in silver as
-- "not to be used as a metric in gold", so they are intentionally not selected.

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['territory_id']) }} as territory_key,
    c.territory_id,

    -- territory ---------------------------------------------------------------
    c.territory_name,
    c.country_region_code,
    c.territory_group,

    -- audit -------------------------------------------------------------------
    c.territory_modified_date

from {{ ref('slv_dim_adventure_works_sales__sales_territory') }} as c
