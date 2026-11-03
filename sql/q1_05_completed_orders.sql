-- Purpose: rerun Q1 profitability by discount band using completed orders only.
-- Why: order_items includes lines from cancelled, returned and pending orders, which did not
--      (or not yet) generate real profit. Including them overstates profit.
--      order_status only exists in sales_customer_analytics, so we join it to order_items on order_id.
-- Decision: keep only 'Completed'. Pending is excluded as well (conservative: count only profit
--           actually earned). Trade-off: pending orders are likely the most recent ones (~5% of orders).
-- Note: a "line" = one product in an order (one row in order_items).
--       All money and quantity columns are taken from order_items (i.), our source of truth.
--       Same discount bands as q1_02_discount_bands.sql.
--       Currency: amounts are treated as USD. The data labels orders in 7 currencies but never converts
--       them (average order values are the same in every currency), so the values behave as one currency.
--       USD is the most common label (~60% of orders) and is used in the dataset's own summary file.
--
-- Outcome:
--   1. The Q1 finding holds on completed orders: CM per line changes by less than USD 1 in every band.
--      - No discount band earns as much per purchase as full price (0% band: USD 214.22 per purchase).
--      - At 40-50% discount, profit per purchase is USD 22.30, about 90% lower than at full price.
--      - At 50-60% discount, profit per purchase is -USD 71.27: each purchase loses money.
--      - Recommendation: keep discounts below 40%.
--   2. Data artefact found: 93% of lines in cancelled and returned orders are at 0% discount,
--      vs ~1% in completed and pending orders. The extreme, near-identical pattern for cancelled
--      and returned orders points to a rule in the synthetic data, not real customer behaviour.
--      As a result, 93% of the 0% band in q1_03_discount_band_profitability.sql came from cancelled
--      or returned orders. This file (completed orders only) is the version to use for Q1.
--   3. Among completed orders, only ~1% of lines sell at full price: almost every real sale is discounted.
--      The 0% band still has 3,441 lines, enough for a reliable baseline.


-- Step 1: check the join is safe (every line in order_items finds its order)
SELECT
  COUNT(*) AS total_lines
  ,COUNTIF(o.order_id IS NULL) AS lines_without_matching_order
FROM `analytics-reboot.ecommerce.order_items` AS i
LEFT JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
  ON i.order_id = o.order_id;

-- Result: total_lines 397,569 | lines_without_matching_order 0
-- All lines find their order, so an inner join will not lose any lines.


-- Step 2: lines per order status
SELECT
  o.order_status
  ,COUNT(*) AS line_count
FROM `analytics-reboot.ecommerce.order_items` AS i
JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
  ON i.order_id = o.order_id
GROUP BY o.order_status
ORDER BY line_count DESC;

-- Result:
-- Completed  327,028
-- Returned    27,209
-- Cancelled   24,109
-- Pending     19,223
-- The four counts add up to 397,569: no lines lost or duplicated by the join.
-- Excluding returned, cancelled and pending removes 70,541 lines (17.7%); 327,028 lines (82.3%) remain.


-- Step 3: profitability by discount band, completed orders only (amounts in USD)
SELECT
  CASE
    WHEN i.discount_percentage = 0 THEN '0%'
    WHEN i.discount_percentage > 0 AND i.discount_percentage < 0.1 THEN '0%-10%'
    WHEN i.discount_percentage >= 0.1 AND i.discount_percentage < 0.2 THEN '10%-20%'
    WHEN i.discount_percentage >= 0.2 AND i.discount_percentage < 0.3 THEN '20%-30%'
    WHEN i.discount_percentage >= 0.3 AND i.discount_percentage < 0.4 THEN '30%-40%'
    WHEN i.discount_percentage >= 0.4 AND i.discount_percentage < 0.5 THEN '40%-50%'
    WHEN i.discount_percentage >= 0.5 AND i.discount_percentage <= 0.6 THEN '50%-60%'
    ELSE 'unassigned'
  END AS discount_band
  ,COUNT(*) AS line_count
  ,ROUND(AVG(i.quantity), 2) AS avg_units_per_line
  ,ROUND(SUM(i.gross_sales - i.discount_amount - i.shipping_cost - i.product_cost) / SUM(i.quantity), 2) AS cm_per_unit
  ,ROUND(SUM(i.gross_sales - i.discount_amount - i.shipping_cost - i.product_cost) / COUNT(*), 2) AS cm_per_line
FROM `analytics-reboot.ecommerce.order_items` AS i
JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
  ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY discount_band
ORDER BY discount_band;

-- Result (completed orders only; cm_per_unit and cm_per_line in USD):
-- discount_band  line_count  avg_units_per_line  cm_per_unit  cm_per_line
-- 0%                  3,441        1.89              113.22       214.22
-- 0%-10%            107,520        1.89              101.62       191.58
-- 10%-20%           123,795        1.88               76.90       144.59
-- 20%-30%            46,493        2.37               55.03       130.45
-- 30%-40%            21,740        3.30               31.73       104.83
-- 40%-50%            17,062        3.32                6.71        22.30
-- 50%-60%             6,977        3.30              -21.60       -71.27
-- Compared with q1_03_discount_band_profitability.sql (all orders): CM per line changes by < USD 1 in every band.
-- But the 0% band shrinks from 51,476 to 3,441 lines (-93%); other bands shrink by only ~6-7%.


-- Step 4: discount pattern by order status (explains the drop in the 0% band)
SELECT
  o.order_status
  ,COUNT(*) AS line_count
  ,ROUND(COUNTIF(i.discount_percentage = 0) / COUNT(*), 3) AS share_full_price
  ,ROUND(AVG(i.discount_percentage), 3) AS avg_discount
FROM `analytics-reboot.ecommerce.order_items` AS i
JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
  ON i.order_id = o.order_id
GROUP BY o.order_status
ORDER BY o.order_status;

-- Result:
-- order_status  line_count  share_full_price  avg_discount
-- Cancelled         24,109        0.933           0.012
-- Completed        327,028        0.011           0.167
-- Pending           19,223        0.010           0.166
-- Returned          27,209        0.932           0.012
-- Cancelled and returned orders are almost all at 0% discount, with near-identical values;
-- completed and pending look alike. This looks like a data generation rule, not customer behaviour.
