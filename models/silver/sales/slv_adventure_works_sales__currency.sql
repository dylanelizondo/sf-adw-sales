-- Silver model. Same grain as bronze (one row per currency), properly typed and named.
-- No aggregation and no business logic: dimensional modelling belongs in gold.

with source as (

    select * from {{ ref('adw_core', 'brz_adventure_works_sales__currency') }}

),

renamed as (

    select
          currency_code::varchar(3)                  as currency_code
        -- NAME is too generic to survive a join downstream, so it gets the
        -- entity prefix here rather than in every gold model.
        , name::varchar(50)                          as currency_name
        , {{ to_silver_date('modified_date') }}      as modified_date
    from source

)

select
      currency_code
    , currency_name
    , modified_date

    -- Audit columns. sysdate() is UTC TIMESTAMP_NTZ in Snowflake; current_timestamp()
    -- would be TIMESTAMP_LTZ and read differently per session timezone.
    , sysdate()                                                                        as _loaded_at
    , '{{ ref("adw_core", "brz_adventure_works_sales__currency") }}'::varchar           as _source_relation
from renamed
