-- dim_orders
-- ONE row per sales order. 31,465 = Sales.SalesOrderHeader. THIS ROW COUNT IS THE CONTRACT.
--
-- Gold dimension for sales orders. Grain: one row per order (sales_order_id).
-- Carries the order header attributes plus three pre-aggregated line metrics
-- (total lines, total units, total revenue) so BI dashboards can answer
-- order-level questions without joining to FACT_ORDER_LINE.
--
-- Individual order lines live in FACT_ORDER_LINE (#28); join on order_key
-- when line-level detail is needed.
--
-- Derived attributes:
--   order_channel : ONLINE / OFFLINE from online_order_flag
--   order_status_label : human-readable label from the status code (1-6)
--   is_shipped : true when ship_date is not null
--
-- All dates arrive as VARCHAR from the source and are cast here.
-- Monetary columns arrive as FLOAT/NUMBER and are cast to DECIMAL(18,2).

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(h.sales_order_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as order_key,
    h.sales_order_id,

    -- order identifiers ---------------------------------------------------
    h.sales_order_number,
    h.purchase_order_number,
    h.account_number,
    h.revision_number,

    -- dates ---------------------------------------------------------------
    try_to_date(h.order_date)                    as order_date,
    try_to_date(h.due_date)                      as due_date,
    try_to_date(h.ship_date)                     as ship_date,
    (h.ship_date is not null)                    as is_shipped,

    -- status --------------------------------------------------------------
    h.status::integer                            as order_status,
    case h.status::integer
        when 1 then 'In Process'
        when 2 then 'Approved'
        when 3 then 'Backordered'
        when 4 then 'Rejected'
        when 5 then 'Shipped'
        when 6 then 'Cancelled'
        else 'Unknown'
    end                                          as order_status_label,

    -- channel -------------------------------------------------------------
    h.online_order_flag::boolean                 as online_order_flag,
    case h.online_order_flag::integer
        when 1 then 'ONLINE'
        else        'OFFLINE'
    end                                          as order_channel,

    -- foreign keys --------------------------------------------------------
    h.customer_id,
    h.sales_person_id,
    h.territory_id,
    h.bill_to_address_id,
    h.ship_to_address_id,
    h.ship_method_id,
    h.credit_card_id,
    h.currency_rate_id,

    -- amounts -------------------------------------------------------------
    cast(h.sub_total   as decimal(18, 2))        as sub_total,
    cast(h.tax_amt     as decimal(18, 2))        as tax_amt,
    cast(h.freight     as decimal(18, 2))        as freight,
    cast(h.total_due   as decimal(18, 2))        as total_due,

    -- pre-aggregated line metrics (avoids FACT_ORDER_LINE join for order KPIs)
    coalesce(agg.line_count,    0)               as order_line_count,
    coalesce(agg.total_qty,     0)               as order_total_qty,
    cast(coalesce(agg.total_revenue, 0)
         as decimal(18, 2))                      as order_total_revenue,

    -- comment -------------------------------------------------------------
    h.comment                                    as order_comment,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(h.modified_date)            as order_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header') }} as h
left join (
    select
        sales_order_id,
        count(*)                    as line_count,
        sum(order_qty)              as total_qty,
        sum(line_total)             as total_revenue
    from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_detail') }}
    group by sales_order_id
) as agg
    on h.sales_order_id = agg.sales_order_id
