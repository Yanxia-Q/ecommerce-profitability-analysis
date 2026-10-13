SELECT
MIN(discount_percentage) AS min_discount
,MAX(discount_percentage) AS max_discount
,COUNTIF(discount_percentage = 0) AS full_price_lines
,COUNT(*) AS total_lines
FROM `analytics-reboot.ecommerce.order_items`

-- Results:
min_discount 0.0	max_discount 0.6	full_price_lines 51,476	total_lines 397,569
