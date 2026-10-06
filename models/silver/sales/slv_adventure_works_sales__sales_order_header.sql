select
    -- Primary Key: trimmed and safely cast
    try_to_number(trim(sales_order_id::varchar))::number(38,0)     as sales_order_id,
    revision_number::number(38,0)                                    as revision_number,

    -- Order & Delivery Dates
    try_to_date(order_date)                                          as order_date,
    try_to_date(due_date)                                            as due_date,
    try_to_date(ship_date)                                           as ship_date,

    -- Order Status
    status::number(38,0)                                             as status_code,
    case status
        when 1 then 'In process'
        when 2 then 'Approved'
        when 3 then 'Backordered'
        when 4 then 'Rejected'
        when 5 then 'Shipped'
        when 6 then 'Cancelled'
        else 'Unknown'
    end                                                              as status_label,

    -- Channel Flags & Labels
    online_order_flag::number(38,0)                                  as online_order_flag_code,
    case online_order_flag
        when 1 then true
        when 0 then false
        else null
    end                                                              as is_online_order,
    case online_order_flag
        when 1 then 'Online'
        when 0 then 'Salesperson'
        else 'Unknown'
    end                                                              as order_channel_label,

    -- Document & Reference Numbers
    trim(sales_order_number)                                         as sales_order_number,
    trim(purchase_order_number)                                      as purchase_order_number,
    trim(account_number)                                             as account_number,

    -- Foreign Keys
    customer_id::number(38,0)                                        as customer_id,
    sales_person_id::number(38,0)                                    as sales_person_id,
    territory_id::number(38,0)                                       as territory_id,
    bill_to_address_id::number(38,0)                                 as bill_to_address_id,
    ship_to_address_id::number(38,0)                                 as ship_to_address_id,
    ship_method_id::number(38,0)                                     as ship_method_id,
    credit_card_id::number(38,0)                                     as credit_card_id,
    trim(credit_card_approval_code)                                  as credit_card_approval_code,
    currency_rate_id::number(38,0)                                   as currency_rate_id,

    -- Financial Amounts
    sub_total::number(19,4)                                          as sub_total,
    tax_amt::number(19,4)                                            as tax_amt,
    freight::number(19,4)                                            as freight,
    total_due::number(19,4)                                          as total_due,

    -- Metadata & Audit
    -- COMMENT is intentionally dropped: it is 100% NULL in the source.
    rowguid,
    try_to_date(modified_date)                                       as modified_date,
    current_timestamp()                                              as _loaded_at,
    'ADVENTURE_WORKS.SALES.SALES_ORDER_HEADER'                       as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header') }}
where try_to_number(trim(sales_order_id::varchar)) is not null
