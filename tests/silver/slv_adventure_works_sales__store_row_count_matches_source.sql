-- Returns rows (= fails) if slv_dim_adventure_works_sales__store_join_person no longer has
-- exactly one row per store.
with source as (
    select count(*) as n from {{ ref('adw_core', 'brz_adventure_works_sales__store') }}
),
model as (
    select count(*) as n from {{ ref('slv_dim_adventure_works_sales__store_join_person') }}
)
select source.n as source_rows, model.n as model_rows
from source cross join model
where source.n != model.n
