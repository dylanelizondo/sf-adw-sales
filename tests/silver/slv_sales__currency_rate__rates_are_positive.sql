-- An exchange rate of zero or less is not a rate. Catches a source load that writes a
-- sentinel value into the amount columns, which a not_null test would let through.
--
-- Verified 2026-09-28: 0 failures.

select
      currency_rate_id
    , currency_rate_date
    , to_currency_code
    , average_rate
    , end_of_day_rate
from {{ ref('slv_sales__currency_rate') }}
where average_rate <= 0
   or end_of_day_rate <= 0
