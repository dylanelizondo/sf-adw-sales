{{ config(
    alias="dim_address",
    materialized='incremental',
    unique_key='address_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('address_id') }}"
    )
}}

-- dim_address
-- ONE row per address plus the two default rows (-1 Missing, -2 Not Applicable)
-- that upsert_default_rows adds in the post_hook.
--
-- Type 1: merge keyed on address_id, so a changed address overwrites its row in place
-- and no history is kept. Straight select from ONE silver model, no JOINs.

select
    -- keys ------------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['address_id']) }} as address_key,
    a.address_id,

    -- address -------------------------------------------------------------------
    a.address_line1,
    a.address_line2,
    a.city,
    a.postal_code,

    -- foreign keys ------------------------------------------------------------
    a.state_province_id,
    a.state_province_code,
    a.state_province_name,
    a.country_region_code,
    a.territory_id,

    -- audit -------------------------------------------------------------------
    a.address_modified_date

from {{ ref('slv_dim_adventure_works_person__address_join_state_province') }} as a