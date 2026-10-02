select
    -- Natural & Foreign Keys
    i.injury_tracker_id                                                    as injury_tracker_id,
    coalesce(i.collision_tracker_id, -1)                                   as collision_tracker_id,
    coalesce(i.person_id, -1)                                              as person_id,
    coalesce(i.sales_person_id, c.sales_person_id, -1)                     as sales_person_id,
    coalesce(i.territory_id, c.territory_id, -1)                           as territory_id,
    coalesce(c.vehicle_id, -1)                                             as vehicle_id,

    -- Incident Dates & Flags
    i.incident_date                                                        as incident_date,
    case
        when i.collision_tracker_id is not null then true
        else false
    end                                                                    as is_collision_related,

    -- Categorical Dimensions
    coalesce(i.injury_type, 'Unspecified')                                 as injury_type,
    coalesce(i.body_part, 'Unspecified')                                   as body_part,
    coalesce(i.severity, 'Unspecified')                                    as injury_severity,
    coalesce(c.severity, 'None')                                           as collision_severity,
    coalesce(i.status, 'Unspecified')                                      as incident_status,
    coalesce(i.treatment_type, 'None')                                     as treatment_type,
    coalesce(i.is_hospitalized, false)                                     as is_hospitalized,

    -- Metrics & Financials
    coalesce(i.days_lost, 0)                                               as days_lost_count,
    coalesce(i.medical_cost, 0::number(19,4))                              as medical_cost_amount,
    coalesce(i.claim_amount, 0::number(19,4))                              as claim_amount,
    coalesce(c.estimated_cost, 0::number(19,4))                            as collision_estimated_cost_amount,
    coalesce(c.actual_cost, 0::number(19,4))                               as collision_actual_cost_amount,
    (coalesce(i.medical_cost, 0) + coalesce(c.actual_cost, 0))::number(19,4) as total_incident_cost_amount,

    -- Incident Descriptions & References
    coalesce(i.description, 'No description')                              as injury_description,
    coalesce(c.police_report_number, 'N/A')                                as police_report_number,

    -- Audit Metadata
    current_timestamp()                                                    as _loaded_at
from {{ ref('slv_adventure_works_sales__injury_tracker') }} i
left join {{ ref('slv_adventure_works_sales__collision_tracker') }} c
    on i.collision_tracker_id = c.collision_tracker_id
