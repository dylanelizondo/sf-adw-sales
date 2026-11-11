-- slv_dim_adventure_works_sales__order_profile
-- ONE row per combination of order status, sales channel and shipped flag that exists in the
-- orders: the rows of the junk dimension dim_order_profile. At most 6 statuses x 2 channels x 2
-- shipped values, so a few dozen rows. Row count is the contract of the gold dimension
-- (silver + 2 default rows), enforced by tests/gold/dim_order_profile__row_count_matches_silver.sql.
--
-- order_profile_id (macros/order_profile_id.sql) is deterministic from the three attributes, so
-- the facts compute the same id from the columns they carry. The labels follow from the codes,
-- so the distinct cannot produce two rows for one id (tested: order_profile_id is unique).
{{ config(alias="adw_sales_order_profile") }}

select distinct
    {{ order_profile_id('status_code', 'is_online_order', 'ship_date is not null') }} as order_profile_id,
    status_code                                                                       as order_status_code,
    status_label                                                                      as order_status_label,
    is_online_order,
    order_channel_label                                                               as order_channel,
    ship_date is not null                                                             as is_shipped
from {{ ref('slv_adventure_works_sales__sales_order_header') }}
