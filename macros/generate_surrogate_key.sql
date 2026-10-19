-- Lightweight replacement for dbt_utils.generate_surrogate_key.
--
-- The project has no packages.yml (see tests/generic/unique_combination_of_columns.sql
-- for the same reasoning): pulling in dbt_utils for a single helper adds a dependency
-- every job then has to resolve. This macro does the same thing dbt_utils does —
-- concatenate the given columns with a separator, coalescing nulls to a placeholder
-- so a null doesn't silently collapse the key, then hash the result with MD5 — without
-- requiring the package.

{% macro generate_surrogate_key(field_list) %}

    md5(
        {%- for field in field_list %}
            coalesce(cast({{ field }} as varchar), '_dbt_utils_surrogate_key_null_')
            {% if not loop.last %} || '-' || {% endif %}
        {%- endfor %}
    )

{% endmacro %}