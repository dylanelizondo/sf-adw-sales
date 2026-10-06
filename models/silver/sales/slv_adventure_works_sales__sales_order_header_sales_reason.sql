select
    -- Composite key: the source keys arrive corrupted, so they are trimmed and safely cast.
    -- Rows where either part cannot be parsed are dropped in the final filter.
    try_to_number(trim(sales_order_id::varchar))::number(38,0)    as sales_order_id,
    try_to_number(trim(sales_reason_id::varchar))::number(38,0)   as sales_reason_id,
    try_to_date(modified_date)                                      as modified_date,
    current_timestamp()                                             as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_ORDER_HEADER_SALES_REASON'         as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header_sales_reason') }}
where try_to_number(trim(sales_order_id::varchar)) is not null
  and try_to_number(trim(sales_reason_id::varchar)) is not null
