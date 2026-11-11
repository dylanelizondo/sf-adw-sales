-- Returns a row (= fails) if dim_client does not have exactly one row per silver customer,
-- plus the 2 default rows (-1 Missing, -2 N/A) added by upsert_default_rows.
-- A fan-out from the store or slv_adventure_works_person__person join, or a dropped customer, shows up here.
select
    silver_customers.n as silver_rows,
    dim_clients.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__customer') }}) as silver_customers
cross join (select count(*) as n from {{ ref('gld_dim_client') }}) as dim_clients
where dim_clients.n != silver_customers.n + 2
