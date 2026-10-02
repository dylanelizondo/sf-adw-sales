-- In sales order headers, total_due must equal sub_total + tax_amt + freight.
-- Any row returned indicates a calculation inconsistency in the source/silver layer.
select
    sales_order_id,
    sub_total,
    tax_amt,
    freight,
    total_due,
    (sub_total + tax_amt + freight) as calculated_total_due,
    abs(total_due - (sub_total + tax_amt + freight)) as difference
from {{ ref('slv_adventure_works_sales__sales_order_header') }}
where abs(total_due - (sub_total + tax_amt + freight)) > 0.01
