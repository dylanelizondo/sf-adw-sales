-- Returns a row (= fails) if dim_orders does not have exactly one row per silver order.
-- A fan-out from the order-line join, or a dropped order, shows up here.
select
    silver_orders.n as silver_rows,
    dim_order_rows.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__sales_order_header') }}) as silver_orders
cross join (select count(*) as n from {{ ref('dim_orders') }}) as dim_order_rows
where silver_orders.n != dim_order_rows.n
