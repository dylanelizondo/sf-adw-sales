{{
    config(
        materialized='semantic_view',
        alias='sv_sales',
        copy_grants=true,
        persist_docs={'relation': false, 'columns': false}
    )
}}

-- sv_sales
-- Semantic view over the sales star schema (gld_fct_order_line + its conformed dimensions), built
-- for Cortex Analyst / Snowflake Intelligence and any SQL or BI tool.
--
-- Notes:
--   * persist_docs is off: the package does not support it. Descriptions live in the COMMENT
--     clauses below, so keep them in sync with the .yml files by hand.
--   * Clause order matters in Snowflake: COMMENT, then AI_SQL_GENERATION, then
--     AI_QUESTION_CATEGORIZATION. The two AI_* clauses take NO "=".
--   * dbt_semantic_view issue #20: the package may place these AI_* clauses wrongly in the
--     generated DDL. If compile/run fails with "unexpected 'AI_SQL_GENERATION'", see the README
--     note for this model.
--   * Not included yet: product (ADW_PRODUCTION mesh project), store (Type 2) and dim_date.
--   * Charge rows (is_order_charge = true) carry only tax_amt and freight; product lines carry
--     only the line measures. Metrics are defined so they never mix the two.

TABLES (
    items AS {{ ref('gld_fct_order_line') }}
        PRIMARY KEY (order_lines_key)
        COMMENT = 'One row per sales order line, plus one charge row per order with tax or freight',

    clients AS {{ ref('gld_dim_client') }}
        PRIMARY KEY (client_key)
        WITH SYNONYMS = ('customers', 'buyers')
        COMMENT = 'Customers: individuals or resellers (stores)',

    territories AS {{ ref('gld_dim_territory') }}
        PRIMARY KEY (territory_key)
        WITH SYNONYMS = ('regions', 'sales territories')
        COMMENT = 'Sales territories',

    bill_to AS {{ ref('gld_dim_address') }}
        PRIMARY KEY (address_key)
        COMMENT = 'Billing address of the order',

    ship_to AS {{ ref('gld_dim_address') }}
        PRIMARY KEY (address_key)
        COMMENT = 'Shipping address of the order',

    sales_people AS {{ ref('gld_dim_sales_person') }}
        PRIMARY KEY (sales_person_key)
        WITH SYNONYMS = ('salespeople', 'sellers', 'reps')
        COMMENT = 'Salesperson who processed the sale (not the store account manager)',

    cards AS {{ ref('gld_dim_credit_card') }}
        PRIMARY KEY (credit_card_key)
        COMMENT = 'Credit card used to pay the order',

    profiles AS {{ ref('gld_dim_order_profile') }}
        PRIMARY KEY (order_profile_key)
        COMMENT = 'Order status, sales channel and shipped flag',

    offers AS {{ ref('gld_dim_special_offer') }}
        PRIMARY KEY (special_offer_key)
        WITH SYNONYMS = ('promotions', 'discount programs')
        COMMENT = 'Special offers applied to order lines',

    ship_methods AS {{ ref('gld_dim_ship_method') }}
        PRIMARY KEY (ship_method_key)
        WITH SYNONYMS = ('carriers', 'shipping methods')
        COMMENT = 'Shipping methods',

    rates AS {{ ref('gld_dim_currency_rate') }}
        PRIMARY KEY (currency_rate_key)
        COMMENT = 'Currency exchange rates for orders not sold in local currency'
)

RELATIONSHIPS (
    items_to_clients AS items (customer_key) REFERENCES clients,
    items_to_territories AS items (territory_key) REFERENCES territories,
    items_to_bill_to AS items (bill_to_address_key) REFERENCES bill_to,
    items_to_ship_to AS items (ship_to_address_key) REFERENCES ship_to,
    items_to_sales_people AS items (sales_person_key) REFERENCES sales_people,
    items_to_cards AS items (credit_card_key) REFERENCES cards,
    items_to_profiles AS items (order_profile_key) REFERENCES profiles,
    items_to_offers AS items (special_offer_key) REFERENCES offers,
    items_to_ship_methods AS items (ship_method_key) REFERENCES ship_methods,
    items_to_rates AS items (currency_rate_key) REFERENCES rates
)

FACTS (
    items.order_qty_fact AS order_qty COMMENT = 'Units sold on the order line',
    items.unit_price_fact AS unit_price COMMENT = 'List price per unit before discount',
    items.unit_price_discount_fact AS unit_price_discount COMMENT = 'Discount applied per unit, as a fraction of the unit price',
    items.line_total_fact AS line_total COMMENT = 'Net amount of the order line after discount',
    items.tax_amt_fact AS tax_amt COMMENT = 'Order tax, only on charge rows',
    items.freight_fact AS freight COMMENT = 'Order freight, only on charge rows'
)

DIMENSIONS (
    -- orders -------------------------------------------------------------------
    items.sales_order_number AS sales_order_number
        WITH SYNONYMS = ('order number', 'SO number')
        COMMENT = 'Sales order number',
    items.purchase_order_number AS purchase_order_number
        COMMENT = 'Customer purchase order number',
    items.is_order_charge AS is_order_charge
        COMMENT = 'TRUE for the tax and freight charge row of an order; FALSE for product lines',
    items.order_date AS order_date
        WITH SYNONYMS = ('date of order', 'purchase date')
        COMMENT = 'Date the order was placed',
    items.due_date AS due_date
        COMMENT = 'Date the order is due',
    items.ship_date AS ship_date
        COMMENT = 'Date the order shipped; NULL if not shipped yet',
    items.order_year AS YEAR(order_date)
        COMMENT = 'Calendar year of the order date',
    items.order_month AS MONTH(order_date)
        COMMENT = 'Calendar month number (1-12) of the order date',
    items.order_quarter AS QUARTER(order_date)
        COMMENT = 'Calendar quarter (1-4) of the order date',

    -- order profile --------------------------------------------------------------
    profiles.order_status AS order_status_label
        WITH SYNONYMS = ('status')
        COMMENT = 'Order status',
    profiles.order_channel AS order_channel
        WITH SYNONYMS = ('channel', 'sales channel')
        COMMENT = 'Sales channel: online or offline',
    profiles.is_shipped AS is_shipped
        COMMENT = 'Whether the order has shipped',

    -- clients --------------------------------------------------------------------
    clients.client_name AS client_name
        WITH SYNONYMS = ('customer name')
        COMMENT = 'Customer name',
    clients.client_type AS client_type
        WITH SYNONYMS = ('customer type')
        COMMENT = 'Individual or store',
    clients.client_age_band AS client_age_band
        COMMENT = 'Age band of individual customers',
    clients.client_education AS client_education
        COMMENT = 'Education level of individual customers',
    clients.client_occupation AS client_occupation
        COMMENT = 'Occupation of individual customers',
    clients.client_is_home_owner AS client_is_home_owner
        COMMENT = 'Whether the individual customer owns a home',

    -- territories ----------------------------------------------------------------
    territories.territory_name AS territory_name
        WITH SYNONYMS = ('territory', 'region')
        COMMENT = 'Sales territory name',
    territories.territory_group AS territory_group
        WITH SYNONYMS = ('region group', 'geography')
        COMMENT = 'Group the territory belongs to (e.g. North America, Europe, Pacific)',
    territories.territory_country AS country_region_code
        COMMENT = 'Country or region code of the territory',

    -- addresses ------------------------------------------------------------------
    bill_to.bill_to_city AS city COMMENT = 'Billing city',
    bill_to.bill_to_state AS state_province_name COMMENT = 'Billing state or province',
    bill_to.bill_to_country AS country_region_code COMMENT = 'Billing country or region code',
    ship_to.ship_to_city AS city COMMENT = 'Shipping city',
    ship_to.ship_to_state AS state_province_name COMMENT = 'Shipping state or province',
    ship_to.ship_to_country AS country_region_code COMMENT = 'Shipping country or region code',

    -- salesperson ----------------------------------------------------------------
    sales_people.sales_person_name AS sales_person_full_name
        WITH SYNONYMS = ('salesperson', 'seller', 'rep')
        COMMENT = 'Salesperson who processed the sale',

    -- payment, promotion, shipping, currency ---------------------------------------
    cards.card_type AS card_type
        WITH SYNONYMS = ('payment method')
        COMMENT = 'Credit card brand',
    offers.special_offer AS special_offer_description
        WITH SYNONYMS = ('promotion', 'discount program')
        COMMENT = 'Special offer description',
    offers.special_offer_type AS special_offer_type COMMENT = 'Special offer type',
    offers.special_offer_category AS special_offer_category COMMENT = 'Special offer category',
    ship_methods.ship_method AS ship_method_name
        WITH SYNONYMS = ('carrier', 'shipping method')
        COMMENT = 'Shipping method',
    rates.from_currency AS from_currency_code COMMENT = 'Source currency of the exchange rate',
    rates.to_currency AS to_currency_code COMMENT = 'Target currency of the exchange rate'
)

METRICS (
    items.total_sales AS SUM(items.line_total_fact)
        WITH SYNONYMS = ('revenue', 'sales', 'net sales', 'sales amount')
        COMMENT = 'Net sales: sum of line totals after discount. Excludes tax and freight',
    items.total_quantity AS SUM(items.order_qty_fact)
        WITH SYNONYMS = ('units sold', 'quantity')
        COMMENT = 'Total units sold',
    items.gross_sales AS SUM(items.order_qty_fact * items.unit_price_fact)
        COMMENT = 'Sales before discount: quantity times list unit price',
    items.total_discount AS SUM(items.order_qty_fact * items.unit_price_fact * items.unit_price_discount_fact)
        WITH SYNONYMS = ('discount amount')
        COMMENT = 'Discount given: quantity times unit price times discount fraction',
    items.total_tax AS SUM(items.tax_amt_fact)
        WITH SYNONYMS = ('tax')
        COMMENT = 'Total tax on orders',
    items.total_freight AS SUM(items.freight_fact)
        WITH SYNONYMS = ('shipping cost', 'freight cost')
        COMMENT = 'Total freight on orders',
    items.order_count AS COUNT(DISTINCT items.sales_order_id)
        WITH SYNONYMS = ('number of orders', 'orders')
        COMMENT = 'Number of distinct sales orders',
    items.line_count AS COUNT(CASE WHEN items.is_order_charge = FALSE THEN items.order_lines_key END)
        WITH SYNONYMS = ('number of lines', 'order lines')
        COMMENT = 'Number of product order lines. Excludes tax and freight charge rows',
    items.average_unit_price AS AVG(items.unit_price_fact)
        COMMENT = 'Average list unit price per order line',
    items.customer_count AS COUNT(DISTINCT items.customer_key)
        WITH SYNONYMS = ('number of customers', 'buyers')
        COMMENT = 'Number of distinct customers who ordered'
)

COMMENT = 'Sales semantic view: order lines, tax and freight with customers, territories, salespeople, promotions and shipping. Source of truth for sales metrics in Cortex Analyst.'

AI_SQL_GENERATION 'Total sales, revenue and net sales mean total_sales, which sums line totals after discount and excludes tax and freight. Use total_tax and total_freight for those amounts. Charge rows (is_order_charge = TRUE) hold only tax and freight, so never count them as order lines; use line_count for lines and order_count for orders. A salesperson is the person who processed the sale, not the store account manager. Online orders have no salesperson. Round currency amounts to 2 decimal places. Do not add a date filter unless the user asks for a period; when asked about trends, group by order_year and order_month.'

AI_QUESTION_CATEGORIZATION 'This view answers questions about sales orders: sales amounts, quantities, discounts, tax, freight, customers, territories, salespeople, promotions, payment cards and shipping. Product catalog, product cost, inventory, production, purchasing, finance and HR questions are out of scope; say they cannot be answered from this view. If a question asks about products or stores, say product and store details are not available yet. If the question is ambiguous about the measure (for example just "how much"), ask whether the user means net sales, quantity or order count.'
