select
    -- Aggregation Grain
    order_date                                                             as order_date,
    coalesce(territory_id, -1)                                             as territory_id,
    coalesce(sales_person_id, -1)                                          as sales_person_id,
    is_online_order                                                        as is_online_order,
    order_channel_label                                                    as order_channel_label,
    order_status_label                                                     as order_status_label,

    -- Volume KPIs
    count(distinct sales_order_id)                                         as total_orders_count,
    count(distinct customer_id)                                            as distinct_customers_count,
    count(sales_order_detail_id)                                           as total_line_items_count,
    sum(order_quantity)                                                    as total_units_sold_count,

    -- Revenue & Financial KPIs
    sum(gross_line_amount)::number(19,4)                                   as gross_revenue_amount,
    sum(discount_amount)::number(19,4)                                     as total_discount_amount,
    sum(net_line_amount)::number(19,4)                                     as net_revenue_amount,
    sum(allocated_tax_amount)::number(19,4)                                 as total_tax_amount,
    sum(allocated_freight_amount)::number(19,4)                               as total_freight_amount,
    sum(allocated_total_line_amount)::number(19,4)                         as total_gross_payable_amount,

    -- Calculated BI Metrics / Averages
    (sum(net_line_amount) / nullif(count(distinct sales_order_id), 0))::number(19,4) as average_order_value_amount,
    (sum(order_quantity) / nullif(count(distinct sales_order_id), 0))::number(19,2)  as average_units_per_order,
    (sum(discount_amount) / nullif(sum(gross_line_amount), 0))::number(19,4)        as average_discount_rate,

    -- Audit Metadata
    current_timestamp()                                                    as _loaded_at
from {{ ref('fct_sales_orders') }}
group by
    order_date,
    coalesce(territory_id, -1),
    coalesce(sales_person_id, -1),
    is_online_order,
    order_channel_label,
    order_status_label
