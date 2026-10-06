select
    -- Primary & Foreign Keys
    try_to_number(trim(injury_tracker_id::varchar))::number(38,0)        as injury_tracker_id,
    try_to_number(trim(collision_tracker_id::varchar))::number(38,0)     as collision_tracker_id,
    try_to_number(trim(person_id::varchar))::number(38,0)                as person_id,
    try_to_number(trim(sales_person_id::varchar))::number(38,0)          as sales_person_id,
    try_to_number(trim(territory_id::varchar))::number(38,0)             as territory_id,

    -- Incident Dates & Tracking Details
    try_to_date(incident_date)                                           as incident_date,
    trim(injury_type)                                                    as injury_type,
    trim(body_part)                                                      as body_part,
    trim(severity)                                                       as severity,
    trim(status)                                                         as status,
    trim(treatment_type)                                                 as treatment_type,
    case
        when lower(trim(hospitalized_flag::varchar)) in ('1', 'true', 'yes', 'y') then true
        when lower(trim(hospitalized_flag::varchar)) in ('0', 'false', 'no', 'n') then false
        else null
    end                                                                  as is_hospitalized,
    days_lost::number(38,0)                                              as days_lost,
    trim(description)                                                    as description,

    -- Financial Impact / Costs
    medical_cost::number(19,4)                                           as medical_cost,
    claim_amount::number(19,4)                                           as claim_amount,

    -- Metadata & Audit
    rowguid,
    try_to_date(modified_date)                                           as modified_date,
    current_timestamp()                                                  as _loaded_at,
    'ADVENTURE_WORKS.SALES.INJURY_TRACKER'                               as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__injury_tracker') }}
where try_to_number(trim(injury_tracker_id::varchar)) is not null
