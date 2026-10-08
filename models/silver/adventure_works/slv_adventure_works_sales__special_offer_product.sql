-- slv_special_offer_product
-- ONE row per special_offer + product pair. Grain matches the source composite PK.
-- Simple bridge between promotions and the products they apply to.

select
    -- grain keys ----------------------------------------------------------
    special_offer_id,
    product_id,

    -- technical column ----------------------------------------------------
    rowguid,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(modified_date) as special_offer_product_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__special_offer_product') }}
