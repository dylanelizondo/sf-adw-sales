-- slv_adventure_works_sales__store
-- ONE row per store. 701 = Sales.Store. THIS ROW COUNT IS THE CONTRACT, enforced by
-- tests/silver/slv_adventure_works_sales__store_row_count_matches_source.sql.
--
-- Reseller stores that buy from AdventureWorks. store_key is minted HERE from
-- business_entity_id so gold never has to recompute it.
--
-- demographics is the StoreSurvey XML, answered by every store (confirmed: 701/701
-- non-null). Shredded below into store_* columns so gold doesn't carry XML parsing.
-- One row per store already, so no CTE or join is needed to pull it off.

select
    -- keys ----------------------------------------------------------------
    -- Same md5-of-varchar construction as adw_core's person_key, so a surrogate
    -- key built the same way means the same thing anywhere in the mesh.
    md5(cast(coalesce(cast(business_entity_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as store_key,
    business_entity_id,

    -- identity --------------------------------------------------------------
    name as store_name,
    sales_person_id,

    -- demographics: StoreSurvey XML, shredded -------------------------------
    try_to_decimal(xmlget(parse_xml(demographics), 'AnnualSales'     ):"$"::varchar, 18, 2) as store_annual_sales,
    try_to_decimal(xmlget(parse_xml(demographics), 'AnnualRevenue'   ):"$"::varchar, 18, 2) as store_annual_revenue,
    xmlget(parse_xml(demographics), 'BankName'        ):"$"::varchar as store_bank_name,
    xmlget(parse_xml(demographics), 'BusinessType'    ):"$"::varchar as store_business_type,
    try_to_number(xmlget(parse_xml(demographics), 'YearOpened'      ):"$"::varchar) as store_year_opened,
    xmlget(parse_xml(demographics), 'Specialty'       ):"$"::varchar as store_specialty,
    try_to_number(xmlget(parse_xml(demographics), 'SquareFeet'      ):"$"::varchar) as store_square_feet,

    -- NOT numeric: the source carries "4+" alongside "2" and "3". Never cast.
    xmlget(parse_xml(demographics), 'Brands'          ):"$"::varchar as store_brand_count,

    xmlget(parse_xml(demographics), 'Internet'        ):"$"::varchar as store_internet_connection_type,
    try_to_number(xmlget(parse_xml(demographics), 'NumberEmployees' ):"$"::varchar) as store_number_employees,

    -- audit -------------------------------------------------------------
    try_to_timestamp(modified_date) as store_modified_date

from {{ ref('SALES_Bronze') }}
