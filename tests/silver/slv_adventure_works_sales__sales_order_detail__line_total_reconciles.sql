-- LINE_TOTAL is kept as delivered by the source and never recomputed. This proves it still
-- equals quantity * price * (1 - discount); a row returned is a line that does not add up.
select
    sales_order_detail_id,
    line_total,
    order_qty * unit_price * (1 - unit_price_discount) as recomputed_line_total
from {{ ref('slv_adventure_works_sales__sales_order_detail') }}
where abs(line_total - (order_qty * unit_price * (1 - unit_price_discount))) > 0.01
