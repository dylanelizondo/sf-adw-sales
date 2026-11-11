-- Order amounts cannot be negative. A row returned here carries a sentinel or a sign error
-- that a not_null test would let through.
select
    sales_order_id,
    sub_total,
    tax_amt,
    freight,
    total_due
from {{ ref('slv_adventure_works_sales__sales_order_header') }}
where sub_total < 0
   or tax_amt < 0
   or freight < 0
   or total_due < 0
