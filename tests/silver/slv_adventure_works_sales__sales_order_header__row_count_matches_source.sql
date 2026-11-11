-- Returns a row (= fails) if the silver header has a different number of rows than bronze.
-- Silver drops rows whose order key cannot be recovered, so a wrong recover_sales_order_id
-- rule shows up here as lost orders instead of passing unnoticed.
select
    source_orders.n as source_rows,
    silver_orders.n as silver_rows
from (select count(*) as n from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header') }}) as source_orders
cross join (select count(*) as n from {{ ref('slv_adventure_works_sales__sales_order_header') }}) as silver_orders
where source_orders.n != silver_orders.n
