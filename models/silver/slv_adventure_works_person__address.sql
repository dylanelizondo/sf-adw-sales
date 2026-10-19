select
    address_id,
    address_line1,
    address_line2,
    city,
    state_province_id::number(38,0)                 as state_province_id,
    postal_code,
    try_to_date(modified_date)                       as modified_date,
    current_timestamp()                              as _loaded_at,
    'ADVENTURE_WORKS.PERSON.ADDRESS'                 as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_person__address') }}