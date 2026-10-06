-- Composite uniqueness test.
--
-- dbt ships `unique` for a single column only, and several silver bridge and history
-- tables are grained on two or more columns. dbt_utils would provide this, but the
-- project has no packages.yml and pulling one in for a single test adds a dependency
-- that every job then has to resolve; a generic test in this repo costs nothing and
-- behaves the same.
--
-- Copied from sf-adw-core/tests/generic/unique_combination_of_columns.sql.
-- Returns one row per duplicated combination, so a failure names the offending keys.
{% test unique_combination_of_columns(model, columns) %}

    select {{ columns | join(', ') }}
         , count(*) as rows_for_combination
    from {{ model }}
    group by {{ columns | join(', ') }}
    having count(*) > 1

{% endtest %}
