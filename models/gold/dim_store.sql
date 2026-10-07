-- dim_store
-- ONE row per reseller store. 701 = Sales.Store. THIS ROW COUNT IS THE CONTRACT.
--
-- Gold dimension for the reseller channel. Joins the store record to the
-- assigned salesperson's identity (resolved from slv_person) so BI never
-- needs to re-join those tables downstream.
--
-- store_key is minted here and is the join target for fact tables that
-- reference a store.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(s.business_entity_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as store_key,
    s.business_entity_id                                              as store_id,

    -- store attributes ----------------------------------------------------
    s.name                                                            as store_name,

    -- salesperson (resolved via slv_person) --------------------------------
    s.sales_person_id,
    p.person_key                                                      as sales_person_key,
    p.person_full_name                                                as sales_person_full_name,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(s.modified_date)                                 as store_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__store') }}         as s
left join {{ ref('adw_core', 'slv_person') }}                          as p
    on s.sales_person_id = p.business_entity_id
