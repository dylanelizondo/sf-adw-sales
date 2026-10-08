-- slv_shopping_cart_item
-- ONE row per cart item. Grain matches the source PK (shopping_cart_item_id).
--
-- Only 3 rows exist in the source (active carts at snapshot time). The model
-- is built as a full table regardless; its small size is not a reason to skip
-- the silver layer — it is still a legitimate sales entity referenced by gold.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(shopping_cart_item_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as shopping_cart_item_key,
    shopping_cart_item_id,

    -- attributes ----------------------------------------------------------
    shopping_cart_id,
    quantity,
    product_id,

    -- dates ---------------------------------------------------------------
    try_to_date(date_created)       as date_created,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(modified_date) as shopping_cart_item_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__shopping_cart_item') }}
