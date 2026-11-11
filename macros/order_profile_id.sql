{# Natural id of a row of dim_order_profile (the junk dimension of order status, channel and
   shipped flag): status * 100 + channel * 10 + shipped.
     status   order_status_code, 9 when it is null (real codes are 1 to 6)
     channel  1 online, 0 salesperson, 9 when unknown
     shipped  1 shipped, 0 not shipped
   Deterministic, so the silver model that lists the combinations and the facts that point at them
   compute the same id from the columns they already carry. Real ids start at 90, so they never
   meet the -1 / -2 default rows. #}
{% macro order_profile_id(status_code, is_online_order, is_shipped) -%}
    (coalesce({{ status_code }}, 9) * 100
     + case when {{ is_online_order }} is null then 9 when {{ is_online_order }} then 1 else 0 end * 10
     + case when {{ is_shipped }} then 1 else 0 end)
{%- endmacro %}