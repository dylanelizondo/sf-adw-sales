{{ config(
    alias="dim_special_offer",
    materialized='incremental',
    unique_key='special_offer_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('special_offer_id', {
        'SPECIAL_OFFER_DISCOUNT_PCT': [none, none],
        'SPECIAL_OFFER_MIN_QTY': [none, none],
        'SPECIAL_OFFER_MAX_QTY': [none, none],
    }) }}"
    )
}}

-- dim_special_offer
-- ONE row per promotion plus the two default rows (-1 Missing, -2 Not Applicable) that
-- upsert_default_rows adds in the post_hook. Row count equals
-- slv_adventure_works_sales__special_offer + 2, enforced by
-- tests/gold/dim_special_offer__row_count_matches_silver.sql.
--
-- Type 1: merge keyed on special_offer_id, so a changed promotion overwrites its row in place and
-- no history is kept. Straight select from ONE silver model, no JOINs. The surrogate key is the
-- one silver already minted (special_offer_key): inherited, never recomputed.
--
-- The facts point the order-charge row (no product, so no promotion) at the -2 "Not Applicable"
-- row. The discount percentage and the quantity range are NULL on the default rows, so no
-- sentinel number is mistaken for a real 0% / -1 units.

select
    -- keys ----------------------------------------------------------------
    s.special_offer_key,
    s.special_offer_id,

    -- promotion ---------------------------------------------------------------
    s.special_offer_description,
    s.special_offer_type,
    s.special_offer_category,
    s.special_offer_discount_pct,
    s.special_offer_min_qty,
    s.special_offer_max_qty,
    s.special_offer_start_date,
    s.special_offer_end_date,

    -- audit -------------------------------------------------------------------
    s.special_offer_modified_date

from {{ ref('slv_adventure_works_sales__special_offer') }} as s
