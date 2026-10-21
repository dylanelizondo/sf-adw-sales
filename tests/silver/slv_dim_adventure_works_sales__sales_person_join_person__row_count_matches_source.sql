-- Returns a row (= fails) if the model does not have exactly one row per silver salesperson.
-- A fan-out from the person join, or a dropped salesperson, shows up here.
select
    silver_sales_people.n as sales_person_rows,
    joined_sales_people.n as model_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__sales_person') }}) as silver_sales_people
cross join (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__sales_person_join_person') }}) as joined_sales_people
where silver_sales_people.n != joined_sales_people.n
