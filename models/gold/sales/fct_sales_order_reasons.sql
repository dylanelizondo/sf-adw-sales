select
    -- Natural & Composite Keys
    sr.sales_order_id                                                      as sales_order_id,
    sr.sales_reason_id                                                     as sales_reason_id,
    f.sales_order_detail_id                                                as sales_order_detail_id,
    f.customer_id                                                          as customer_id,
    f.territory_id                                                         as territory_id,
    f.sales_person_id                                                      as sales_person_id,
    f.product_id                                                           as product_id,

    -- Order & Reason Context
    f.order_date                                                           as order_date,
    f.order_status_label                                                   as order_status_label,
    f.order_channel_label                                                  as order_channel_label,
    f.is_online_order                                                      as is_online_order,

    -- Attributed Revenue & Quantities
    f.order_quantity                                                       as order_quantity,
    f.gross_line_amount                                                    as gross_line_amount,
    f.discount_amount                                                      as discount_amount,
    f.net_line_amount                                                      as net_line_amount,
    f.allocated_total_line_amount                                          as allocated_total_line_amount,

    -- Audit Metadata
    current_timestamp()                                                    as _loaded_at
from {{ ref('slv_adventure_works_sales__sales_order_header_sales_reason') }} sr
inner join {{ ref('fct_sales_orders') }} f
    on sr.sales_order_id = f.sales_order_id
