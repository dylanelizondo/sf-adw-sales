{#-
    ---------------------------------------------------------------------------
    TEXT -> DATE / TIMESTAMP_NTZ cast for the silver layer.

    Every date column in ADVENTURE_WORKS arrives as TEXT in 'YYYY-MM-DD' format
    (the source load writes them with TO_CHAR). The cast lives here so the format
    assumption is written down once instead of 18 times.

    WHY try_to_date AND NOT to_date: try_* returns NULL on an unparseable value
    instead of aborting the run. On its own that would hide a format change, so
    every column that goes through this macro carries a not_null test in its .yml
    -- that is what makes the failure loud. Profiled 2026-09-23: 0 rows fail the
    cast across the whole schema, so the tests pass today and will start failing
    the day the source format changes.

    Do NOT use this on SALES_ORDER_ID. That column is also TEXT holding dates,
    but there it is a corrupted integer key, not a date -- see
    recover_sales_order_id (backlog B-04).
    ---------------------------------------------------------------------------
-#}

{% macro to_silver_date(column) -%}
    try_to_date({{ column }}, 'YYYY-MM-DD')
{%- endmacro %}


{% macro to_silver_ts(column) -%}
    try_to_timestamp_ntz({{ column }})
{%- endmacro %}
