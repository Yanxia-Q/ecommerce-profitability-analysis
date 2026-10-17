-- Purpose: check when we give discounts, how many units are sold per line, and how much contribution margin is earned per unit and per line
-- Method: Calculate contribution margin per unit and per line for each discount band (Same discount bands as 03_discount_bands.sql), then compare to the 0% baseline
-- Outcome: No discount level earns as much profit per purchase as selling at full price.
--          Discounts of 20–30% partly offset the loss, as customers buy 26% more units per purchase.
--          But above 40%, profit per purchase drops by around 90% compared with full price, and discounts above 50% make every purchase unprofitable.
--          To protect profitability, discounts should stay below 40%.
--          Note: discounts under 20% don't increase units at all, but this data only shows units per purchase. Small discounts might still bring in more orders or new customers, which we can't measure here.
--          Check: avg units per line × CM per unit ≈ CM per line (differences due to rounding only)
-- Note: a "line" = one product in an order (one row in order_items)

-- Definitions:
--contribution margin = gross_sales - discount_amount - shipping_cost - product_cost
--total contribution margin in a band = SUM (gross_sales - discount_amount - shipping_cost - product_cost)
--contribution margin per unit = SUM (gross_sales - discount_amount - shipping_cost - product_cost) / SUM (quantity)
--contribution margin per line = SUM (gross_sales - discount_amount - shipping_cost - product_cost) / COUNT(*)


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
  ,ROUND(AVG (quantity),2) AS avg_units_per_line
  ,ROUND(SUM (gross_sales - discount_amount - shipping_cost - product_cost) / SUM (quantity),2) AS cm_per_unit
  ,ROUND(SUM (gross_sales - discount_amount - shipping_cost - product_cost) / COUNT(*),2) AS cm_per_line
FROM `analytics-reboot.ecommerce.order_items`
GROUP BY discount_band
ORDER BY discount_band;

-- Results:
-- Row	discount_band	line_count	avg_units_per_line	cm_per_unit	cm_per_line
-- 1	0%	51476	1.88	113.92	214.49
-- 2	0%-10%	115040	1.88	101.68	191.63
-- 3	10%-20%	132328	1.88	76.85	144.41
-- 4	20%-30%	49819	2.37	55.0	130.36
-- 5	30%-40%	23230	3.3	31.62	104.47
-- 6	40%-50%	18241	3.32	6.65	22.09
-- 7	50%-60%	7435	3.3	-21.46	-70.82
