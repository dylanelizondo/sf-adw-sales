-- slv_dim_adventure_works_sales__sales_order_header_join_detail
-- ONE row per sales order. Reads straight from BRONZE: recovers the corrupted order key,
-- casts amounts, decodes status and channel, and joins in the lines -- aggregated
-- down to one row per order (line count, units, revenue) -- all in one model, so gold
-- needs nothing but a straight select.
--
-- sales_order_id is the key, recovered via recover_sales_order_id. No surrogate key
-- is minted here -- the recovered natural key is unique and reproducible on its own.
--
-- Dates are NOT converted here: order_date, due_date and ship_date are already DATE in
-- bronze, and modified_date is TIMESTAMP_NTZ and is kept as a timestamp.
{{ config(alias="adw_sales_sales_order_header_join_detail") }}

select
    -- keys ----------------------------------------------------------------
    {{ recover_sales_order_id('h.sales_order_id') }}                       as sales_order_id,

    -- identifiers -----------------------------------------------------------
    trim(h.sales_order_number)                                            as sales_order_number,
    trim(h.purchase_order_number)                                         as purchase_order_number,
    trim(h.account_number)                                                as account_number,
    h.revision_number::number(38,0)                                       as revision_number,

    -- dates -------------------------------------------------------------------
    h.order_date                                                          as order_date,
    h.due_date                                                            as due_date,
    h.ship_date                                                           as ship_date,
    h.ship_date is not null                                               as is_shipped,

    -- status and channel ----------------------------------------------------
    h.status::number(38,0)                                                as order_status_code,
    case h.status::number(38,0)
        when 1 then 'In process'
        when 2 then 'Approved'
        when 3 then 'Backordered'
        when 4 then 'Rejected'
        when 5 then 'Shipped'
        when 6 then 'Cancelled'
        else null
    end                                                                    as order_status_label,
    case h.online_order_flag::number(38,0)
        when 1 then true
        when 0 then false
        else null
    end                                                                    as is_online_order,
    case h.online_order_flag::number(38,0)
        when 1 then 'Online'
        when 0 then 'Salesperson'
        else null
    end                                                                    as order_channel,

    -- foreign keys ------------------------------------------------------------
    h.customer_id::number(38,0)                                           as customer_id,
    h.sales_person_id::number(38,0)                                       as sales_person_id,
    h.territory_id::number(38,0)                                          as territory_id,
    h.bill_to_address_id::number(38,0)                                    as bill_to_address_id,
    h.ship_to_address_id::number(38,0)                                    as ship_to_address_id,
    h.ship_method_id::number(38,0)                                        as ship_method_id,
    h.credit_card_id::number(38,0)                                        as credit_card_id,
    h.currency_rate_id::number(38,0)                                      as currency_rate_id,

    -- amounts -----------------------------------------------------------------
    h.sub_total::number(19,4)                                             as sub_total,
    h.tax_amt::number(19,4)                                               as tax_amt,
    h.freight::number(19,4)                                               as freight,
    h.total_due::number(19,4)                                             as total_due,

    -- order-level line metrics --------------------------------------------------
    coalesce(l.order_line_count, 0)                                       as order_line_count,
    coalesce(l.order_total_qty, 0)                                        as order_total_qty,
    coalesce(l.order_total_revenue, 0)                                    as order_total_revenue,

    -- audit -------------------------------------------------------------------
    h.modified_date                                                       as order_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header') }} as h
left join (
    select
        {{ recover_sales_order_id('sales_order_id') }}      as sales_order_id,
        count(*)                                            as order_line_count,
        sum(order_qty::number(38,0))                        as order_total_qty,
        sum(line_total::number(38,6))                       as order_total_revenue
    from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_detail') }}
    where try_to_number(trim(sales_order_detail_id::varchar)) is not null
      and {{ recover_sales_order_id('sales_order_id') }} is not null
    group by 1
) as l
    on {{ recover_sales_order_id('h.sales_order_id') }} = l.sales_order_id

where {{ recover_sales_order_id('h.sales_order_id') }} is not null