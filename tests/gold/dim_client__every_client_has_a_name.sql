-- client_name falls back to 'Unknown' when no store name or person name is available. A row returned
-- here is a client with no usable name: a customer typed UNKNOWN, a store without a name, or a person
-- missing from slv_adventure_works_person__person. The fallback itself can never be null, so a not_null test would not catch it.
select
    customer_id,
    client_type
from {{ ref('gld_dim_client') }}
where client_name = 'Unknown'
