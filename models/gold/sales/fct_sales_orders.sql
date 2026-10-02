select
    -- Surrogate / Natural Keys
    d.sales_order_detail_id                                                as sales_order_detail_id,
    h.sales_order_id                                                       as sales_order_id,
    h.customer_id                                                          as customer_id,
    coalesce(h.sales_person_id, -1)                                        as sales_person_id,
    coalesce(h.territory_id, -1)                                           as territory_id,
    d.product_id                                                           as product_id,
    coalesce(d.special_offer_id, 1)                                        as special_offer_id,
    h.bill_to_address_id                                                   as bill_to_address_id,
    h.ship_to_address_id                                                   as ship_to_address_id,
    h.ship_method_id                                                       as ship_method_id,
    coalesce(h.credit_card_id, -1)                                         as credit_card_id,
    coalesce(h.currency_rate_id, -1)                                       as currency_rate_id,

    -- Order Document Info
    h.sales_order_number                                                   as sales_order_number,
    coalesce(h.purchase_order_number, 'N/A')                               as purchase_order_number,
    coalesce(h.account_number, 'N/A')                                      as account_number,
    coalesce(d.carrier_tracking_number, 'N/A')                             as carrier_tracking_number,
    h.revision_number                                                      as revision_number,

    -- Status & Channel Dimensions
    h.status_code                                                          as order_status_code,
    h.status_label                                                         as order_status_label,
    h.online_order_flag_code                                               as online_order_flag_code,
    h.is_online_order                                                      as is_online_order,
    h.order_channel_label                                                  as order_channel_label,

    -- Date Dimensions
    h.order_date                                                           as order_date,
    h.due_date                                                             as due_date,
    h.ship_date                                                            as ship_date,
    case
        when h.ship_date is not null and h.order_date is not null
        then datediff('day', h.order_date, h.ship_date)
        else null
    end                                                                    as days_to_ship,
    case
        when h.ship_date is not null and h.due_date is not null
        then (h.ship_date <= h.due_date)
        else null
    end                                                                    as is_shipped_on_time,

    -- Quantities & Unit Amounts
    d.order_qty                                                            as order_quantity,
    d.unit_price                                                           as unit_price_amount,
    d.unit_price_discount                                                  as unit_price_discount_rate,
    (d.order_qty * d.unit_price)::number(19,4)                             as gross_line_amount,
    (d.order_qty * d.unit_price * d.unit_price_discount)::number(19,4)     as discount_amount,
    d.line_total::number(19,4)                                             as net_line_amount,

    -- Allocated Order-Level Amounts (Allocated by Line Weight in Order Subtotal)
    case
        when coalesce(h.sub_total, 0) > 0
        then ((d.line_total / h.sub_total) * h.tax_amt)::number(19,4)
        else 0::number(19,4)
    end                                                                    as allocated_tax_amount,
    case
        when coalesce(h.sub_total, 0) > 0
        then ((d.line_total / h.sub_total) * h.freight)::number(19,4)
        else 0::number(19,4)
    end                                                                    as allocated_freight_amount,
    case
        when coalesce(h.sub_total, 0) > 0
        then (d.line_total + ((d.line_total / h.sub_total) * (h.tax_amt + h.freight)))::number(19,4)
        else d.line_total::number(19,4)
    end                                                                    as allocated_total_line_amount,

    -- Audit Metadata
    current_timestamp()                                                    as _loaded_at
from {{ ref('slv_adventure_works_sales__sales_order_header') }} h
inner join {{ ref('slv_adventure_works_sales__sales_order_detail') }} d
    on h.sales_order_id = d.sales_order_id
