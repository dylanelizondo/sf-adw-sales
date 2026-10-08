-- Returns a row (= fails) if dim_store does not have exactly one row per silver store.
-- A fan-out from the slv_person join, or a dropped store, shows up here.
select
    silver_stores.n as silver_rows,
    dim_stores.n as dim_rows
from (select count(*) as n from {{ ref('slv_adventure_works_sales__store') }}) as silver_stores
cross join (select count(*) as n from {{ ref('dim_store') }}) as dim_stores
where silver_stores.n != dim_stores.n
