-- slv_adventure_works_purchasing__ship_method
-- ONE row per shipping method. Grain matches the source PK (ship_method_id).
--
-- Lookup of shipping methods with their base and variable rates. Cleaned and typed only: text
-- trimmed, the rates cast. The table lives in the PURCHASING schema of the source, but the sales
-- orders point at it, so this domain consumes it from sf-adw-core's bronze. modified_date is
-- already TIMESTAMP_NTZ in bronze and is kept as delivered.

{{ config(alias="stg_dim_adw_purchasing_ship_method") }}

select
    -- keys ----------------------------------------------------------------
    {{ dbt_utils.generate_surrogate_key(['ship_method_id']) }}       as ship_method_key,
    ship_method_id::number(38,0)                                     as ship_method_id,

    -- attributes ----------------------------------------------------------
    trim(name)                                                       as ship_method_name,
    ship_base::number(19,4)                                          as ship_base,
    ship_rate::number(19,4)                                          as ship_rate,

    -- audit ---------------------------------------------------------------
    modified_date                                                    as ship_method_modified_date

from {{ ref('adw_core', 'brz_adventure_works_purchasing__ship_method') }}
