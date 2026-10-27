{{ config(alias="stg_dim_sales_order_detail_join_header") }}

select
    -- keys ----------------------------------------------------------------
    d.sales_order_detail_key,
    d.sales_order_detail_id,
    d.sales_order_id,

    -- order identifiers (from header) --------------------------------------
    h.sales_order_number,
    h.purchase_order_number,
    h.account_number,
    h.revision_number,

    -- dates -----------------------------------------------------------------
    h.order_date,
    h.due_date,
    h.ship_date,
    h.ship_date is not null as is_shipped,

    -- status and channel (from header) --------------------------------------
    h.status_code           as order_status_code,
    h.status_label          as order_status_label,
    h.is_online_order,
    h.order_channel_label   as order_channel,

    -- foreign keys ----------------------------------------------------------
    h.customer_id,
    h.sales_person_id,
    h.territory_id,
    h.bill_to_address_id,
    h.ship_to_address_id,
    h.credit_card_id,
    c.store_id,

    -- degenerate (no dimension yet) -----------------------------------------
    d.special_offer_id,
    h.ship_method_id,
    h.currency_rate_id,

    -- line measures ---------------------------------------------------------
    d.order_qty,
    d.unit_price,
    d.unit_price_discount,
    d.line_total,

    -- audit: incremental watermark of the fact. Falls back to the line date
    -- when the header is missing, so the line is never skipped.
    coalesce(greatest(d.modified_date, h.modified_date), d.modified_date) as order_item_modified_date

from {{ ref('slv_adventure_works_sales__sales_order_detail') }} as d
left join {{ ref('slv_adventure_works_sales__sales_order_header') }} as h
    on d.sales_order_id = h.sales_order_id
left join {{ ref('slv_adventure_works_sales__customer') }} as c
    on h.customer_id = c.customer_id