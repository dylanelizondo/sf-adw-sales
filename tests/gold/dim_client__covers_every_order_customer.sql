-- Falla (devuelve filas) si alguna línea de la fact apunta a un cliente
-- que no existe en gld_dim_client.
select
    f.sales_order_detail_id,
    f.customer_key
from {{ ref('gld_fct_order_items') }} as f
left join {{ ref('gld_dim_client') }} as c
    on c.client_key = f.customer_key
where c.client_key is null