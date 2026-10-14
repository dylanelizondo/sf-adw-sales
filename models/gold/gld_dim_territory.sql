-- gld_dim_territory  (SCD TYPE 1 -> dbt incremental)
-- ONE row per sales territory (10). Row count equals slv_dim_adventure_works_sales__sales_territory,
-- enforced by tests/gold/gld_dim_territory__row_count_matches_silver.sql.
--
-- Type 1: attributes are overwritten in place, no history kept. Incremental MERGE on the
-- natural key territory_id (no surrogate key is minted).
--
-- The *_YTD / *_LAST_YEAR columns are pre-aggregated source snapshots flagged in silver as
-- "not to be used as a metric in gold", so they are intentionally left out.
-- Reads from a single silver model with NO JOINs.
{{ config(
    alias='dim_territory',
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='territory_id'
) }}

select
    -- keys ------------------------------------------------------------------
    territory_id,

    -- territory ---------------------------------------------------------------
    name                                     as territory_name,
    country_region_code,
    territory_group,

    -- audit -------------------------------------------------------------------
    modified_date                            as territory_modified_date

from {{ ref('slv_dim_adventure_works_sales__sales_territory') }}
{% if is_incremental() %}
where modified_date >= (select max(territory_modified_date) from {{ this }})
{% endif %}
