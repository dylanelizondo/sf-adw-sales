select
    state_province_id,
    state_province_code,
    country_region_code,
    is_only_state_province_flag::boolean             as is_only_state_province,
    name                                              as state_province_name,
    territory_id::number(38,0)                        as territory_id,
    modified_date                                     as modified_date,
    current_timestamp()                               as _loaded_at,
    'ADVENTURE_WORKS.PERSON.STATE_PROVINCE'            as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_person__state_province') }}