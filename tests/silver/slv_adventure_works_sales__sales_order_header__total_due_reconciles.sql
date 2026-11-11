-- total_due must equal sub_total + tax_amt + freight. A row returned here is an order whose
-- amounts do not add up.
select
    sales_order_id,
    sub_total,
    tax_amt,
    freight,
    total_due,
    sub_total + tax_amt + freight as expected_total_due
from {{ ref('slv_adventure_works_sales__sales_order_header') }}
where abs(total_due - (sub_total + tax_amt + freight)) > 0.01
