-- Falla (devuelve filas) si:
--   (a) el cliente no tiene tienda y store_key no es 'Not Applicable'; o
--   (b) el cliente tiene tienda y store_key no es una versión de ESA tienda
--       (fila por defecto, de otra tienda o inexistente).
with fact as (
    select sales_order_detail_id, store_key
    from {{ ref('gld_fct_order_items') }}
),

silver as (
    select sales_order_detail_id, store_id
    from {{ ref('slv_dim_adventure_works_sales__sales_order_detail_join_header') }}
),

store_versions as (
    select store_id, store_key
    from {{ ref('gld_dim_store') }}
    where store_id > 0
)

select
    f.sales_order_detail_id,
    s.store_id,
    f.store_key
from fact as f
join silver as s
    on s.sales_order_detail_id = f.sales_order_detail_id
where
    -- (a) sin tienda, pero la key no es Not Applicable
    (s.store_id is null and f.store_key != 'Not Applicable')
    -- (b) con tienda, pero la key no pertenece a una versión de esa tienda
    or (
        s.store_id is not null
        and not exists (
            select 1
            from store_versions as v
            where v.store_id = s.store_id
              and v.store_key = f.store_key
        )
    )