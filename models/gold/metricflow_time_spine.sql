-- Daily calendar for MetricFlow (dbt Semantic Layer), taken from adw_core's gld_dim_date so there is
-- one calendar, not two. Thin model: the time_spine config must live on a model in THIS project.
-- distinct: the dimension's default rows (Missing / Not Applicable) both resolve to 1900-01-01.
{{ config(materialized='view') }}

select distinct cast(date_key as date) as date_day
from {{ ref('adw_core', 'gld_dim_date') }}
