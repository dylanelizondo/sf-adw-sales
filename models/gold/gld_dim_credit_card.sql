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
-- upsert_default_rows adds in the post_hook, so facts with no card on file (for example cash
-- or no-card orders) still join.
--
-- Type 1: merge keyed on credit_card_id, so a changed card overwrites its row in place and
-- no history is kept. Straight select from ONE silver model, no JOINs.
--
-- PII note: the raw PAN never reaches here either -- silver already drops it, exposing only
-- card_last_four and a one-way hash. See slv_adventure_works_sales__credit_card.yml.

select
    -- keys ------------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['credit_card_id']) }} as credit_card_key,
    cc.credit_card_id,

    -- card --------------------------------------------------------------------
    cc.card_type,
    cc.card_last_four,
    cc.card_number_hash,
    cc.expiry_date,

    -- audit -------------------------------------------------------------------
    cc.modified_date as credit_card_modified_date

from {{ ref('slv_adventure_works_sales__credit_card') }} as cc
