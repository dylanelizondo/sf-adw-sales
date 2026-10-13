-- slv_adventure_works_sales__sales_order_header_sales_reason
-- ONE row per (sales order, sales reason). Grain matches the source composite PK.
--
-- Bridge between sales orders and the reasons recorded for the purchase; an order can carry
-- several reasons. Cleaned and typed only: the corrupted order key is recovered, the reason
-- key and date are cast. No business logic; that belongs in gold.
--
-- Uniqueness of the pair is enforced by unique_combination_of_columns in the YAML, and the row
-- count must equal bronze (tests/silver/..._row_count_matches_source.sql).

select
    -- keys ----------------------------------------------------------------
    -- Surrogate key over the pair, same construction as dbt_utils.generate_surrogate_key.
    md5(cast(
            coalesce(cast({{ recover_sales_order_id('sales_order_id') }} as varchar), '_dbt_utils_surrogate_key_null_')
            || '-' ||
            coalesce(cast(try_to_number(trim(sales_reason_id::varchar)) as varchar), '_dbt_utils_surrogate_key_null_')
        as varchar))                                                     as sales_order_sales_reason_key,
    {{ recover_sales_order_id('sales_order_id') }}                       as sales_order_id,
    try_to_number(trim(sales_reason_id::varchar))::number(38,0)          as sales_reason_id,

    -- audit -----------------------------------------------------------------
    {{ to_silver_date('modified_date') }}                                as modified_date,
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                            as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__sales_order_header_sales_reason") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header_sales_reason') }}
where {{ recover_sales_order_id('sales_order_id') }} is not null
  and try_to_number(trim(sales_reason_id::varchar)) is not null
