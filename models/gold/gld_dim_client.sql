{{ config(alias="adw_dim_client") }}

-- dim_client
-- ONE row per client (customer). Row count equals slv_adventure_works_sales__customer (19,820),
-- enforced by tests/gold/dim_client__row_count_matches_silver.sql.
--
-- Reads from SILVER, never from bronze. customer_id is the natural key, so the dimension
-- joins straight to dim_orders. client_key is an auto-incrementing surrogate key minted
-- HERE, since silver carries no key of its own -- same approach as dim_store. row_number()
-- is used instead of a Snowflake SEQUENCE because this table is rebuilt with CREATE OR
-- REPLACE on every run -- a SEQUENCE would keep climbing across runs instead of restarting,
-- so the key would not be reproducible.
--
-- Adds the display name and, for individual customers only, non-sensitive self-reported
-- attributes from adw_core's slv_adventure_works_person__person (one row per business_entity_id, so no fan-out).
-- Email, phone and the SENSITIVE survey answers (gender, marital status, income band) are not
-- selected. The 635 customers with both a person and a store id are STORE clients and get no
-- personal data. Store details live in dim_store: join on store_id.

select
    -- keys ----------------------------------------------------------------
    row_number() over (order by c.customer_id)  as client_key,
    c.customer_id,

    -- client ------------------------------------------------------------------
    c.customer_type                             as client_type,
    coalesce(
        case c.customer_type
            when 'STORE'      then s.store_name
            when 'INDIVIDUAL' then p.person_full_name
        end,
        'Unknown'
    )                                           as client_name,
    c.account_number                            as client_account_number,

    -- individual clients only (null for stores) ---------------------------------
    p.has_demographics_survey                   as client_has_demographics_survey,
    p.survey_age_band                           as client_age_band,
    p.survey_education                          as client_education,
    p.survey_education_sort                     as client_education_sort,
    p.survey_occupation                         as client_occupation,
    p.survey_total_children                     as client_total_children,
    p.survey_number_cars_owned                  as client_number_cars_owned,
    p.survey_is_home_owner                      as client_is_home_owner,

    -- foreign keys ------------------------------------------------------------
    c.store_id,
    c.person_id,
    c.territory_id,
    p.primary_address_id,

    -- audit -------------------------------------------------------------------
    c.customer_modified_date                    as client_modified_date

from {{ ref('slv_adventure_works_sales__customer') }} as c
left join {{ ref('slv_dim_adventure_works_sales__store_join_person') }} as s
    on c.store_id = s.store_id
left join {{ ref('adw_core', 'slv_adventure_works_person__person') }} as p
    on c.person_id = p.business_entity_id
   and c.customer_type = 'INDIVIDUAL'
