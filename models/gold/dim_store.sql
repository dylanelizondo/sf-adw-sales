-- dim_store
-- ONE row per reseller store. Row count equals slv_adventure_works_sales__store (701),
-- enforced by tests/gold/dim_store__row_count_matches_silver.sql.
--
-- Reads from SILVER: store_key is minted there and inherited here, and the StoreSurvey
-- XML is already shredded. The only thing added is the assigned salesperson's identity
-- from adw_core's slv_person, so BI joins one dimension instead of two.
-- slv_person has exactly one row per business_entity_id, so the join cannot fan out.

select
    -- keys ----------------------------------------------------------------
    s.store_key,
    s.business_entity_id                    as store_id,

    -- store ---------------------------------------------------------------
    s.store_name,
    s.store_business_type,
    s.store_specialty,
    s.store_year_opened,
    s.store_square_feet,
    s.store_number_employees,
    s.store_brand_count,
    s.store_internet_connection_type,
    s.store_bank_name,
    s.store_annual_sales,
    s.store_annual_revenue,

    -- assigned salesperson --------------------------------------------------
    s.sales_person_id,
    p.person_key                            as sales_person_key,
    p.person_full_name                      as sales_person_full_name,

    -- audit -----------------------------------------------------------------
    s.store_modified_date

from {{ ref('slv_adventure_works_sales__store') }} as s
left join {{ ref('adw_core', 'slv_person') }} as p
    on s.sales_person_id = p.business_entity_id
