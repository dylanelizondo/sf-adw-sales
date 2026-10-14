-- slv_dim_adventure_works_sales__store_join_person
-- ONE row per store. 701 = Sales.Store. THIS ROW COUNT IS THE CONTRACT, enforced by
-- tests/silver/slv_dim_adventure_works_sales__store_join_person_row_count_matches_source.sql.
--
-- Reseller stores that buy from AdventureWorks. No surrogate key is minted here --
-- store_id (business_entity_id) is the natural key; gold mints its own store_key.
--
-- demographics is the StoreSurvey XML, pre-shredded upstream into demographics_*
-- columns. Renamed below into store_* so gold doesn't carry the raw survey names.
-- One row per store already, so no CTE or join is needed to pull it off.
{{config(alias="adw_sales_store_join_person")}}

select
    -- keys ----------------------------------------------------------------
    s.business_entity_id as store_id,

    -- identity --------------------------------------------------------------
    name as store_name,

    -- demographics: StoreSurvey XML, shredded -------------------------------
    demographics_annual_sales as store_annual_sales,
    demographics_annual_revenue as store_annual_revenue,
    demographics_bank_name as store_bank_name,
    demographics_business_type as store_business_type,
    demographics_year_opened as store_year_opened,
    demographics_specialty as store_specialty,
    demographics_square_feet as store_square_feet,

    -- NOT numeric: the source carries "4+" alongside "2" and "3". Never cast.
    demographics_brand_count as store_brand_count,

    demographics_internet_connection_type as store_internet_connection_type,
    demographics_number_employees as store_number_employees,

    -- assigned salesperson --------------------------------------------------
    s.sales_person_id,
    p.person_key                            as sales_person_key,
    p.person_full_name                      as sales_person_full_name,

    -- audit -------------------------------------------------------------
    modified_date as store_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__store') }} as s
left join {{ ref('adw_core', 'slv_adventure_works_person__person') }} as p
    on s.sales_person_id = p.business_entity_id
