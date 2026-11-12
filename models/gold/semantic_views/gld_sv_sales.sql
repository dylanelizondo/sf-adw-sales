{{
    config(
        materialized='semantic_view',
        alias='sv_sales',
        copy_grants=true
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
--   * Product comes from the ADW_PRODUCTION mesh project (gld_dim_product).
--   * Store is the Type 2 snapshot gld_dim_store: the fact's store_key points at the store VERSION in
--     force on the order date, so group by store_id (stable) plus store_name.
--   * Dates come from adw_core's gld_dim_date, joined three times (role-playing): order_dates,
--     due_dates and ship_dates. ship_date is NULL until the order ships.
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
        COMMENT = 'Currency exchange rates for orders not sold in local currency',

    products AS {{ ref('ADW_PRODUCTION', 'gld_dim_product') }}
        PRIMARY KEY (product_key)
        WITH SYNONYMS = ('items sold', 'merchandise')
        COMMENT = 'Products sold (from the ADW_PRODUCTION project). Charge rows have no product',

    stores AS {{ ref('gld_dim_store') }}
        PRIMARY KEY (store_key)
        WITH SYNONYMS = ('resellers', 'shops', 'retailers')
        COMMENT = 'Reseller stores (Type 2: one row per store version). Individual customers have store Not Applicable',

    order_dates AS {{ ref('adw_core', 'gld_dim_date') }}
        PRIMARY KEY (date_key)
        COMMENT = 'Calendar for the date the order was placed',

    due_dates AS {{ ref('adw_core', 'gld_dim_date') }}
        PRIMARY KEY (date_key)
        COMMENT = 'Calendar for the date the order is due',

    ship_dates AS {{ ref('adw_core', 'gld_dim_date') }}
        PRIMARY KEY (date_key)
        COMMENT = 'Calendar for the date the order shipped'
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
    items_to_rates AS items (currency_rate_key) REFERENCES rates,
    items_to_products AS items (product_key) REFERENCES products,
    items_to_stores AS items (store_key) REFERENCES stores,
    items_to_order_dates AS items (order_date) REFERENCES order_dates,
    items_to_due_dates AS items (due_date) REFERENCES due_dates,
    items_to_ship_dates AS items (ship_date) REFERENCES ship_dates
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

    -- order date calendar ---------------------------------------------------------
    order_dates.order_year AS order_dates.year
        WITH SYNONYMS = ('year', 'sales year')
        COMMENT = 'Calendar year of the order date',
    order_dates.order_quarter AS order_dates.quarter
        WITH SYNONYMS = ('quarter')
        COMMENT = 'Calendar quarter (1-4) of the order date',
    order_dates.order_month AS order_dates.month
        COMMENT = 'Calendar month number (1-12) of the order date',
    order_dates.order_month_name AS order_dates.monthname
        WITH SYNONYMS = ('month')
        COMMENT = 'Month name of the order date (e.g. Jan, Feb)',
    order_dates.order_week AS order_dates.weekofyear
        COMMENT = 'Week of the year of the order date',
    order_dates.order_day_name AS order_dates.dayname
        WITH SYNONYMS = ('weekday', 'day of week')
        COMMENT = 'Day of the week of the order date (e.g. Mon, Tue)',
    order_dates.order_month_end AS order_dates.last_day_of_month
        COMMENT = 'Last day of the month of the order date, to group by month as a date',

    -- due and ship date calendars ---------------------------------------------------
    due_dates.due_year AS due_dates.year COMMENT = 'Calendar year of the due date',
    due_dates.due_month AS due_dates.month COMMENT = 'Calendar month number of the due date',
    ship_dates.ship_year AS ship_dates.year COMMENT = 'Calendar year of the ship date; NULL if not shipped',
    ship_dates.ship_month AS ship_dates.month COMMENT = 'Calendar month number of the ship date; NULL if not shipped',

    -- stores -----------------------------------------------------------------------
    stores.store_id AS store_id
        COMMENT = 'Stable store id, the same across all versions of a store',
    stores.store_name AS store_name
        WITH SYNONYMS = ('store', 'reseller', 'shop')
        COMMENT = 'Store name',
    stores.store_business_type AS store_business_type
        WITH SYNONYMS = ('business type')
        COMMENT = 'Type of business of the store',
    stores.store_specialty AS store_specialty
        WITH SYNONYMS = ('specialty')
        COMMENT = 'What the store specializes in selling',
    stores.store_year_opened AS store_year_opened
        COMMENT = 'Year the store opened',
    stores.store_square_feet AS store_square_feet
        COMMENT = 'Store size in square feet',
    stores.store_number_employees AS store_number_employees
        COMMENT = 'Number of employees of the store',
    stores.store_account_manager AS sales_person_full_name
        WITH SYNONYMS = ('account manager')
        COMMENT = 'Salesperson assigned to manage the store. Not the person who processed the sale',

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

    -- products ---------------------------------------------------------------------
    products.product_name AS product_name
        WITH SYNONYMS = ('product', 'item')
        COMMENT = 'Product name',
    products.product_number AS product_number
        COMMENT = 'Product number (SKU)',
    products.category_name AS category_name
        WITH SYNONYMS = ('product category', 'category')
        COMMENT = 'Product category (e.g. Bikes, Components, Clothing, Accessories)',
    products.subcategory_name AS subcategory_name
        WITH SYNONYMS = ('product subcategory', 'subcategory')
        COMMENT = 'Product subcategory',
    products.model_name AS model_name
        COMMENT = 'Product model name',

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

AI_SQL_GENERATION 'Total sales, revenue and net sales mean total_sales, which sums line totals after discount and excludes tax and freight. Use total_tax and total_freight for those amounts. Charge rows (is_order_charge = TRUE) hold only tax and freight, so never count them as order lines; use line_count for lines and order_count for orders. A salesperson is the person who processed the sale, not the store account manager. Online orders have no salesperson. Round currency amounts to 2 decimal places. For product rankings use product_name with total_sales; charge rows have no product and carry no line sales. For any top-N or ranking, exclude rows where the ranked measure is NULL (or where the dimension is Not Applicable or Missing) and order with NULLS LAST. A store is a reseller customer; individual customers have the store Not Applicable, so exclude it from store rankings. Store data is versioned, so group stores by store_id and store_name, and never use store_account_manager when the user asks who sold. Use the order date calendar (order_year, order_quarter, order_month, order_month_name) unless the user mentions the ship date or due date, then use ship_year or due_year. Do not add a date filter unless the user asks for a period, and do not assume what the current or last year is: the data covers 2022 to 2025, so for relative periods use the latest order_year available. When asked about trends, group by order_year and order_month.'

AI_QUESTION_CATEGORIZATION 'This view answers questions about sales orders: sales amounts, quantities, discounts, tax, freight, customers, territories, salespeople, promotions, payment cards and shipping. Product cost, inventory, production, purchasing, finance and HR questions are out of scope; say they cannot be answered from this view. Product names, numbers, categories and subcategories are available for slicing sales. Store names, types, specialties, sizes and account managers are available for slicing sales, and so are order, due and ship dates by year, quarter, month and weekday. If the question is ambiguous about the measure (for example just "how much"), ask whether the user means net sales, quantity or order count.'
