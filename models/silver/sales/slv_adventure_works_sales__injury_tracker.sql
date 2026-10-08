-- slv_adventure_works_sales__injury_tracker
-- ONE row per safety event report. Grain matches the source PK (report_number).
--
-- Log of workplace injuries and safety events with their OSHA classification. Cleaned
-- and typed only: text trimmed, dates and day counts cast. No business logic; that
-- belongs in gold.
--
-- Types: the tracker tables were added outside the standard AdventureWorks load, so their
-- columns are real types (created_date is a TIMESTAMP_NTZ), not TEXT. The to_silver_* macros
-- assume TEXT and fail on them (TRY_CAST on a timestamp), so every column is read through
-- ::varchar, which works whatever the bronze type is.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(nullif(trim(report_number::varchar), '') as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))      as injury_tracker_key,
    nullif(trim(report_number::varchar), '')                            as report_number,

    -- when ------------------------------------------------------------------
    try_to_timestamp_ntz(created_date::varchar)                         as created_at,
    try_to_date(date_occurred::varchar)                                 as date_occurred,

    -- what happened ---------------------------------------------------------
    trim(event_type::varchar)                                           as event_type,
    trim(event_report_title::varchar)                                   as event_report_title,
    trim(safety_incident_description::varchar)                          as safety_incident_description,
    trim(osha_classification::varchar)                                  as osha_classification,

    -- where -----------------------------------------------------------------
    trim(department::varchar)                                           as department,
    trim(location_of_event::varchar)                                    as location_of_event,

    -- injury ----------------------------------------------------------------
    trim(nature_of_injury::varchar)                                     as nature_of_injury,
    trim(region_of_body::varchar)                                       as region_of_body,

    -- impact ----------------------------------------------------------------
    try_to_number(days_restricted::varchar)::number(38,0)               as days_restricted,
    try_to_number(days_lost::varchar)::number(38,0)                     as days_lost,

    -- audit -----------------------------------------------------------------
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                           as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__injury_tracker") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__injury_tracker') }}
where nullif(trim(report_number::varchar), '') is not null
