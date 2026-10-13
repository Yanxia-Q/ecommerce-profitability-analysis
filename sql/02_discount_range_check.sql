-- Purpose: check the full range of discounts before defining Q1 discount bands
-- Method: MIN/MAX of discount_percentage across all lines in order_items,
--         plus the number of full-price lines (the 0% baseline band)
-- Outcome: discounts range from 0% to 60%; 51,476 of 397,569 lines (12.9%)
--          are at full price, which is enough for a reliable baseline
-- Note: a "line" = one product in an order (one row in order_items)


SELECT
MIN(discount_percentage) AS min_discount
,MAX(discount_percentage) AS max_discount
,COUNTIF(discount_percentage = 0) AS full_price_lines
,COUNT(*) AS total_lines
FROM `analytics-reboot.ecommerce.order_items`;

-- Results: min_discount 0.0	max_discount 0.6	full_price_lines 51,476	total_lines 397,569
