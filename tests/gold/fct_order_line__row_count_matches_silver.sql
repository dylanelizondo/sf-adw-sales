-- La fact debe tener exactamente las filas del silver de C1 (sin "+ 2": las facts no llevan filas por defecto).
-- Falla si el join con el snapshot de tienda duplica filas o si se pierden líneas.
with fact as (
    select count(*) as n from {{ ref('gld_fct_order_line') }}
),
silver as (
    select count(*) as n from {{ ref('slv_dim_adventure_works_sales__sales_order_detail_join_header') }}
)
select fact.n as fact_rows, silver.n as silver_rows
from fact, silver
where fact.n != silver.n