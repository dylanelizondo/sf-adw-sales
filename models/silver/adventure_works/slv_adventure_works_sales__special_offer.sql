-- slv_adventure_works_sales__special_offer
-- ONE row per promotion. 16 = Sales.SpecialOffer. THIS ROW COUNT IS THE CONTRACT,
-- enforced by tests/silver/slv_adventure_works_sales__special_offer_row_count_matches_source.sql.
--
-- Lookup of promotions and discounts, with validity dates and the quantity range they
-- apply to. special_offer_key is minted HERE from special_offer_id so gold never has to
-- recompute it. One row per promotion already, so no CTE or join is needed here.

select
    -- keys ----------------------------------------------------------------
    -- Same md5-of-varchar construction as the store and person surrogate keys, so a
    -- key built the same way means the same thing anywhere in the mesh.
    md5(cast(coalesce(cast(special_offer_id as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar)) as special_offer_key,
    special_offer_id,

    -- identity --------------------------------------------------------------
    description   as special_offer_description,
    discount_pct  as special_offer_discount_pct,
    type          as special_offer_type,
    category      as special_offer_category,

    -- validity window ---------------------------------------------------
    try_to_date(start_date) as special_offer_start_date,
    try_to_date(end_date)   as special_offer_end_date,

    -- quantity range this promotion applies to. max_qty is legitimately null
    -- when the promotion has no upper cap.
    min_qty as special_offer_min_qty,
    max_qty as special_offer_max_qty,

    -- audit -------------------------------------------------------------
    try_to_timestamp(modified_date) as special_offer_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__special_offer') }}
