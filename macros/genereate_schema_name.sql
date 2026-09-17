{#-
    ---------------------------------------------------------------------------
    Controla el SCHEMA donde escribe cada modelo.

    El +schema de dbt_project.yml es el DOMINIO (SALES). Lo que hace este macro
    es decidir si se usa literal o con el nombre del desarrollador adelante:

      DBT_ENV_TYPE = dev     ->  DYLAN_SALES    (IDE: cada dev su sandbox)
      DBT_ENV_TYPE = deploy  ->  SALES          (jobs de UAT y PROD)

    El prefijo en modo dev sale de target.schema, o sea del schema que cada
    persona tiene en Studio -> Credentials. No hay que configurar nada mas:
    quien entre al IDE ya trae su schema personal.

    Por que el default es 'dev' y no 'deploy': si la variable falta, el peor
    caso posible es escribir en un schema personal, no encima de PROD.

    En dbt Cloud:
      DBT_ENV_TYPE   Project default = dev
                     User Acceptance Testing = deploy
                     Production = deploy
    ---------------------------------------------------------------------------
-#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set dominio = custom_schema_name | trim | upper
                      if custom_schema_name is not none else none -%}

    {%- if dominio is none -%}

        {#- El modelo no declara dominio: cae al schema del environment -#}
        {{ target.schema | trim | upper }}

    {%- elif env_var('DBT_ENV_TYPE', 'dev') | lower == 'dev' -%}

        {#- Sandbox personal: DYLAN_SALES -#}
        {{ target.schema | trim | upper }}

    {%- else -%}

        {#- Job de UAT o PROD: nombre limpio del dominio -#}
        {{ dominio }}

    {%- endif -%}

{%- endmacro %}