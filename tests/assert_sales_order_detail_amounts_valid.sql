-- Order line quantities, unit prices, and discounts must be valid positive/non-negative numbers.
-- Any row returned indicates invalid pricing or quantities.
select
    sales_order_detail_id,
    sales_order_id,
    order_qty,
    unit_price,
    unit_price_discount,
    line_total
from {{ ref('slv_adventure_works_sales__sales_order_detail') }}
where order_qty <= 0
   or unit_price < 0
   or unit_price_discount < 0
   or unit_price_discount > 1
   or line_total < 0
