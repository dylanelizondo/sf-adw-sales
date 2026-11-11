{{ config(alias="stg_dim_adw_sales_person_credit_card") }}

select
    business_entity_id,
    credit_card_id,
    modified_date                                   as modified_date,
    current_timestamp()                             as _loaded_at,
    'ADVENTURE_WORKS.SALES.PERSON_CREDIT_CARD'       as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__person_credit_card') }}