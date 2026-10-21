{# Turns a value into a SQL literal: quotes text/dates, leaves numbers/booleans as is #}
{% macro _default_sql_literal(raw, col) %}
  {%- set dtype = col.dtype | upper -%}
  {%- if raw is none -%}null
  {%- elif col.is_number() or dtype == 'BOOLEAN' -%}{{ raw }}
  {%- else -%}'{{ raw | string | replace("'", "'") }}'
  {%- endif -%}
{% endmacro %}


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
            {% set raw     = by_type.get('text', ['Missing', 'Not Applicable'])[idx] %}
            {% set max_len = col.char_size %}
            {% if max_len is not none and (raw | length) > max_len %}
              {% set short = by_type.get('text_short', ['-1', '-2'])[idx] %}
              {% if (short | length) <= max_len %}
                {% set raw = short %}
              {% else %}
                {% set raw = short[:max_len] %}
              {% endif %}
            {% endif %}
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