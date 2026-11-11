{# Turns a value into a SQL literal: quotes text/dates, leaves numbers/booleans as is #}
{% macro _default_sql_literal(raw, col) %}
  {%- set dtype = col.dtype | upper -%}
  {%- if raw is none -%}null
  {%- elif col.is_number() or dtype == 'BOOLEAN' -%}{{ raw }}
  {%- else -%}'{{ raw | string | replace("'", "'") }}'
  {%- endif -%}
{% endmacro %}


{# The text a default row (-1 / -2) gets in a text column. THE ONLY place that decides it:
   upsert_default_rows writes it into every text column, and default_row_key (macros/
   fact_foreign_key.sql) reads it for the fact's fallback key, so both always agree.
   idx: 0 = the -1 row (Missing), 1 = the -2 row (Not Applicable).
   max_len: char size of the target column, or none. When the text does not fit, text_short
   (default '-1' / '-2') is used, cut to max_len if it still does not fit. #}
{% macro default_row_text(idx, max_len=none) -%}
  {%- set by_type = var('default_rows', {}).get('by_type', {}) -%}
  {%- set raw = by_type.get('text', ['Missing', 'Not Applicable'])[idx] -%}
  {%- if max_len is not none and (raw | length) > max_len -%}
    {%- set short = by_type.get('text_short', ['-1', '-2'])[idx] -%}
    {%- if (short | length) <= max_len -%}
      {%- set raw = short -%}
    {%- else -%}
      {%- set raw = short[:max_len] -%}
    {%- endif -%}
  {%- endif -%}
  {{- raw -}}
{%- endmacro %}


{# Inserts or updates ONLY the -1 and -2 rows.
   column_defaults (optional): {'column_name': [value_for_-1, value_for_-2]}
   Columns not listed fall back to var('default_rows').by_type #}
{% macro upsert_default_rows(key_column, column_defaults=none) %}
  {% if execute %}
    {% set by_type = var('default_rows', {}).get('by_type', {}) %}
    {% set cols    = adapter.get_columns_in_relation(this) %}
    {% set key     = key_column | upper %}

    {# Normalize override keys to upper case so 'country_code' matches COUNTRY_CODE #}
    {% set overrides = {} %}
    {% for name, values in (column_defaults or {}).items() %}
      {% do overrides.update({name | upper: values}) %}
    {% endfor %}

    merge into {{ this }} t
    using (
      {% for idx in [0, 1] %}
      select
        {% for col in cols %}
          {% set dtype = col.dtype | upper %}
          {% set cname = col.name | upper %}

          {% if cname == key %}
            {% set raw = [-1, -2][idx] %}
          {% elif cname in overrides %}
            {% set raw = overrides[cname][idx] %}
          {% elif col.is_string() %}
            {% set raw = default_row_text(idx, col.char_size) %}
          {% elif col.is_number() %}
            {% set raw = by_type.get('number', [-1, -2])[idx] %}
          {% elif 'TIMESTAMP' in dtype %}
            {% set raw = by_type.get('timestamp', ['1900-01-01 00:00:00', '1900-01-01 00:00:00'])[idx] %}
          {% elif 'DATE' in dtype %}
            {% set raw = by_type.get('date', ['1900-01-01', '1900-01-01'])[idx] %}
          {% elif dtype == 'BOOLEAN' %}
            {% set raw = by_type.get('boolean', [false, false])[idx] %}
          {% else %}
            {% set raw = none %}
          {% endif %}

          cast({{ _default_sql_literal(raw, col) }} as {{ col.data_type }}) as {{ col.name }}{% if not loop.last %},{% endif %}
        {% endfor %}
      {% if not loop.last %}union all{% endif %}
      {% endfor %}
    ) s
    on t.{{ key_column }} = s.{{ key_column }}
    when matched then update set
      {% for col in cols if (col.name | upper) != key %}
        t.{{ col.name }} = s.{{ col.name }}{% if not loop.last %},{% endif %}
      {% endfor %}
    when not matched then insert (
      {% for col in cols %}{{ col.name }}{% if not loop.last %}, {% endif %}{% endfor %}
    ) values (
      {% for col in cols %}s.{{ col.name }}{% if not loop.last %}, {% endif %}{% endfor %}
    )
  {% endif %}
{% endmacro %}