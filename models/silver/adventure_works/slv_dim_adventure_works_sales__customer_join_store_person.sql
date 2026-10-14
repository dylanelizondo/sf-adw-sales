-- slv_dim_adventure_works_sales__customer_join_store_person
-- ONE row per customer. Row count equals slv_adventure_works_sales__customer (19,820), enforced by
-- tests/silver/slv_dim_adventure_works_sales__customer_join_store_person__row_count_matches_customer.sql.
--
-- Silver model that prepares dim_client: the joins a gold dimension needs live here, so gold can
-- select from it without joins. The customer is joined to its store (store name) and, for individual
-- customers, to the person (display name). Natural key only (customer_id); no surrogate key.
--
-- The store name comes from the bronze store view (its XML is already flattened there). Attributes that
-- come from the person survey XML (age band, education, occupation, ...) are not carried here: they come
-- back once that XML is flattened in bronze too.
-- Both joined keys have exactly one row per business_entity_id, so the joins cannot fan out.
{{ config(alias="adw_sales_customer_join_store_person") }}

select
    -- key -------------------------------------------------------------------
    c.customer_id,

    -- customer ----------------------------------------------------------------
    c.customer_type,
    coalesce(
        case c.customer_type
            when 'STORE'      then s.name
            when 'INDIVIDUAL' then p.person_full_name
        end,
        'Unknown'
    )                                           as customer_name,
    c.account_number,

    -- foreign keys ------------------------------------------------------------
    c.store_id,
    c.person_id,
    c.territory_id,

    -- audit -------------------------------------------------------------------
    c.customer_modified_date

from {{ ref('slv_adventure_works_sales__customer') }} as c
left join {{ ref('adw_core', 'brz_adventure_works_sales__store') }} as s
    on c.store_id = s.business_entity_id
left join {{ ref('adw_core', 'slv_adventure_works_person__person') }} as p
    on c.person_id = p.business_entity_id
   and c.customer_type = 'INDIVIDUAL'
