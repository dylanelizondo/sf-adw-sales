{{ config(alias="dim_address") }}

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