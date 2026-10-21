-- Returns a row (= fails) if fct_order_header does not have exactly one row per silver order,
-- plus the 2 default rows (-1 Missing, -2 Not Applicable) added by upsert_default_rows.
-- A fan-out from the order-line join, or a dropped order, shows up here.
select
    silver_orders.n as silver_rows,
    fct_order_rows.n as fct_rows
from (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__sales_order_header_join_detail') }}) as silver_orders
cross join (select count(*) as n from {{ ref('gld_fct_order_header') }}) as fct_order_rows
where fct_order_rows.n != silver_orders.n + 2
