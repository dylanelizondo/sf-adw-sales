select *
from {{ ref('adw_core', 'brz_adventure_works_sales__store') }};