-- =============================================================================
-- upd_shopping_cart_item_date_created.sql
-- Snowflake one-off script
--
-- PURPOSE
--   Update SHOPPING_CART_ITEM.DATE_CREATED with the ORDER_DATE of the most
--   recent sales order placed by the same customer, and set MODIFIED_DATE to
--   the current timestamp.
--
-- JOIN LOGIC
--   SHOPPING_CART_ITEM has no direct FK to SALES_ORDER_HEADER.
--   The link is:  SHOPPING_CART_ITEM.shopping_cart_id
--                 → the cart belongs to a customer session
--                 → joined via SALES.CUSTOMER.customer_id
--                 → to SALES_ORDER_HEADER.customer_id
--   Because a customer may have many orders, we take the MOST RECENT order_date
--   (MAX) as the reference point for the cart.
--   Cart items with no matching order keep their original DATE_CREATED (no update).
--
-- EXECUTION ORDER
--   1. Create the temp table with the resolved dates.
--   2. Inspect the temp table before committing (optional sanity check).
--   3. Run the UPDATE against the target table.
--   4. Drop the temp table.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1 — Build temp table with one row per cart item + resolved order_date
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE tmp_shopping_cart_date_update AS

SELECT
    sci.shopping_cart_item_id,
    sci.shopping_cart_id,
    sci.product_id,
    MAX(TRY_TO_DATE(soh.order_date)) AS resolved_order_date
FROM ADVENTURE_WORKS.SALES.SHOPPING_CART_ITEM          AS sci
INNER JOIN ADVENTURE_WORKS.SALES.CUSTOMER              AS c
    ON sci.shopping_cart_id = c.customer_id            -- cart session maps to customer
INNER JOIN ADVENTURE_WORKS.SALES.SALES_ORDER_HEADER    AS soh
    ON c.customer_id = soh.customer_id
GROUP BY
    sci.shopping_cart_item_id,
    sci.shopping_cart_id,
    sci.product_id;


-- -----------------------------------------------------------------------------
-- STEP 2 — Sanity check: review what will be updated before committing
-- -----------------------------------------------------------------------------
SELECT
    t.shopping_cart_item_id,
    t.shopping_cart_id,
    t.product_id,
    sci.date_created                        AS date_created_before,
    t.resolved_order_date                   AS date_created_after,
    sci.modified_date                       AS modified_date_before,
    CURRENT_TIMESTAMP()                     AS modified_date_after
FROM tmp_shopping_cart_date_update          AS t
INNER JOIN ADVENTURE_WORKS.SALES.SHOPPING_CART_ITEM AS sci
    ON t.shopping_cart_item_id = sci.shopping_cart_item_id
ORDER BY t.shopping_cart_item_id;


-- -----------------------------------------------------------------------------
-- STEP 3 — Apply the update
-- -----------------------------------------------------------------------------
UPDATE ADVENTURE_WORKS.SALES.SHOPPING_CART_ITEM AS sci
SET
    sci.date_created  = t.resolved_order_date,
    sci.modified_date = CURRENT_TIMESTAMP()
FROM tmp_shopping_cart_date_update AS t
WHERE sci.shopping_cart_item_id = t.shopping_cart_item_id;


-- -----------------------------------------------------------------------------
-- STEP 4 — Clean up
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_shopping_cart_date_update;
