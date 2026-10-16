{{ config(
    alias="dim_client",
    materialized='incremental',
    unique_key='customer_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('customer_id') }}"
    )
}}

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as client_key,
    c.customer_id,

    -- client ------------------------------------------------------------------
    c.client_type,
    c.client_name,
    c.client_account_number,

    -- individual clients only (null for stores) ---------------------------------
    c.client_has_demographics_survey,
    c.client_age_band,
    c.client_education,
    c.client_education_sort,
    c.client_occupation,
    c.client_total_children,
    c.client_number_cars_owned,
    c.client_is_home_owner,

    -- foreign keys ------------------------------------------------------------
    c.store_id,
    c.person_id,
    c.territory_id,
    c.primary_address_id,

    -- audit -------------------------------------------------------------------
    c.client_modified_date

from {{ ref('slv_dim_adventure_works_sales__store_join_individual_customer') }} as c
