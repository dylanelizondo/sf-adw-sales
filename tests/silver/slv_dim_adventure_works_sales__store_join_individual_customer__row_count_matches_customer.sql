-- Returns a row (= fails) if the model does not have exactly one row per silver customer.
-- Both joins are left joins on a unique key, so a fan-out or a dropped customer shows up here.
select
    silver_customers.n as customer_rows,
    joined_customers.n as model_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__customer') }}) as silver_customers
cross join (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__store_join_individual_customer') }}) as joined_customers
where silver_customers.n != joined_customers.n
