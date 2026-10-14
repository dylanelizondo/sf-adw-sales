-- dim_store
-- ONE row per reseller store. Row count equals slv_dim_adventure_works_sales__store_join_person (701),
-- enforced by tests/gold/dim_store__row_count_matches_silver.sql.
--
-- Reads from gld_dim_store_snapshot, a Type 2 history of silver keyed on store_id, and
-- keeps only the current row per store (dbt_valid_to is null) so this stays a one-row-
-- per-store current-state dimension. Query the snapshot directly for history.
--
-- The snapshot's own audit columns (dbt_scd_id, dbt_updated_at, dbt_valid_from,
-- dbt_valid_to) are excluded so they don't leak into the dimension's column list.
--
-- store_key is an auto-incrementing row number, minted HERE because the snapshot carries
-- no surrogate key of its own (only the natural key, store_id). row_number() is used
-- instead of a Snowflake SEQUENCE because this table is rebuilt with CREATE OR REPLACE on
-- every run -- a SEQUENCE would keep climbing across runs instead of restarting, so the
-- key would not be reproducible.
{{ config(alias='adw_dim_store' ) }}
select
    -- keys ----------------------------------------------------------------
    row_number() over (order by s.store_id) as store_key,
    s.* exclude (dbt_scd_id, dbt_updated_at, dbt_valid_from, dbt_valid_to)

from {{ ref('gld_dim_store_snapshot') }} as s
where s.dbt_valid_to is null
