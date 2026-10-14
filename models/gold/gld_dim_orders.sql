{{
    config(
        materialized='incremental',
        unique_key='sales_order_id',
        incremental_strategy='merge',
        alias='adw_dim_orders'
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

select s.*

from {{ ref('slv_dim_adventure_works_sales__sales_order_header_join_detail') }} as s

{% if is_incremental() %}
where s.order_modified_date > (select coalesce(max(order_modified_date), '1900-01-01') from {{ this }})
{% endif %}
