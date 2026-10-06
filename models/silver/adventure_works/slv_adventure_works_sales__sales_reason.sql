-- slv_sales_reason
-- ONE row per sales reason. Grain matches the source PK (salesreasonid).
--
-- The source columns are NOT in snake_case (salesreasonid, reasontype, modifieddate);
-- this model aligns them to the project convention. Bronze preserves the source names
-- as-is; the rename lives here and only here.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(salesreasonid as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as sales_reason_key,
    salesreasonid as sales_reason_id,

    -- attributes ----------------------------------------------------------
    name          as sales_reason_name,
    reasontype    as reason_type,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(modifieddate) as sales_reason_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_reason') }}
