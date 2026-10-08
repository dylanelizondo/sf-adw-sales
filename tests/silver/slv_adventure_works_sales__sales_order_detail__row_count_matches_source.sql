-- Returns a row (= fails) if the silver detail has a different number of rows than bronze.
-- Silver drops lines whose keys cannot be parsed or recovered, so a wrong key rule shows up
-- here as lost lines instead of passing unnoticed.
select
    source_lines.n as source_rows,
    silver_lines.n as silver_rows
from (select count(*) as n from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_detail') }}) as source_lines
cross join (select count(*) as n from {{ ref('slv_adventure_works_sales__sales_order_detail') }}) as silver_lines
where source_lines.n != silver_lines.n
