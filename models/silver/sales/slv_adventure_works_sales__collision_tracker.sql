-- slv_adventure_works_sales__collision_tracker
-- ONE row per collision incident. Grain matches the source PK (incident_number).
--
-- Log of fleet vehicle collisions. Cleaned and typed only: text trimmed, the date and
-- speed cast, yes/no flags turned into booleans. No business logic; that belongs in gold.
-- Driver names are PII and are carried as delivered (trimmed).

select
    -- keys ----------------------------------------------------------------
    md5(cast(coalesce(cast(nullif(trim(incident_number::varchar), '') as varchar),
                      '_dbt_utils_surrogate_key_null_') as varchar))      as collision_tracker_key,
    nullif(trim(incident_number::varchar), '')                          as incident_number,

    -- when ------------------------------------------------------------------
    {{ to_silver_date('incident_date') }}                               as incident_date,
    trim(day_of_week)                                                   as day_of_week,
    trim(time_of_day)                                                   as time_of_day,

    -- what happened ---------------------------------------------------------
    trim(incident_title)                                                as incident_title,
    trim(collision_type)                                                as collision_type,
    trim(collision_initiated_by)                                        as collision_initiated_by,
    trim(vehicle_activity_at_collision)                                 as vehicle_activity_at_collision,
    try_to_number(mph_at_collision::varchar, 9, 2)                      as mph_at_collision,

    -- where -----------------------------------------------------------------
    trim(service_area)                                                  as service_area,
    trim(territory)                                                     as territory,
    trim(collision_location)                                            as collision_location,

    -- driver ----------------------------------------------------------------
    trim(driver_first_name)                                             as driver_first_name,
    trim(driver_last_name)                                              as driver_last_name,
    case
        when lower(trim(cdl_holder::varchar)) in ('yes', 'y', 'true', '1') then true
        when lower(trim(cdl_holder::varchar)) in ('no', 'n', 'false', '0') then false
        else null
    end                                                                 as is_cdl_holder,

    -- investigation ---------------------------------------------------------
    trim(safety_professional)                                           as safety_professional,
    case
        when lower(trim(kore_camera_assisted::varchar)) in ('yes', 'y', 'true', '1') then true
        when lower(trim(kore_camera_assisted::varchar)) in ('no', 'n', 'false', '0') then false
        else null
    end                                                                 as is_kore_camera_assisted,
    trim(conclusion)                                                    as conclusion,
    trim(notes)                                                         as notes,

    -- audit -----------------------------------------------------------------
    -- sysdate() is UTC TIMESTAMP_NTZ; current_timestamp() would be TIMESTAMP_LTZ.
    sysdate()                                                           as _loaded_at,
    '{{ ref("adw_core", "brz_adventure_works_sales__collision_tracker") }}'::varchar as _source_relation

from {{ ref('adw_core', 'brz_adventure_works_sales__collision_tracker') }}
where nullif(trim(incident_number::varchar), '') is not null
