{{ config(
    alias="dim_territory",
    materialized='incremental',
    unique_key='territory_id',
    incremental_strategy='merge'
    )
}}

-- dim_territory
-- ONE row per sales territory (10). Row count equals slv_dim_adventure_works_sales__sales_territory,
-- enforced by tests/gold/gld_dim_territory__row_count_matches_silver.sql.
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
