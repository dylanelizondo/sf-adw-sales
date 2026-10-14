-- customer_name falls back to 'Unknown' when no store name or person name is available. A row returned
-- here is a customer with no usable name: a customer typed UNKNOWN, a store without a name, or a person
-- missing from the person model. The fallback itself can never be null, so a not_null test would not catch it.
select
    customer_id,
    customer_type
from {{ ref('slv_dim_adventure_works_sales__customer_join_store_person') }}
where customer_name = 'Unknown'
