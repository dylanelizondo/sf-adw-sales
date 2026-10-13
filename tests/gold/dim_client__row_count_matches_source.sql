-- Returns a row (= fails) if dim_client does not have exactly one row per bronze customer.
-- A duplicated or dropped customer shows up here.
select
    source_customers.n as source_rows,
    dim_clients.n as dim_rows
from (select count(*) as n from {{ ref('adw_core', 'brz_adventure_works_sales__customer') }}) as source_customers
cross join (select count(*) as n from {{ ref('dim_client') }}) as dim_clients
where source_customers.n != dim_clients.n
