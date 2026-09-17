{#-
    ---------------------------------------------------------------------------
    Controla el SCHEMA donde escribe cada modelo.

    El +schema de dbt_project.yml es el DOMINIO (SALES). Este macro decide si se
    usa literal o con un prefijo adelante:

      DBT_ENV_TYPE = dev     ->  DYLAN_ELIZONDO_SALES   (IDE: sandbox personal)
                                 DBT_CLOUD_PR_123_5_SALES  (CI: aislado por PR)
      DBT_ENV_TYPE = deploy  ->  SALES                  (jobs de UAT y PROD)

    El prefijo sale de target.schema, que dbt Cloud define solo: tu schema
    personal en el IDE, o el del PR en los jobs de CI.

    Default 'dev' a proposito: si la variable falta, el peor caso es escribir en
    un schema aislado, nunca encima de PROD.

    DIAGNOSTICO: la linea log() imprime la decision en los logs de cada corrida.
    Buscá "[SCHEMA]" en el log del job. Comentala cuando ya no la necesites.
    ---------------------------------------------------------------------------
-#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set env_type = env_var('DBT_ENV_TYPE', 'dev') | lower | trim -%}
    {%- set dominio = custom_schema_name | trim | upper
                      if custom_schema_name is not none else none -%}

    {%- if dominio is none -%}
        {%- set resultado = target.schema | trim | upper -%}
        {%- set motivo = 'el modelo no declara +schema' -%}
    {%- elif env_type == 'dev' -%}
        {%- set resultado = (target.schema | trim | upper) ~ '_' ~ dominio -%}
        {%- set motivo = 'modo dev: prefijo target.schema' -%}
    {%- else -%}
        {%- set resultado = dominio -%}
        {%- set motivo = 'modo deploy: dominio literal' -%}
    {%- endif -%}

    {{- log('[SCHEMA] ' ~ (node.name if node is not none else '?')
            ~ ' | +schema=' ~ (custom_schema_name if custom_schema_name is not none else 'none')
            ~ ' | DBT_ENV_TYPE=' ~ env_type
            ~ ' | target.schema=' ~ target.schema
            ~ ' | -> ' ~ resultado
            ~ ' (' ~ motivo ~ ')', info=True) -}}

    {{- resultado -}}

{%- endmacro %}