-- Purpose: put each line in order_items into a discount band, and check if every band has enough lines to be reliable
-- Method: 0% (full price) as its own band, then 10-point bands up to 60%;
--         lower bound included (e.g. 10% falls in 10%-20%), 60% included in the last band, then count the number of lines in each band
-- Outcome: all 397,569 lines assigned (no 'unassigned');
--          smallest band is 50%-60% with 7,435 lines, so all bands are reliable.
--          10-point bands chosen over 5-point: easier to read in a chart, more lines per band (more stable averages).
--          Trade-off: the threshold can only be located within 10 points.
--          If more precision is needed, we can then zoom in with 5% bands.
-- Note: a "line" = one product in an order (one row in order_items)


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
FROM `analytics-reboot.ecommerce.order_items`
GROUP BY discount_band
ORDER BY discount_band;

-- Results:
-- Row	discount_band	line_count
-- 1	0%	51476
-- 2	0%-10%	115040
-- 3	10%-20%	132328
-- 4	20%-30%	49819
-- 5	30%-40%	23230
-- 6	40%-50%	18241
-- 7	50%-60%	7435
