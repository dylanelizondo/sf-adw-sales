-- slv_country_region_currency
-- ONE row per country + currency pair. Grain matches the source composite PK.
-- Trivial bridge: no transformations beyond the audit cast.

select
    -- grain keys ----------------------------------------------------------
    country_region_code,
    currency_code,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(modified_date) as country_region_currency_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__country_region_currency') }}
