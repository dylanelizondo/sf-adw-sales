select
    a.address_id,
    a.address_line1,
    a.address_line2,
    a.city,
    a.postal_code,
    a.state_province_id,
    sp.state_province_code,
    sp.state_province_name,
    sp.country_region_code,
    sp.territory_id,
    a.modified_date                                   as address_modified_date

from {{ ref('slv_adventure_works_person__address') }} as a
left join {{ ref('slv_adventure_works_person__state_province') }} as sp
    on a.state_province_id = sp.state_province_id