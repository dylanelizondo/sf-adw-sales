{{
    config(
        materialized='incremental',
        unique_key='sales_order_id',
        incremental_strategy='merge',
        alias='dim_orders'
    )
}}

-- dim_orders
-- ONE row per sales order. Row count equals
-- slv_dim_adventure_works_sales__sales_order_header_join_detail, enforced by
-- tests/gold/dim_orders__row_count_matches_silver.sql.
--
-- Reads from slv_dim_adventure_works_sales__sales_order_header_join_detail, which already
-- joins the order header (recovered straight from bronze) to its aggregated line metrics.
-- Straight select -- gold adds nothing, not even a key: sales_order_id is the natural key
-- and is used as-is.
--
-- Type 1: merge keyed on sales_order_id, so a changed order overwrites its existing row
-- in place -- no history is kept here. On incremental runs only orders modified since the
-- last run are re-selected (watermarked on order_modified_date); see the dbt incremental-
-- strategy docs: https://docs.getdbt.com/docs/build/incremental-strategy

select 
    {{ dbt_utils.generate_surrogate_key(['sales_order_id']) }} as store_key,
    s.sales_order_id,

    -- identifiers -----------------------------------------------------------
    s.sales_order_number,
    s.purchase_order_number,
    s.account_number,
    s.revision_number,

    -- dates -------------------------------------------------------------------
    s.order_date,
    s.due_date,
    s.ship_date,
    s.is_shipped,

    -- status and channel ----------------------------------------------------
    s.order_status_code,
    s.order_status_label,
    s.is_online_order,
    s.order_channel,

    -- foreign keys ------------------------------------------------------------
    s.customer_id,
    s.sales_person_id,
    s.territory_id,
    s.bill_to_address_id,
    s.ship_to_address_id,
    s.ship_method_id,
    s.credit_card_id,
    s.currency_rate_id,

    -- amounts -----------------------------------------------------------------
    s.sub_total,
    s.tax_amt,
    s.freight,
    s.total_due,

    -- order-level line metrics --------------------------------------------------
    s.order_line_count,
    s.order_total_qty,
    s.order_total_revenue,

    -- audit -------------------------------------------------------------------
    s.order_modified_date

from {{ ref('slv_dim_adventure_works_sales__sales_order_header_join_detail') }} as s

{% if is_incremental() %}
where s.order_modified_date > (select coalesce(max(order_modified_date), '1900-01-01') from {{ this }})
{% endif %}
