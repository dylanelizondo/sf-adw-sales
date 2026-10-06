-- slv_adventure_works_sales__injury_tracker
-- ONE row per safety event report. Grain matches the source PK (report_number).
--
-- Log of workplace injuries and safety events with their OSHA classification. Cleaned
-- and typed only: text trimmed, dates and day counts cast. No business logic; that
-- belongs in gold.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(nullif(trim(report_number::varchar), '') as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))      as injury_tracker_key,
    nullif(trim(report_number::varchar), '')                            as report_number,

    -- when ------------------------------------------------------------------
    {{ to_silver_ts('created_date') }}                                  as created_at,
    {{ to_silver_date('date_occurred') }}                               as date_occurred,

    -- what happened ---------------------------------------------------------
    trim(event_type)                                                    as event_type,
    trim(event_report_title)                                            as event_report_title,
    trim(safety_incident_description)                                   as safety_incident_description,
    trim(osha_classification)                                           as osha_classification,

    -- where -----------------------------------------------------------------
    trim(department)                                                    as department,
    trim(location_of_event)                                             as location_of_event,

    -- injury ----------------------------------------------------------------
    trim(nature_of_injury)                                              as nature_of_injury,
    trim(region_of_body)                                                as region_of_body,

    -- impact ----------------------------------------------------------------
    try_to_number(days_restricted::varchar)::number(38,0)               as days_restricted,
    try_to_number(days_lost::varchar)::number(38,0)                     as days_lost,

    -- audit -----------------------------------------------------------------
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                           as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__injury_tracker") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__injury_tracker') }}
where nullif(trim(report_number::varchar), '') is not null
