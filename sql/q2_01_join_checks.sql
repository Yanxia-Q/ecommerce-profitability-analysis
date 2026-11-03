-- Purpose: check if the product_catalog table is really one row per product, and if every line in order_items finds its product in product_catalog.
--          This is important because Q2 joins order_items to product_catalog to get category and brand,
--          and I want to make sure that the join won't duplicate any lines or lose any lines.
-- Method: count the total rows in product_catalog and the number of unique product_ids,
--         and count the total lines in order_items and the number of lines that don't find a category or brand in product_catalog.
-- Outcome: product_catalog is one row per product (1,175 rows, 1,175 unique products), so the join can't duplicate any lines.
--          All 397,569 lines find their product, with no missing category or brand, so the join is safe for Q2.
-- Note: a "line" = one product in an order (one row in order_items)


-- Step 1: is product_catalog one row per product?
SELECT
  COUNT(*) AS total_rows
  ,COUNT(DISTINCT product_id) AS unique_products
FROM `analytics-reboot.ecommerce.product_catalog`;

-- Result: total_rows 1,175 | unique_products 1,175


-- Step 2: does every line find its product (with category and brand)?
SELECT
  COUNT(*) AS total_lines
  ,COUNTIF(p.product_category IS NULL) AS lines_missing_category
  ,COUNTIF(p.brand IS NULL) AS lines_missing_brand
FROM `analytics-reboot.ecommerce.order_items` AS i
LEFT JOIN `analytics-reboot.ecommerce.product_catalog` AS p
  ON i.product_id = p.product_id;

-- Result: total_lines 397,569 | lines_missing_category 0 | lines_missing_brand 0
