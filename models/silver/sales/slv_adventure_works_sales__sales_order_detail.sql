select
    -- Primary & Foreign Keys
    try_to_number(trim(sales_order_detail_id::varchar))::number(38,0)     as sales_order_detail_id,
    try_to_number(trim(sales_order_id::varchar))::number(38,0)            as sales_order_id,
    product_id::number(38,0)                                              as product_id,
    special_offer_id::number(38,0)                                        as special_offer_id,

    -- Tracking Information
    trim(carrier_tracking_number)                                         as carrier_tracking_number,

    -- Order Quantities & Pricing
    order_qty::number(38,0)                                               as order_qty,
    unit_price::number(19,4)                                              as unit_price,
    unit_price_discount::number(19,4)                                     as unit_price_discount,
    -- LINE_TOTAL reconciles with the source, so it is kept as delivered and never
    -- recomputed. tests/assert_line_total_reconciles.sql guards that assumption.
    line_total::number(38,6)                                              as line_total,

    -- Metadata & Audit
    rowguid,
    try_to_date(modified_date)                                            as modified_date,
    current_timestamp()                                                   as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_ORDER_DETAIL'                            as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_detail') }}
where try_to_number(trim(sales_order_detail_id::varchar)) is not null
  and try_to_number(trim(sales_order_id::varchar)) is not null
