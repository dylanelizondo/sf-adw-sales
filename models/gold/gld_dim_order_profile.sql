{{ config(
    alias="dim_order_profile",
    materialized='incremental',
    unique_key='order_profile_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('order_profile_id') }}"
    )
}}

-- dim_order_profile
-- Junk dimension: ONE row per combination of order status, sales channel and shipped flag (a few
-- dozen), plus the two default rows (-1 Missing, -2 Not Applicable) that upsert_default_rows adds
-- in the post_hook. Row count equals slv_dim_adventure_works_sales__order_profile + 2, enforced by
-- tests/gold/dim_order_profile__row_count_matches_silver.sql.
--
-- It holds the low-cardinality descriptors that would otherwise repeat on every row of
-- gld_fct_order_line, which carries only order_profile_key.
--
-- Type 1: merge keyed on order_profile_id. Straight select from ONE silver model, no JOINs. The
-- silver rows have no modified date, so every run re-selects all of them (a few dozen); the merge
-- makes that harmless.

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['order_profile_id']) }} as order_profile_key,
    order_profile_id,

    -- descriptors -------------------------------------------------------------
    order_status_code,
    order_status_label,
    is_online_order,
    order_channel,
    is_shipped

from {{ ref('slv_dim_adventure_works_sales__order_profile') }}
