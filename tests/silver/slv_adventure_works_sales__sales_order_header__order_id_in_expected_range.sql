-- Recovered order ids must fall in the AdventureWorks range (43659 to 75123). A row returned
-- here means recover_sales_order_id produced a number that is not an order id, so the key
-- rule is wrong even if the keys are unique and not null.
select
    sales_order_id
from {{ ref('slv_adventure_works_sales__sales_order_header') }}
where sales_order_id < 43659
   or sales_order_id > 75123
