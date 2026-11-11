{{ config(
    alias="dim_currency_rate",
    materialized='incremental',
    unique_key='currency_rate_id',
    incremental_strategy='merge',
    post_hook="{{ upsert_default_rows('currency_rate_id', {
        'AVERAGE_RATE': [none, none],
        'END_OF_DAY_RATE': [none, none],
    }) }}"
    )
}}

-- dim_currency_rate
-- ONE row per exchange rate (a currency pair on a date) plus the two default rows (-1 Missing,
-- -2 Not Applicable) that upsert_default_rows adds in the post_hook. Row count equals
-- slv_adventure_works_sales__currency_rate + 2, enforced by
-- tests/gold/dim_currency_rate__row_count_matches_silver.sql.
--
-- Type 1: merge keyed on currency_rate_id, so a changed rate overwrites its row in place and no
-- history is kept. Straight select from ONE silver model, no JOINs.
--
-- The facts point orders sold in local currency, which carry no rate, at the -2 "Not Applicable"
-- row. The rates are NULL on the default rows, so no sentinel number is mistaken for a real rate.

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['currency_rate_id']) }} as currency_rate_key,
    r.currency_rate_id,

    -- exchange rate -------------------------------------------------------------
    r.currency_rate_date,
    r.from_currency_code,
    r.to_currency_code,
    r.average_rate,
    r.end_of_day_rate,

    -- audit -------------------------------------------------------------------
    r.modified_date                             as currency_rate_modified_date

from {{ ref('slv_adventure_works_sales__currency_rate') }} as r
