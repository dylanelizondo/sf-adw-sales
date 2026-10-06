select
    territory_id,
    name,
    country_region_code,
    "GROUP"                                         as territory_group,
    sales_ytd::number(19,4)                         as sales_ytd,
    sales_last_year::number(19,4)                   as sales_last_year,
    cost_ytd::number(19,4)                          as cost_ytd,
    cost_last_year::number(19,4)                    as cost_last_year,
    try_to_date(modified_date)                      as modified_date,
    current_timestamp()                             as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_TERRITORY'         as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_territory') }}