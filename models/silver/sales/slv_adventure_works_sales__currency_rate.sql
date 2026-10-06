-- Silver model. Same grain as bronze (one row per date + currency pair), properly typed.
-- No aggregation and no business logic: dimensional modelling belongs in gold.
--
-- CURRENCY_RATE_DATE is the day the rate applies to, and in the source it is the day the
-- referencing order was placed. That alignment is broken today -- see the model description
-- in slv_adventure_works_sales__currency_rate.yml before using this table for currency conversion.

with source as (

    select * from {{ ref('adw_core', 'brz_adventure_works_sales__currency_rate') }}

),

renamed as (

    select
          currency_rate_id::number(38,0)                 as currency_rate_id
        , {{ to_silver_date('currency_rate_date') }}      as currency_rate_date
        , from_currency_code::varchar(3)                 as from_currency_code
        , to_currency_code::varchar(3)                   as to_currency_code
        , average_rate::number(19,6)                     as average_rate
        , end_of_day_rate::number(19,6)                  as end_of_day_rate
        , {{ to_silver_date('modified_date') }}          as modified_date
    from source

)

select
      currency_rate_id
    , currency_rate_date
    , from_currency_code
    , to_currency_code
    , average_rate
    , end_of_day_rate
    , modified_date

    -- Audit columns. sysdate() is UTC TIMESTAMP_NTZ in Snowflake; current_timestamp()
    -- would be TIMESTAMP_LTZ and read differently per session timezone.
    , sysdate()                                                                             as _loaded_at
    , '{{ ref("adw_core", "brz_adventure_works_sales__currency_rate") }}'::varchar           as _source_relation
from renamed
