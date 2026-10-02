select
    -- Aggregation Grain
    incident_date                                                          as incident_date,
    territory_id                                                           as territory_id,
    sales_person_id                                                        as sales_person_id,
    injury_severity                                                        as injury_severity,
    incident_status                                                        as incident_status,

    -- Incident Counts & Rates
    count(injury_tracker_id)                                               as total_incidents_count,
    sum(case when is_collision_related then 1 else 0 end)                  as collision_related_incidents_count,
    sum(case when is_hospitalized then 1 else 0 end)                       as hospitalized_incidents_count,
    sum(days_lost_count)                                                   as total_days_lost_count,

    -- Financial Impact
    sum(medical_cost_amount)::number(19,4)                                 as total_medical_cost_amount,
    sum(claim_amount)::number(19,4)                                        as total_claim_amount,
    sum(collision_actual_cost_amount)::number(19,4)                        as total_collision_cost_amount,
    sum(total_incident_cost_amount)::number(19,4)                          as total_incident_cost_amount,

    -- Averages
    (sum(days_lost_count) / nullif(count(injury_tracker_id), 0))::number(19,2)             as average_days_lost_per_incident,
    (sum(total_incident_cost_amount) / nullif(count(injury_tracker_id), 0))::number(19,4)  as average_cost_per_incident_amount,

    -- Audit Metadata
    current_timestamp()                                                    as _loaded_at
from {{ ref('fct_safety_incidents') }}
group by
    incident_date,
    territory_id,
    sales_person_id,
    injury_severity,
    incident_status
