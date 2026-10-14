-- slv_dim_adventure_works_sales__customer_join_store_person
-- ONE row per customer. Row count equals bronze Sales.Customer (19,820), enforced by
-- tests/silver/slv_dim_adventure_works_sales__customer_join_store_person__row_count_matches_customer.sql.
--
-- Reads straight from BRONZE, same as slv_dim_adventure_works_sales__store_join_person: resolves
-- the customer_type ambiguity (PERSON_ID and STORE_ID are meant to be mutually exclusive; 635 rows
-- carry both -- those are treated as STORE customers because the store relationship is the
-- authoritative sales entity), then joins the customer to its store (store name) and, for
-- individual customers, to the person (display name). Natural key only (customer_id); no
-- surrogate key.
--
-- The store name comes from the bronze store view (its XML is already flattened there). Attributes
-- that come from the person survey XML (age band, education, occupation, ...) are not carried
-- here: they come back once that XML is flattened in bronze too.
-- Both joined keys have exactly one row per business_entity_id, so the joins cannot fan out.
{{ config(alias="adw_sales_customer_join_store_person") }}

select
    -- key -------------------------------------------------------------------
    c.customer_id,

    -- customer ----------------------------------------------------------------
    case
        when c.store_id  is not null then 'STORE'
        when c.person_id is not null then 'INDIVIDUAL'
        else 'UNKNOWN'
    end                                           as customer_type,
    coalesce(
        case
            when c.store_id  is not null then s.name
            when c.person_id is not null then p.person_full_name
        end,
        'Unknown'
    )                                             as customer_name,
    c.account_number,

    -- foreign keys ------------------------------------------------------------
    c.store_id,
    c.person_id,
    c.territory_id,

    -- audit -------------------------------------------------------------------
    try_to_timestamp(c.modified_date)              as customer_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__customer') }} as c
left join {{ ref('adw_core', 'brz_adventure_works_sales__store') }} as s
    on c.store_id = s.business_entity_id
left join {{ ref('adw_core', 'slv_adventure_works_person__person') }} as p
    on c.person_id = p.business_entity_id
   and c.store_id is null
