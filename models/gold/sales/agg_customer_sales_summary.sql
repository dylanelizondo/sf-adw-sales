select
    -- Customer Dimension Identifier
    customer_id                                                            as customer_id,

    -- Recency & Activity Metrics
    min(order_date)                                                        as first_order_date,
    max(order_date)                                                        as most_recent_order_date,
    datediff('day', min(order_date), max(order_date))                      as customer_lifespan_days,

    -- Order Frequency & Volume
    count(distinct sales_order_id)                                         as total_orders_placed_count,
    sum(order_quantity)                                                    as total_units_purchased_count,
    count(distinct product_id)                                             as distinct_products_purchased_count,

    -- Monetary Value KPIs
    sum(gross_line_amount)::number(19,4)                                   as lifetime_gross_revenue_amount,
    sum(discount_amount)::number(19,4)                                     as lifetime_discount_amount,
    sum(net_line_amount)::number(19,4)                                     as lifetime_net_revenue_amount,
    sum(allocated_tax_amount)::number(19,4)                                 as lifetime_tax_amount,
    sum(allocated_freight_amount)::number(19,4)                               as lifetime_freight_amount,
    sum(allocated_total_line_amount)::number(19,4)                         as lifetime_total_spend_amount,

    -- Averages & Behavior
    (sum(net_line_amount) / nullif(count(distinct sales_order_id), 0))::number(19,4) as average_order_value_amount,
    (sum(order_quantity) / nullif(count(distinct sales_order_id), 0))::number(19,2)  as average_units_per_order,

    -- Channel Preferences
    sum(case when is_online_order then 1 else 0 end)                       as online_orders_count,
    sum(case when not is_online_order then 1 else 0 end)                   as salesperson_orders_count,
    case
        when sum(case when not is_online_order then 1 else 0 end) = 0 then 'Online Only'
        when sum(case when is_online_order then 1 else 0 end) = 0 then 'Salesperson Only'
        else 'Omnichannel'
    end                                                                    as preferred_channel_segment,

    -- Audit Metadata
    current_timestamp()                                                    as _loaded_at
from {{ ref('fct_sales_orders') }}
group by
    customer_id
