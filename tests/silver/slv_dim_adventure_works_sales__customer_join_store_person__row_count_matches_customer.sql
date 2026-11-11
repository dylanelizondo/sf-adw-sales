-- Returns a row (= fails) if the model does not have exactly one row per silver customer.
-- A fan-out from the store or person join, or a dropped customer, shows up here.
select
    silver_customers.n as customer_rows,
    joined_customers.n as model_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__customer') }}) as silver_customers
cross join (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__customer_join_store_person') }}) as joined_customers
where silver_customers.n != joined_customers.n
