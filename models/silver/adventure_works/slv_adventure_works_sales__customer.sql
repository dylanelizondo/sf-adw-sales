-- slv_customer
-- ONE row per customer. 19,820 = Sales.Customer. THIS ROW COUNT IS THE CONTRACT.
--
-- Resolves the customer_type ambiguity: PERSON_ID and STORE_ID are meant to be mutually
-- exclusive in practice (635 rows carry both in the source — those are treated
-- as STORE customers because the store relationship is the authoritative sales
-- entity). account_number is surfaced as-is; it is derived by the source system
-- and carries no transformation here.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(customer_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as customer_key,
    customer_id,

    -- foreign keys --------------------------------------------------------
    person_id,
    store_id,
    territory_id,

    -- derived attribute ---------------------------------------------------
    -- STORE wins when both IDs are present (635 ambiguous rows).
    -- NULL person_id with NULL store_id is theoretically impossible in the
    -- source constraints but handled defensively.
    case
        when store_id  is not null then 'STORE'
        when person_id is not null then 'INDIVIDUAL'
        else 'UNKNOWN'
    end as customer_type,

    -- account_number: derived in the source system and ambiguous (issue #34), kept as-is.
    account_number,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(modified_date) as customer_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__customer') }}
