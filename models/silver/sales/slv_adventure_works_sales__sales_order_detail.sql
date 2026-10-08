-- slv_adventure_works_sales__sales_order_detail
-- ONE row per sales order line. Grain matches the source PK (sales_order_detail_id).
--
-- Order lines with product, quantity, price and discount. Cleaned and typed only: the
-- corrupted order key is recovered and numbers and dates are cast. LINE_TOTAL reconciles
-- with the source, so it is kept as delivered and NEVER recomputed here;
-- tests/silver/..._line_total_reconciles.sql proves it still adds up. No business logic;
-- that belongs in gold.
--
-- The row count must equal bronze (tests/silver/..._row_count_matches_source.sql), so a
-- wrong key recovery shows up as lost lines.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(try_to_number(trim(sales_order_detail_id::varchar)) as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))     as sales_order_detail_key,
    try_to_number(trim(sales_order_detail_id::varchar))::number(38,0)    as sales_order_detail_id,
    {{ recover_sales_order_id('sales_order_id') }}                       as sales_order_id,

    -- product and promotion -------------------------------------------------
    product_id::number(38,0)                                             as product_id,
    special_offer_id::number(38,0)                                       as special_offer_id,
    trim(carrier_tracking_number)                                        as carrier_tracking_number,

    -- quantity and price ------------------------------------------------------
    order_qty::number(38,0)                                              as order_qty,
    unit_price::number(19,4)                                             as unit_price,
    unit_price_discount::number(19,4)                                    as unit_price_discount,
    -- Kept as delivered by the source; see the header comment.
    line_total::number(38,6)                                             as line_total,

    -- audit -----------------------------------------------------------------
    rowguid                                                              as rowguid,
    {{ to_silver_date('modified_date') }}                                as modified_date,
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                            as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__sales_order_detail") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_detail') }}
where try_to_number(trim(sales_order_detail_id::varchar)) is not null
  and {{ recover_sales_order_id('sales_order_id') }} is not null
