-- slv_adventure_works_sales__sales_order_header
-- ONE row per sales order. Grain matches the source PK (sales_order_id).
--
-- Header of sales orders. Cleaned and typed only: the corrupted order key is recovered,
-- dates and amounts are cast, status and channel codes are decoded next to the original
-- codes. COMMENT is dropped because it is 100% NULL in the source. No business logic;
-- that belongs in gold.
--
-- The row count must equal bronze (tests/silver/..._row_count_matches_source.sql): a
-- wrong key recovery would drop rows, and that test is what makes it loud.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast({{ recover_sales_order_id('sales_order_id') }} as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))     as sales_order_key,
    {{ recover_sales_order_id('sales_order_id') }}                       as sales_order_id,
    revision_number::number(38,0)                                        as revision_number,

    -- dates -----------------------------------------------------------------
    {{ to_silver_date('order_date') }}                                   as order_date,
    {{ to_silver_date('due_date') }}                                     as due_date,
    {{ to_silver_date('ship_date') }}                                    as ship_date,

    -- status and channel ----------------------------------------------------
    status::number(38,0)                                                 as status_code,
    case status::number(38,0)
        when 1 then 'In process'
        when 2 then 'Approved'
        when 3 then 'Backordered'
        when 4 then 'Rejected'
        when 5 then 'Shipped'
        when 6 then 'Cancelled'
        else null
    end                                                                  as status_label,
    online_order_flag::number(38,0)                                      as online_order_flag_code,
    case online_order_flag::number(38,0)
        when 1 then true
        when 0 then false
        else null
    end                                                                  as is_online_order,
    case online_order_flag::number(38,0)
        when 1 then 'Online'
        when 0 then 'Salesperson'
        else null
    end                                                                  as order_channel_label,

    -- identifiers -----------------------------------------------------------
    trim(sales_order_number)                                             as sales_order_number,
    trim(purchase_order_number)                                          as purchase_order_number,
    trim(account_number)                                                 as account_number,

    -- foreign keys ----------------------------------------------------------
    customer_id::number(38,0)                                            as customer_id,
    sales_person_id::number(38,0)                                        as sales_person_id,
    territory_id::number(38,0)                                           as territory_id,
    bill_to_address_id::number(38,0)                                     as bill_to_address_id,
    ship_to_address_id::number(38,0)                                     as ship_to_address_id,
    ship_method_id::number(38,0)                                         as ship_method_id,
    credit_card_id::number(38,0)                                         as credit_card_id,
    trim(credit_card_approval_code)                                      as credit_card_approval_code,
    currency_rate_id::number(38,0)                                       as currency_rate_id,

    -- amounts ---------------------------------------------------------------
    sub_total::number(19,4)                                              as sub_total,
    tax_amt::number(19,4)                                                as tax_amt,
    freight::number(19,4)                                                as freight,
    total_due::number(19,4)                                              as total_due,

    -- audit -----------------------------------------------------------------
    rowguid                                                              as rowguid,
    {{ to_silver_date('modified_date') }}                                as modified_date,
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                            as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__sales_order_header") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_order_header') }}
where {{ recover_sales_order_id('sales_order_id') }} is not null
