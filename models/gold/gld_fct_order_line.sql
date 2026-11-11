{{ config(
    materialized='incremental',
    alias='fct_order_line',
    unique_key='sales_order_detail_id',
    incremental_strategy='merge'
) }}

with items as (
    select *
    from {{ ref('slv_dim_adventure_works_sales__sales_order_detail_join_header') }}
    {% if is_incremental() %}
    where order_item_modified_date >= (select max(order_item_modified_date) from {{ this }})
    {% endif %}
),

-- versiones de tienda: sin filas por defecto (store_id > 0)
store_versions as (
    select
        store_id,
        store_key,
        store_valid_from,
        to_date(store_valid_from) as valid_from_date
    from {{ ref('gld_dim_store') }}
    where store_id > 0
),

-- una búsqueda por (tienda, fecha de orden), no por línea
store_orders as (
    select distinct store_id, order_date
    from items
    where store_id is not null
),

-- exactamente una versión por (tienda, fecha de orden): version_rank = 1
chosen as (
    select
        so.store_id,
        so.order_date,
        v.store_key,
        row_number() over (
            partition by so.store_id, so.order_date
            order by
                case when v.valid_from_date <= so.order_date then 0 else 1 end,
                case when v.valid_from_date <= so.order_date then v.store_valid_from end desc nulls last,
                v.store_valid_from asc,
                v.store_key
        ) as version_rank
    from store_orders as so
    join store_versions as v on v.store_id = so.store_id
)

select
    -- llave y grano -------------------------------------------------------
    i.sales_order_detail_key as order_items_key,
    i.sales_order_detail_id,

    -- orden (degeneradas) -------------------------------------------------
    i.sales_order_id,
    i.sales_order_number,
    i.purchase_order_number,
    i.account_number,
    i.revision_number,

    -- fechas y estado -----------------------------------------------------
    i.order_date,
    i.due_date,
    i.ship_date,
    i.is_shipped,
    i.order_status_code,
    i.order_status_label,
    i.is_online_order,
    i.order_channel,

    -- foreign keys por key ------------------------------------------------
    {{ fact_foreign_key('customer_id') }}                                  as customer_key,
    {{ fact_foreign_key('territory_id') }}                                 as territory_key,
    {{ fact_foreign_key('bill_to_address_id') }}                           as bill_to_address_key,
    {{ fact_foreign_key('ship_to_address_id') }}                           as ship_to_address_key,
    {{ fact_foreign_key('sales_person_id', null_means='not_applicable') }} as sales_person_key,
    {{ fact_foreign_key('credit_card_id', null_means='not_applicable') }}  as credit_card_key,
    case
        when i.store_id is null then {{ default_row_key('not_applicable') }}
        when c.store_key is null then {{ default_row_key('missing') }}
        else c.store_key
    end                                                                    as store_key,

    -- degeneradas sin dimensión -------------------------------------------
    i.special_offer_id,
    i.ship_method_id,
    i.currency_rate_id,

    -- medidas -------------------------------------------------------------
    i.order_qty,
    i.unit_price,
    i.unit_price_discount,
    i.line_total,

    -- auditoría -----------------------------------------------------------
    i.order_item_modified_date

from items as i
left join chosen as c
    on  c.store_id     = i.store_id
    and c.order_date   = i.order_date
    and c.version_rank = 1