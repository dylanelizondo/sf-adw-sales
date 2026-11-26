-- An online order never carries a purchase order (the fact shows Not Applicable) and a reseller
-- order always does. A row returned here is an order that breaks that rule: a reseller order whose
-- purchase order number went missing, or an online order that unexpectedly has one.
select
    f.sales_order_id,
    p.is_online_order,
    f.purchase_order_number
from {{ ref('gld_fct_order_line') }} as f
inner join {{ ref('gld_dim_order_profile') }} as p
    on f.order_profile_key = p.order_profile_key
where (p.is_online_order and f.purchase_order_number != '{{ default_row_text(1) }}')
   or (not p.is_online_order and (f.purchase_order_number is null or f.purchase_order_number = '{{ default_row_text(1) }}'))
