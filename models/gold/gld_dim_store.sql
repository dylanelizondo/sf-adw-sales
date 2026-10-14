-- dim_store
-- ONE row per reseller store. Row count equals slv_adventure_works_sales__store (701),
-- enforced by tests/gold/dim_store__row_count_matches_silver.sql.
--
-- Reads straight from SILVER: slv_store already shreds the StoreSurvey XML and resolves
-- the assigned salesperson's identity from adw_core's slv_person, so gold adds nothing
-- but the surrogate key.
--
-- store_key is an auto-incrementing row number, minted HERE because slv_store carries no
-- surrogate key of its own (only the natural key, store_id). row_number() is used instead
-- of a Snowflake SEQUENCE because this table is rebuilt with CREATE OR REPLACE on every
-- run -- a SEQUENCE would keep climbing across runs instead of restarting, so the key
-- would not be reproducible.

select
    -- keys ----------------------------------------------------------------
    row_number() over (order by s.store_id) as store_key,
    s.store_id,

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
    s.sales_person_key,
    s.sales_person_full_name,

    -- audit -----------------------------------------------------------------
    s.store_modified_date

from {{ ref('slv_adventure_works_sales__store') }} as s
