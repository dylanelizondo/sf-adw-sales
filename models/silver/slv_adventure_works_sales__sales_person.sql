select
    business_entity_id,
    territory_id::number                            as territory_id,
    sales_quota::number(19,4)                       as sales_quota,
    bonus::number(19,4)                             as bonus,
    commission_pct::number(9,6)                     as commission_pct,
    sales_ytd::number(19,4)                         as sales_ytd,
    sales_last_year::number(19,4)                   as sales_last_year,
    try_to_date(modified_date)                      as modified_date,
    current_timestamp()                             as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_PERSON'            as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_person') }}