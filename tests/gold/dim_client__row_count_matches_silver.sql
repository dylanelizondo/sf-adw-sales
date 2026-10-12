-- Returns a row (= fails) if dim_client does not have exactly one row per silver customer.
-- A fan-out from the store or slv_person join, or a dropped customer, shows up here.
select
    silver_customers.n as silver_rows,
    dim_clients.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__customer') }}) as silver_customers
cross join (select count(*) as n from {{ ref('dim_client') }}) as dim_clients
where silver_customers.n != dim_clients.n
