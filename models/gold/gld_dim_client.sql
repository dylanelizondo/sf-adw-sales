{{ config(
    alias="dim_client",
    materialized='incremental',
    unique_key='customer_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('customer_id', {
        'CLIENT_TYPE': ['UNKNOWN', 'UNKNOWN'],
        'STORE_ID': [-1, -2],
        'PERSON_ID': [none, none],
    }) }}"
    )
}}

-- territory_id and primary_address_id are dropped on purpose -- they belong to the
-- order (fact), not to the client. store_id is the one dimension-to-dimension FK this
-- model carries: an outrigger to dim_store (not a flatten), accepted here because
-- dim_store has its own Type 2 history that dim_client (Type 1) must not duplicate or
-- freeze a point-in-time copy of. Store descriptive attributes live only in dim_store;
-- join there via store_id for business type, specialty, annual sales, assigned
-- salesperson, etc.

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

    -- outrigger / plain reference --------------------------------------------
    c.store_id,
    c.person_id,

    -- audit -------------------------------------------------------------------
    c.client_modified_date

from {{ ref('slv_dim_adventure_works_sales__store_join_individual_customer') }} as c
