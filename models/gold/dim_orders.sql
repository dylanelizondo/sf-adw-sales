-- dim_orders
-- ONE row per sales order. Row count equals slv_adventure_works_sales__sales_order_header,
-- enforced by tests/gold/dim_orders__row_count_matches_silver.sql.
--
-- Reads from SILVER, never from bronze: the order key arrives corrupted in bronze and is
-- recovered once in silver (recover_sales_order_id). Re-deriving it here would risk keys
-- that no longer join to the order lines.
--
-- Carries the header attributes plus three order-level line metrics (line count, units,
-- revenue) so order KPIs need no join to the order lines. The aggregation sits in a
-- subquery with one row per order, so the left join cannot fan out the header.

select
    -- keys ----------------------------------------------------------------
    h.sales_order_key                       as order_key,
    h.sales_order_id,

    -- identifiers -----------------------------------------------------------
    h.sales_order_number,
    h.purchase_order_number,
    h.account_number,
    h.revision_number,

    -- dates -------------------------------------------------------------------
    h.order_date,
    h.due_date,
    h.ship_date,
    h.ship_date is not null                 as is_shipped,

    -- status and channel (decoded in silver) ----------------------------------
    h.status_code                           as order_status_code,
    h.status_label                          as order_status_label,
    h.is_online_order,
    h.order_channel_label                   as order_channel,

    -- foreign keys ------------------------------------------------------------
    h.customer_id,
    h.sales_person_id,
    h.territory_id,
    h.bill_to_address_id,
    h.ship_to_address_id,
    h.ship_method_id,
    h.credit_card_id,
    h.currency_rate_id,

    -- amounts -----------------------------------------------------------------
    h.sub_total,
    h.tax_amt,
    h.freight,
    h.total_due,

    -- order-level line metrics --------------------------------------------------
    coalesce(l.order_line_count, 0)         as order_line_count,
    coalesce(l.order_total_qty, 0)          as order_total_qty,
    coalesce(l.order_total_revenue, 0)      as order_total_revenue,

    -- audit -------------------------------------------------------------------
    h.modified_date                         as order_modified_date

from {{ ref('slv_adventure_works_sales__sales_order_header') }} as h
left join (
    select
        sales_order_id,
        count(*)        as order_line_count,
        sum(order_qty)  as order_total_qty,
        sum(line_total) as order_total_revenue
    from {{ ref('slv_adventure_works_sales__sales_order_detail') }}
    group by sales_order_id
) as l
    on h.sales_order_id = l.sales_order_id
