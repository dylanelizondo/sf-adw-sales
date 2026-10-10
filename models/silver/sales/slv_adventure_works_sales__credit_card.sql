select
    credit_card_id,
    card_type,
    right(to_varchar(card_number), 4)                 as card_last_four,
    sha2(to_varchar(card_number))                     as card_number_hash,
    last_day(date_from_parts(exp_year, exp_month, 1)) as expiry_date,
    try_to_date(modified_date)                        as modified_date,
    current_timestamp()                               as _loaded_at,
    'ADVENTURE_WORKS.SALES.CREDIT_CARD'                as _source_relation
from {{ ref('adw_core', 'brz_adventure_works_sales__credit_card') }}