-- slv_dim_adventure_works_sales__sales_order_detail_join_header
-- ONE row per sales order line. Same grain and row count as
-- slv_adventure_works_sales__sales_order_detail. THIS ROW COUNT IS THE CONTRACT, enforced by
-- tests/silver/slv_dim_adventure_works_sales__sales_order_detail_join_header__row_count_matches_detail.sql.
--
-- Everything gold needs for the order-line fact in one place, so gold is a straight select: the
-- line itself (quantity, price, discount, line total), the header it belongs to (identifiers,
-- dates, status and channel, and the ids of customer, territory, addresses, salesperson and
-- credit card) and the reseller store behind the order's customer.
--
-- sales_order_id is unique in the header and customer_id in the customer (both tested), so
-- neither join can fan out. Both are left joins, so a line is never dropped: an id that cannot be
-- resolved stays null here and becomes a 'Missing' key in gold.
--
-- store_id comes from slv_adventure_works_sales__customer, where STORE wins over PERSON for the
-- 635 customers that carry both ids, so it is the same store dim_client reports. NULL when the
-- customer is an individual. Gold needs it to find the Type 2 dim_store version in force on the
-- order date.
--
-- product_id is carried so gold can point at ADW_PRODUCTION's gld_dim_product by surrogate key.
-- Not here on purpose: the order-level amounts (sub_total, tax_amt, freight, total_due), which
-- repeated on every line would multiply on a SUM.
--
-- Columns are listed one by one, not with a wildcard, so a column added to a source model has to
-- be added here before gold can see it.
{{ config(alias="stg_dim_adw_sales_sales_order_detail_join_header") }}

select
    -- keys ----------------------------------------------------------------
    d.sales_order_detail_key,
    d.sales_order_detail_id,
    d.sales_order_id,

    -- order identifiers (header) ------------------------------------------------
    h.sales_order_number,
    h.purchase_order_number,
    h.account_number,
    h.revision_number,

    -- order dates (header) ------------------------------------------------------
    h.order_date,
    h.due_date,
    h.ship_date,
    h.ship_date is not null                                               as is_shipped,

    -- status and channel (header) -----------------------------------------------
    h.status_code                                                         as order_status_code,
    h.status_label                                                        as order_status_label,
    h.is_online_order,
    h.order_channel_label                                                 as order_channel,

    -- foreign keys ----------------------------------------------------------------
    h.customer_id,
    h.sales_person_id,
    h.territory_id,
    h.bill_to_address_id,
    h.ship_to_address_id,
    h.credit_card_id,
    c.store_id,
    d.product_id,

    -- degenerate dimensions (no gold dimension built for these yet) --------------
    d.special_offer_id,
    h.ship_method_id,
    h.currency_rate_id,

    -- line measures -----------------------------------------------------------------
    d.order_qty,
    d.unit_price,
    d.unit_price_discount,
    d.line_total,

    -- audit -------------------------------------------------------------------
    -- latest change to the line or to its header: the incremental watermark of the gold fact
    coalesce(
        greatest(d.sales_order_detail_modified_date, h.sales_order_header_modified_date),
        d.sales_order_detail_modified_date
    )                                                                     as order_line_modified_date

from {{ ref('slv_adventure_works_sales__sales_order_detail') }} as d
left join {{ ref('slv_adventure_works_sales__sales_order_header') }} as h
    on d.sales_order_id = h.sales_order_id
left join {{ ref('slv_adventure_works_sales__customer') }} as c
    on h.customer_id = c.customer_id
