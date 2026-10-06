-- The grain of this bridge table is one row per (order, reason). dbt_utils is not
-- installed in this project, so pair uniqueness is checked here; any row returned
-- is a duplicated pair.
select
    sales_order_id,
    sales_reason_id,
    count(*) as row_count
from {{ ref('slv_adventure_works_sales__sales_order_header_sales_reason') }}
group by sales_order_id, sales_reason_id
having count(*) > 1
