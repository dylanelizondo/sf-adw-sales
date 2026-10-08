-- Quantity must be positive, the unit price cannot be negative, and the discount is a fraction
-- between 0 and 1. A row returned here carries a sentinel or a sign error that a not_null test
-- would let through.
select
    sales_order_detail_id,
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
