-- slv_dim_adventure_works_sales__sales_territory
-- ONE row per sales territory (10). No JOIN is needed, so the name carries no join_<table> suffix.
-- territory_id is the natural key; no surrogate key is minted here.
{{ config(alias='stg_dim_sales_territory') }}

select
    territory_id,
    name                                            as territory_name,
    country_region_code,
    "GROUP"                                         as territory_group,
    sales_ytd::number(19,4)                         as sales_ytd,
    sales_last_year::number(19,4)                   as sales_last_year,
    cost_ytd::number(19,4)                          as cost_ytd,
    cost_last_year::number(19,4)                    as cost_last_year,
    modified_date                      as territory_modified_date,
    current_timestamp()                             as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_TERRITORY'         as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_territory') }}
