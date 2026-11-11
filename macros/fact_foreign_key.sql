{# How a fact points at a gold dimension by SURROGATE key.

   Type 1 gold dimensions mint their key as dbt_utils.generate_surrogate_key([<natural id>]), so the
   fact recomputes the same hash from the id it carries -- no join to the dimension needed.

   A NULL id has no hash to compute, so it resolves to one of the dimension's two default rows and
   the key is never NULL. upsert_default_rows writes the by-type text default ('Missing' /
   'Not Applicable', vars.default_rows in dbt_project.yml) into every text column of those rows --
   the surrogate-key column included -- so that text IS their key. Both macros get the text from
   default_row_text (macros/upsert_default_rows.sql), so the key a fact falls back to is, by
   construction, the key the dimension's default row was written with.

   null_means: 'missing'        the id should have been there          -> the -1 row
               'not_applicable' the id is legitimately absent (no card) -> the -2 row #}


{# The key of a dimension's default row, as a SQL literal. which: 'missing' or 'not_applicable'.

   The text must fit a surrogate-key column. A key is an md5 hash (32 characters), and
   upsert_default_rows swaps in the short text (text_short) when the text does not fit its column,
   which would silently make this literal differ from the key the dimension holds. So a text longer
   than 32 characters stops the compilation instead. #}
{% macro default_row_key(which) -%}
    {%- if which not in ['missing', 'not_applicable'] -%}
        {{ exceptions.raise_compiler_error("default_row_key: expected 'missing' or 'not_applicable', got '" ~ which ~ "'") }}
    {%- endif -%}
    {%- set text = default_row_text(1 if which == 'not_applicable' else 0) -%}
    {%- if text | length > 32 -%}
        {{ exceptions.raise_compiler_error("default_row_key: the default row text '" ~ text ~ "' is longer than a surrogate key (32 characters); shorten vars.default_rows.by_type.text") }}
    {%- endif -%}
    '{{ text }}'
{%- endmacro %}


{# Surrogate-key expression for a fact column whose dimension keys on a single natural id.
   An id that is NOT null but has no row in the dimension is not hidden here: the relationships
   test on the fact's key column reports it. #}
{% macro fact_foreign_key(id_column, null_means='missing') -%}
    case
        when {{ id_column }} is null then {{ default_row_key(null_means) }}
        else {{ dbt_utils.generate_surrogate_key([id_column]) }}
    end
{%- endmacro %}
