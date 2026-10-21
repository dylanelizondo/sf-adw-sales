-- Returns a row (= fails) if dim_sales_person does not have exactly one row per silver
-- salesperson, plus the 2 default rows (-1 Missing, -2 Not Applicable) added by
-- upsert_default_rows. A dropped salesperson shows up here.
select
    silver_sales_people.n as silver_rows,
    dim_sales_people.n as dim_rows
from (select count(*) as n from {{ ref('slv_dim_adventure_works_sales__sales_person_join_person') }}) as silver_sales_people
cross join (select count(*) as n from {{ ref('gld_dim_sales_person') }}) as dim_sales_people
where dim_sales_people.n != silver_sales_people.n + 2
