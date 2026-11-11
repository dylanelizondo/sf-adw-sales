{{
    config(
        materialized='incremental',
        unique_key='sales_order_detail_id',
        incremental_strategy='merge',
        alias='fct_order_line'
    )
}}

-- fct_order_line
-- ONE row per sales order line (sales_order_detail_id), plus one charge row per order with tax or
-- freight. Product rows equal
-- slv_dim_adventure_works_sales__sales_order_detail_join_header, enforced by
-- tests/gold/fct_order_line__row_count_matches_silver.sql.
--
-- Reads from slv_dim_adventure_works_sales__sales_order_detail_join_header, which already joins
-- each line to its order header and to the reseller store behind the order's customer. Gold adds
-- only the dimension keys. The primary key is the one silver already minted for the line
-- (sales_order_detail_key): inherited, never recomputed.
--
-- Star schema fact at order-line grain. FKs point only at conformed gold dimensions, never at
-- another fact, and always by SURROGATE KEY -- never by the natural id:
--   customer_key, territory_key, bill_to_address_key, ship_to_address_key,
--   sales_person_key, credit_card_key,
--   product_key                         Type 1 dimensions: the same hash the dimension mints over
--                                       the id (fact_foreign_key), so no join is needed.
--   store_key                           Type 2 dim_store: the store VERSION in force on order_date.
-- sales_person_key is the salesperson who processed the transaction. The store's own salesperson
-- (its account manager) stays an attribute of dim_store.
-- order_date/due_date/ship_date are FKs too, all three against adw_core's dim_date -- a
-- role-playing dimension whose grain is the literal calendar date, so the date is its own key.
-- special_offer_key, ship_method_key and currency_rate_key point at dim_special_offer,
-- dim_ship_method and dim_currency_rate by surrogate key. The order-charge row has no product, so
-- its special_offer_key is Not Applicable; an order sold in local currency has no exchange rate,
-- so its currency_rate_key is Not Applicable too.
-- product_key points at ADW_PRODUCTION's gld_dim_product (another dbt Mesh project): the same hash
-- that dimension mints over product_id. Its default rows use the same 'Missing' / 'Not Applicable'
-- key text as this project's dimensions (checked in ADW_GOLD_UAT.PRODUCTION.DIM_PRODUCT), so it
-- goes through fact_foreign_key() like the rest.
-- tax_amt and freight are order amounts. They are NOT repeated on every line (they would multiply
-- on a SUM): each order that has them gets ONE extra row (is_order_charge) whose product_key is
-- 'Not Applicable' and whose line measures are NULL; product lines carry them as NULL. The
-- charge row's sales_order_detail_id is -sales_order_id, so it never collides with a real line.
-- sub_total and total_due stay in fct_order_items.
--
-- A missing id resolves to a default row of its dimension, so the key is never NULL: 'Not
-- Applicable' when the id is legitimately absent (online orders have no salesperson, some orders
-- no card, an individual has no store), 'Missing' when it should have been there (see
-- fact_foreign_key.sql). The fact has no default rows of its own: a -1/-2 row would put sentinel
-- numbers into order_qty, unit_price and line_total and skew every SUM.
--
-- store_key needs the one lookup this model carries. The snapshot keeps one row per store version,
-- so the version is found by date, not by hash: the latest one that started on or before
-- order_date; an order that predates every version takes the store's oldest. The lookup is done
-- once per store and order date (all the lines of an order share both), and exactly one version is
-- picked by row_number, so a store with many versions can never fan the fact out.
--
-- Type 1: merge keyed on sales_order_detail_id, so a changed line overwrites its existing row in
-- place -- no history is kept here. On incremental runs only lines modified since the last run are
-- re-selected (the later of the line's and its order's modified date). That watermark is a date,
-- so the boundary day is selected again (>=) instead of risking a late arrival; the merge makes
-- the repeat harmless. See the dbt incremental-strategy docs:
-- https://docs.getdbt.com/docs/build/incremental-strategy

with product_lines as (

    select
        -- keys ------------------------------------------------------------
        sales_order_detail_key                  as order_lines_key,
        sales_order_detail_id,
        sales_order_id,
        false                                   as is_order_charge,

        -- order identifiers -------------------------------------------------
        sales_order_number,
        purchase_order_number,
        account_number,
        revision_number,

        -- dates -----------------------------------------------------------------
        order_date,
        due_date,
        ship_date,

        -- order profile (junk dimension) ------------------------------------
        order_status_code,
        is_online_order,

        -- foreign keys ----------------------------------------------------------
        customer_id,
        sales_person_id,
        territory_id,
        bill_to_address_id,
        ship_to_address_id,
        credit_card_id,
        store_id,
        product_id,

        -- degenerate dimensions ---------------------------------------------------
        special_offer_id,
        ship_method_id,
        currency_rate_id,

        -- line measures -----------------------------------------------------------
        order_qty,
        unit_price,
        unit_price_discount,
        line_total,

        -- order charges: only on the charge row ----------------------------------
        cast(null as number(38, 4))             as tax_amt,
        cast(null as number(38, 4))             as freight,

        -- audit -----------------------------------------------------------------
        order_line_modified_date

    from {{ ref('slv_dim_adventure_works_sales__sales_order_detail_join_header') }}

    {% if is_incremental() %}
    where order_line_modified_date >= (select coalesce(max(order_line_modified_date), '1900-01-01') from {{ this }})
    {% endif %}

),

-- one extra row per order that carries tax or freight: those amounts belong to the order, not to a
-- product, so the row has no product (product_key = Not Applicable) and no line measures
order_charges as (

    select
        {{ dbt_utils.generate_surrogate_key(["'order_charges'", 'sales_order_id']) }} as order_lines_key,
        -sales_order_id                         as sales_order_detail_id,
        sales_order_id,
        true                                    as is_order_charge,

        sales_order_number,
        purchase_order_number,
        account_number,
        revision_number,

        order_date,
        due_date,
        ship_date,

        order_status_code,
        is_online_order,

        customer_id,
        sales_person_id,
        territory_id,
        bill_to_address_id,
        ship_to_address_id,
        credit_card_id,
        store_id,
        cast(null as number)                    as product_id,

        cast(null as number)                    as special_offer_id,
        ship_method_id,
        currency_rate_id,

        cast(null as number)                    as order_qty,
        cast(null as number(38, 4))             as unit_price,
        cast(null as number(38, 4))             as unit_price_discount,
        cast(null as number(38, 4))             as line_total,

        tax_amt,
        freight,

        order_modified_date                     as order_line_modified_date

    from {{ ref('slv_dim_adventure_works_sales__sales_order_header_join_detail') }}

    where (coalesce(tax_amt, 0) != 0 or coalesce(freight, 0) != 0)
    {% if is_incremental() %}
      and order_modified_date >= (select coalesce(max(order_line_modified_date), '1900-01-01') from {{ this }})
    {% endif %}

),

items as (

    select * from product_lines
    union all
    select * from order_charges

),

-- real stores only: the -1/-2 default rows are not versions of any store
store_versions as (

    select
        store_id,
        store_key,
        store_valid_from,
        to_date(store_valid_from) as store_valid_from_date
    from {{ ref('gld_dim_store') }}
    where store_id > 0

),

-- one lookup per store and order date, not per line: the lines of an order share both
store_orders as (

    select distinct
        store_id,
        order_date
    from items
    where store_id is not null

),

store_version_for_order as (

    select
        so.store_id,
        so.order_date,
        v.store_key,
        row_number() over (
            partition by so.store_id, so.order_date
            order by
                -- versions already in force on the order date first, the latest of them on top...
                case when v.store_valid_from_date <= so.order_date then 0 else 1 end,
                case when v.store_valid_from_date <= so.order_date then v.store_valid_from end desc nulls last,
                -- ...and when none is, the store's oldest version
                v.store_valid_from asc,
                v.store_key
        ) as version_rank
    from store_orders as so
    inner join store_versions as v
        on so.store_id = v.store_id

)

select
    -- keys ----------------------------------------------------------------
    i.order_lines_key,
    i.sales_order_detail_id,

    -- order identifiers (degenerate dimensions) --------------------------------------
    i.sales_order_id,
    i.is_order_charge,
    i.sales_order_number,
    i.purchase_order_number,
    i.account_number,
    i.revision_number,

    -- dates: role-playing FK to adw_core's dim_date --------------------------------
    i.order_date,
    i.due_date,
    i.ship_date,

    -- foreign keys to conformed dimensions: surrogate keys, never ids ---------------
    -- junk dimension of order status, channel and shipped flag (order_profile_id macro; never null, so no default row is needed)
    {{ dbt_utils.generate_surrogate_key([order_profile_id('i.order_status_code', 'i.is_online_order', 'i.ship_date is not null')]) }} as order_profile_key,
    {{ fact_foreign_key('i.customer_id', ) }}                        as customer_key,
    {{ fact_foreign_key('i.territory_id') }}                         as territory_key,
    {{ fact_foreign_key('i.bill_to_address_id') }}                   as bill_to_address_key,
    {{ fact_foreign_key('i.ship_to_address_id') }}                   as ship_to_address_key,
    -- online orders legitimately have no salesperson (Not Applicable); any other order without one is Missing
    case
        when i.sales_person_id is null and i.is_online_order then {{ default_row_key('not_applicable') }}
        else {{ fact_foreign_key('i.sales_person_id', 'missing') }}
    end                                                              as sales_person_key,
    {{ fact_foreign_key('i.credit_card_id', 'not_applicable') }}     as credit_card_key,
    {{ fact_foreign_key('i.ship_method_id') }}                       as ship_method_key,
    -- sold in local currency: no exchange rate, so Not Applicable
    {{ fact_foreign_key('i.currency_rate_id', 'not_applicable') }}   as currency_rate_key,
    -- the order-charge row has no product, so no promotion: Not Applicable
    case
        when i.is_order_charge then {{ default_row_key('not_applicable') }}
        else {{ fact_foreign_key('i.special_offer_id') }}
    end                                                              as special_offer_key,
    -- the order-charge row has no product: Not Applicable. gld_dim_product (ADW_PRODUCTION) writes
    -- its default rows with the same 'Missing' / 'Not Applicable' text as this project's dimensions
    case
        when i.is_order_charge then {{ default_row_key('not_applicable') }}
        else {{ fact_foreign_key('i.product_id') }}
    end                                                              as product_key,

    -- Type 2 store version in force on the order date ---------------------------------
    case
        when i.store_id is null then {{ default_row_key('not_applicable') }}
        else coalesce(sv.store_key, {{ default_row_key('missing') }})
    end                                                              as store_key,

    -- line measures -----------------------------------------------------------------
    i.order_qty,
    i.unit_price,
    i.unit_price_discount,
    i.line_total,

    -- order charges: only on the charge row, NULL on product lines ----------------------
    i.tax_amt,
    i.freight,

    -- audit -------------------------------------------------------------------
    i.order_line_modified_date

from items as i
left join store_version_for_order as sv
    on  i.store_id      = sv.store_id
    and i.order_date    = sv.order_date
    and sv.version_rank = 1