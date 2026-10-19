{{ config(alias="stg_dim_store_join_individual_customer") }}
select
    -- keys ----------------------------------------------------------------
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