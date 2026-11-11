{{ config(
    alias="dim_ship_method",
    materialized='incremental',
    unique_key='ship_method_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('ship_method_id', {
        'SHIP_BASE': [none, none],
        'SHIP_RATE': [none, none],
    }) }}"
    )
}}

-- dim_ship_method
-- ONE row per shipping method plus the two default rows (-1 Missing, -2 Not Applicable) that
-- upsert_default_rows adds in the post_hook. Row count equals
-- slv_adventure_works_purchasing__ship_method + 2, enforced by
-- tests/gold/dim_ship_method__row_count_matches_silver.sql.
--
-- Type 1: merge keyed on ship_method_id, so a changed method overwrites its row in place and no
-- history is kept. Straight select from ONE silver model, no JOINs. The surrogate key is the one
-- silver already minted (ship_method_key): inherited, never recomputed.
--
-- The rates are NULL on the default rows, so no sentinel number is mistaken for a real charge.

select
    -- keys ----------------------------------------------------------------
    s.ship_method_key,
    s.ship_method_id,

    -- shipping method -----------------------------------------------------------
    s.ship_method_name,
    s.ship_base,
    s.ship_rate,

    -- audit -------------------------------------------------------------------
    s.ship_method_modified_date

from {{ ref('slv_adventure_works_purchasing__ship_method') }} as s
