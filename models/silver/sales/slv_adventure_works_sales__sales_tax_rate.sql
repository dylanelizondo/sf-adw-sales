select
    sales_tax_rate_id,
    state_province_id::number(38,0)                 as state_province_id,
    tax_type                                        as tax_type_code,
    case tax_type
        when 1 then 'Shipping only'
        when 2 then 'State only'
        when 3 then 'Shipping and state'
        else null
    end                                              as tax_type_label,
    tax_rate::number(9,6)                           as tax_rate,
    name,
    try_to_date(modified_date)                      as modified_date,
    current_timestamp()                             as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_TAX_RATE'          as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_tax_rate') }}
