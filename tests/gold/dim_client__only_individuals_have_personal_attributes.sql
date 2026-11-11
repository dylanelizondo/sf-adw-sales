-- Personal attributes (the survey answers) belong to INDIVIDUAL clients only.
-- A row returned here is a STORE or UNKNOWN client that received personal data, for example one of
-- the 635 customers that carry both a person and a store id. The -1/-2 default rows added by
-- upsert_default_rows are exempt: they carry real placeholder values in every column on purpose.
select
    customer_id,
    client_type
from {{ ref('gld_dim_client') }}
where client_type != 'INDIVIDUAL'
  and customer_id not in (-1, -2)
  and (
         client_has_demographics_survey is not null
      or client_age_band is not null
      or client_education is not null
      or client_occupation is not null
      or client_total_children is not null
      or client_number_cars_owned is not null
      or client_is_home_owner is not null
  )
