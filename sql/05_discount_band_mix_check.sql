-- Purpose: check apart from the discount, if the unit price, product cost, and shipping cost are different for different discount bands and if they affect profitability in each band
-- Method: calculate average unit price, cost per unit and average shipping cost per line for each discount band (same discount bands as 03_discount_bands.sql), then compare to the 0% baseline
-- Outcome: unit price (243–247), cost per unit (124–127) and shipping per line (6.6–8.6) are nearly identical across bands, so they do not explain the profit decline; the discount is the main driver.
--          Not ruled out: factors outside the data, e.g. timing (sales events) or marketing campaigns.



SELECT
CASE
  WHEN discount_percentage = 0 THEN '0%'
  WHEN discount_percentage > 0 AND discount_percentage < 0.1 THEN '0%-10%'
  WHEN discount_percentage >= 0.1 AND discount_percentage < 0.2 THEN '10%-20%'
  WHEN discount_percentage >= 0.2 AND discount_percentage < 0.3 THEN '20%-30%'
  WHEN discount_percentage >= 0.3 AND discount_percentage < 0.4 THEN '30%-40%'
  WHEN discount_percentage >= 0.4 AND discount_percentage < 0.5 THEN '40%-50%'
  WHEN discount_percentage >= 0.5 AND discount_percentage <= 0.6 THEN '50%-60%'
  ELSE 'unassigned'
END AS  discount_band
  ,COUNT(*) AS line_count
  ,ROUND(AVG(unit_price),2) AS avg_unit_price
  ,ROUND(SUM(product_cost)/SUM(quantity),2) AS cost_per_unit
  ,ROUND(AVG(shipping_cost),2) AS avg_shipping_per_line
FROM `analytics-reboot.ecommerce.order_items`
GROUP BY discount_band
ORDER BY discount_band;

-- Results:
-- Row	discount_band	line_count	avg_unit_price	cost_per_unit	avg_shipping_per_line
-- 1	0%	51476	245.15	126.2	8.41
-- 2	0%-10%	115040	246.51	127.44	8.62
-- 3	10%-20%	132328	244.2	125.43	8.56
-- 4	20%-30%	49819	245.41	126.48	7.81
-- 5	30%-40%	23230	243.74	125.87	8.39
-- 6	40%-50%	18241	246.23	126.55	8.43
-- 7	50%-60%	7435	243.02	123.94	6.59
