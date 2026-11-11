{{ config(
    alias="dim_credit_card",
    materialized='incremental',
    unique_key='credit_card_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('credit_card_id') }}"
    )
}}

-- dim_credit_card
-- ONE row per credit card plus the two default rows (-1 Missing, -2 Not Applicable) that
-- upsert_default_rows adds in the post_hook. Row count equals
-- slv_adventure_works_sales__credit_card + 2, enforced by
-- tests/gold/dim_credit_card__row_count_matches_silver.sql.
--
-- Type 1: merge keyed on credit_card_id, so a changed card overwrites its row in place and no
-- history is kept. Straight select from ONE silver model, no JOINs.
--
-- The facts point orders paid without a card at the -2 "Not Applicable" row. The real card
-- number never reaches silver or gold: only the last four digits and a one-way hash are exposed.

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['credit_card_id']) }} as credit_card_key,
    c.credit_card_id,

    -- card --------------------------------------------------------------------
    c.card_type,
    c.card_last_four,
    c.card_number_hash,
    c.expiry_date,

    -- audit -------------------------------------------------------------------
    c.modified_date                             as credit_card_modified_date

from {{ ref('slv_adventure_works_sales__credit_card') }} as c
