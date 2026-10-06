-- LINE_TOTAL is kept as delivered by the source. This test proves it still reconciles
-- with quantity * price * (1 - discount); any row returned is a line that does not.
select
    sales_order_detail_id,
    line_total,
    order_qty * unit_price * (1 - unit_price_discount) as recomputed_line_total
from {{ ref('slv_adventure_works_sales__sales_order_detail') }}
where abs(line_total - (order_qty * unit_price * (1 - unit_price_discount))) > 0.01
