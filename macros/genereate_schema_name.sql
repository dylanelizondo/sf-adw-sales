{#-
    ---------------------------------------------------------------------------
    Controla el SCHEMA donde escribe cada modelo.

    El +schema de dbt_project.yml es el DOMINIO (SALES). La regla es:

      Studio (IDE)        ->  DYLAN_ELIZONDO_SALES   sandbox personal
      Job de CI           ->  SALES                  en ADW_*_DEV
      Job de UAT / PROD   ->  SALES                  en ADW_*_UAT / _PROD

    O sea: el unico que lleva prefijo es tu IDE. Todo lo que corre como job
    escribe el dominio limpio, y la separacion entre ambientes la da la base
    de datos (DBT_DB_ADW_*), no el schema.

    COMO SE DETECTA: dbt Cloud inyecta DBT_CLOUD_RUN_ID y DBT_CLOUD_JOB_ID en
    toda corrida de job. Studio no las trae. Si faltaran, cae del lado del
    prefijo, que es el lado seguro: nunca sobreescribe el SALES compartido.

    Ya no se usa DBT_ENV_TYPE. Si la creaste en dbt Cloud, podes borrarla.

    DIAGNOSTICO: la linea log() imprime la decision de cada modelo en el log
    de la corrida. Busca "[SCHEMA]". Comentala cuando ya no la necesites.
    ---------------------------------------------------------------------------
-#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set dominio = custom_schema_name | trim | upper
                      if custom_schema_name is not none else none -%}

    {%- set es_job = env_var('DBT_CLOUD_RUN_ID', '') != ''
                     or env_var('DBT_CLOUD_JOB_ID', '') != '' -%}

    {%- if dominio is none -%}
        {%- set resultado = target.schema | trim | upper -%}
        {%- set motivo = 'el modelo no declara +schema' -%}
    {%- elif es_job -%}
        {%- set resultado = dominio -%}
        {%- set motivo = 'corrida de job: dominio literal' -%}
    {%- else -%}
        {%- set resultado = (target.schema | trim | upper) -%}
        {%- set motivo = 'Studio: prefijo personal' -%}
    {%- endif -%}

    {{- log('[SCHEMA] ' ~ (node.name if node is not none else '?')
            ~ ' | +schema=' ~ (custom_schema_name if custom_schema_name is not none else 'none')
            ~ ' | es_job=' ~ es_job
            ~ ' | target.schema=' ~ target.schema
            ~ ' | -> ' ~ resultado
            ~ ' (' ~ motivo ~ ')', info=True) -}}

    {{- resultado -}}

{%- endmacro %}