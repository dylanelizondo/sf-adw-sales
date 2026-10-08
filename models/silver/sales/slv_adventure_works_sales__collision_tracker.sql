-- slv_adventure_works_sales__collision_tracker
-- ONE row per collision incident. Grain matches the source PK (incident_number).
--
-- Log of fleet vehicle collisions. Cleaned and typed only: text trimmed, the date and
-- speed cast, yes/no flags turned into booleans. No business logic; that belongs in gold.
-- Driver names are PII and are carried as delivered (trimmed).
--
-- Types: the tracker tables were added outside the standard AdventureWorks load, so their
-- columns are real types (incident_date is a DATE), not TEXT. The to_silver_* macros assume
-- TEXT and fail on them (TRY_TO_DATE with a format on a DATE), so every column is read
-- through ::varchar, which works whatever the bronze type is.

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(nullif(trim(incident_number::varchar), '') as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))      as collision_tracker_key,
    nullif(trim(incident_number::varchar), '')                          as incident_number,

    -- when ------------------------------------------------------------------
    try_to_date(incident_date::varchar)                                 as incident_date,
    trim(day_of_week::varchar)                                          as day_of_week,
    trim(time_of_day::varchar)                                          as time_of_day,

    -- what happened ---------------------------------------------------------
    trim(incident_title::varchar)                                       as incident_title,
    trim(collision_type::varchar)                                       as collision_type,
    trim(collision_initiated_by::varchar)                               as collision_initiated_by,
    trim(vehicle_activity_at_collision::varchar)                        as vehicle_activity_at_collision,
    try_to_number(mph_at_collision::varchar, 9, 2)                      as mph_at_collision,

    -- where -----------------------------------------------------------------
    trim(service_area::varchar)                                         as service_area,
    trim(territory::varchar)                                            as territory,
    trim(collision_location::varchar)                                   as collision_location,

    -- driver ----------------------------------------------------------------
    trim(driver_first_name::varchar)                                    as driver_first_name,
    trim(driver_last_name::varchar)                                     as driver_last_name,
    case
        when lower(trim(cdl_holder::varchar)) in ('yes', 'y', 'true', '1') then true
        when lower(trim(cdl_holder::varchar)) in ('no', 'n', 'false', '0') then false
        else null
    end                                                                 as is_cdl_holder,

    -- investigation ---------------------------------------------------------
    trim(safety_professional::varchar)                                  as safety_professional,
    case
        when lower(trim(kore_camera_assisted::varchar)) in ('yes', 'y', 'true', '1') then true
        when lower(trim(kore_camera_assisted::varchar)) in ('no', 'n', 'false', '0') then false
        else null
    end                                                                 as is_kore_camera_assisted,
    trim(conclusion::varchar)                                           as conclusion,
    trim(notes::varchar)                                                as notes,

    -- audit -----------------------------------------------------------------
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                           as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__collision_tracker") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__collision_tracker') }}
where nullif(trim(incident_number::varchar), '') is not null
