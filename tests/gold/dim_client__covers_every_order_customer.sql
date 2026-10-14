-- Every customer that placed an order must exist in dim_client, otherwise a join from the orders
-- to the client dimension silently drops sales. A row returned here is an order customer with no
-- client row.
select distinct
    o.customer_id
from {{ ref('gld_dim_orders') }} as o
left join {{ ref('gld_dim_client') }} as c
    on o.customer_id = c.customer_id
where c.customer_id is null
