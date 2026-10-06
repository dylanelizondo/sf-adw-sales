select
    -- Primary & Foreign Keys
    try_to_number(trim(collision_tracker_id::varchar))::number(38,0)     as collision_tracker_id,
    try_to_number(trim(vehicle_id::varchar))::number(38,0)                as vehicle_id,
    try_to_number(trim(sales_person_id::varchar))::number(38,0)          as sales_person_id,
    try_to_number(trim(territory_id::varchar))::number(38,0)             as territory_id,

    -- Incident Dates & Tracking Details
    try_to_date(incident_date)                                           as incident_date,
    trim(collision_type)                                                 as collision_type,
    trim(severity)                                                       as severity,
    trim(status)                                                         as status,
    trim(description)                                                    as description,
    trim(police_report_number)                                           as police_report_number,

    -- Financial Impact / Costs
    estimated_cost::number(19,4)                                         as estimated_cost,
    actual_cost::number(19,4)                                            as actual_cost,

    -- Metadata & Audit
    rowguid,
    try_to_date(modified_date)                                           as modified_date,
    current_timestamp()                                                  as _loaded_at,
    'ADVENTURE_WORKS.SALES.COLLISION_TRACKER'                            as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__collision_tracker') }}
where try_to_number(trim(collision_tracker_id::varchar)) is not null
