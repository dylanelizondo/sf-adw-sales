
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set dominio = custom_schema_name | trim | upper
                      if custom_schema_name is not none else none -%}

    {%- set es_job = env_var('DBT_CLOUD_RUN_ID', '') != ''
                     or env_var('DBT_CLOUD_JOB_ID', '') != '' -%}

    {%- if dominio is none -%}
        {%- set resultado = target.schema | trim | upper -%}
    {%- elif es_job -%}
        {%- set resultado = dominio -%}
    {%- else -%}
        {%- set resultado = (target.schema | trim | upper) -%}
    {%- endif -%}

    {{- resultado -}}

{%- endmacro %}