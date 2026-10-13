-- dim_territory
-- ONE row per sales territory. Row count equals slv_adventure_works_sales__sales_territory (10).
--
-- Reads from SILVER as-is: slv_adventure_works_sales__sales_territory does not mint a
-- surrogate key, so per team convention we use the natural TERRITORY_ID directly as the
-- dimension key. The *_YTD / *_LAST_YEAR columns are pre-aggregated source snapshots
-- flagged in silver as "not to be used as a metric in gold", so they are intentionally
-- left out of this dimension.

select
    -- keys ------------------------------------------------------------------
    territory_id                            as territory_key,
    territory_id,

    -- territory ---------------------------------------------------------------
    name                                     as territory_name,
    country_region_code,
    territory_group,

    -- audit -------------------------------------------------------------------
    modified_date                           as territory_modified_date

from {{ ref('slv_adventure_works_sales__sales_territory') }}