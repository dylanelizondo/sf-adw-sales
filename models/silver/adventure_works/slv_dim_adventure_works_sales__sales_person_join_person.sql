-- slv_dim_adventure_works_sales__sales_person_join_person
-- ONE row per salesperson. 17 = SALES.SALES_PERSON. THIS ROW COUNT IS THE CONTRACT,
-- enforced by tests/silver/slv_dim_adventure_works_sales__sales_person_join_person__row_count_matches_source.sql.
--
-- Resolves the salesperson's display name from adw_core's slv_adventure_works_person__person,
-- same pattern as slv_dim_adventure_works_sales__store_join_person, so gold doesn't need a
-- join to get a name. business_entity_id (same as slv_adventure_works_sales__sales_person) is
-- the natural key -- no surrogate key is minted here, gold mints its own sales_person_key.
{{ config(alias="stg_dim_sales_person_join_person") }}

select
    -- keys ----------------------------------------------------------------
    sp.business_entity_id,

    -- identity ----------------------------------------------------------------
    p.person_full_name as sales_person_full_name,

    -- foreign keys ------------------------------------------------------------
    sp.territory_id,

    -- performance ---------------------------------------------------------------
    sp.sales_quota,
    sp.bonus,
    sp.commission_pct,
    sp.sales_ytd,
    sp.sales_last_year,

    -- audit -------------------------------------------------------------------
    sp.modified_date as sales_person_modified_date

from {{ ref('slv_adventure_works_sales__sales_person') }} as sp
left join {{ ref('adw_core', 'slv_adventure_works_person__person') }} as p
    on sp.business_entity_id = p.business_entity_id
