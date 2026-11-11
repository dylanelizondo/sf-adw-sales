-- Returns a row (= fails) if the silver bridge has a different number of rows than bronze.
-- Silver drops rows whose keys cannot be parsed or recovered, so a wrong key rule shows up
-- here as lost rows instead of passing unnoticed.
select
    source_rows.n as source_rows,
    silver_rows.n as silver_rows
from (select count(*) as n from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header_sales_reason') }}) as source_rows
cross join (select count(*) as n from {{ ref('slv_adventure_works_sales__sales_order_header_sales_reason') }}) as silver_rows
where source_rows.n != silver_rows.n
