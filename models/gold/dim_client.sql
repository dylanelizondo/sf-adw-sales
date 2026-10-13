-- dim_client
-- ONE row per client (customer). Row count equals brz_adventure_works_sales__customer,
-- enforced by tests/gold/dim_client__row_count_matches_source.sql.
--
-- A plain select over bronze customer: no joins and no business logic. Joins (store name,
-- person attributes) and derived columns (client type) belong to silver and are not part of
-- this dimension.
--
-- Two keys. client_key is the md5 surrogate key, built like the silver customer_key, so it is
-- stable and is the one to join on. client_sk is a sequential integer (row_number ordered by
-- customer_id) for BI tools; because this model is a view it is recomputed on every query, so
-- it stays stable while customers are only added at the end, but it is not a stored autoincrement.

select
    -- keys ----------------------------------------------------------------
    row_number() over (order by customer_id)    as client_sk,
    md5(cast(coalesce(cast(customer_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))    as client_key,
    customer_id,

    -- client ------------------------------------------------------------------
    account_number                              as client_account_number,

    -- foreign keys ------------------------------------------------------------
    store_id,
    person_id,
    territory_id,

    -- audit -------------------------------------------------------------------
    try_to_timestamp(modified_date::varchar)    as client_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__customer') }}
