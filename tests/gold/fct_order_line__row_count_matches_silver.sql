-- La fact debe tener una fila por línea del silver de detalle, más una fila de cargos por cada
-- orden con tax o freight (sin "+ 2": las facts no llevan filas por defecto).
-- Falla si el join con el snapshot de tienda duplica filas o si se pierden líneas u órdenes.
with fact as (
    select count(*) as n from {{ ref('gld_fct_order_line') }}
),
silver_lines as (
    select count(*) as n from {{ ref('slv_dim_adventure_works_sales__sales_order_detail_join_header') }}
),
silver_charges as (
    select count(*) as n
    from {{ ref('slv_dim_adventure_works_sales__sales_order_header_join_detail') }}
    where coalesce(tax_amt, 0) != 0 or coalesce(freight, 0) != 0
)
select
    fact.n as fact_rows,
    silver_lines.n + silver_charges.n as silver_rows
from fact, silver_lines, silver_charges
where fact.n != silver_lines.n + silver_charges.n
