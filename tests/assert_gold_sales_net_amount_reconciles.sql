-- In fct_sales_orders, net_line_amount must equal order_quantity * unit_price_amount - discount_amount
select
    sales_order_detail_id,
    net_line_amount,
    gross_line_amount,
    discount_amount,
    (gross_line_amount - discount_amount) as calculated_net_line_amount
from {{ ref('fct_sales_orders') }}
where abs(net_line_amount - (gross_line_amount - discount_amount)) > 0.01
