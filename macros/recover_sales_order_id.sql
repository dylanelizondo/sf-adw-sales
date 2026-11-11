{#-
    ---------------------------------------------------------------------------
    SALES_ORDER_ID -> whole number, for the silver layer (backlog B-04).

    In ADVENTURE_WORKS the order key arrives as TEXT and is corrupted: a value that
    should be an integer such as 43659 shows up as a date (see to_silver_date, which
    must NOT be used on this column). The corruption looks like an Excel date serial:
    day 43659 counted from 1899-12-30 is 2019-07-13, so counting the days back gives
    the original integer.

    The macro accepts both shapes so a clean key is never damaged:
      '43659'       -> 43659                         (already a whole number)
      '2019-07-13'  -> 43659                         (date serial, recovered)
      anything else -> NULL                          (the model drops these rows)

    THIS IS A HYPOTHESIS, not a verified rule. Two silver tests guard it, so a wrong
    guess fails the build instead of silently mangling the key:
      - <model>__row_count_matches_source: no row may be dropped
      - slv_adventure_works_sales__sales_order_header__order_id_in_expected_range:
        recovered ids must fall in the AdventureWorks range 43659 to 75123

    Use it on the order key in the header, the detail and the order/reason bridge so
    all three recover the key the same way and still join.
    ---------------------------------------------------------------------------
-#}

{% macro recover_sales_order_id(column) -%}
    coalesce(
        try_to_number(trim({{ column }}::varchar)),
        datediff('day', '1899-12-30'::date, try_to_date(trim({{ column }}::varchar), 'YYYY-MM-DD'))
    )::number(38,0)
{%- endmacro %}
