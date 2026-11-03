-- Purpose: find which product categories generate high revenue but relatively little profit, and why.
-- Method: Step 1: net revenue, contribution margin (CM) and CM % per category, completed orders only.
--         Shares of total revenue and total CM were then calculated in Google Sheets.
--         Step 2: discount rate, product cost % and shipping cost % per category, to explain the CM % differences.
-- Outcome: No category is loss-making; all have a positive CM.
--          The four largest categories (Electronics, Jewelry, Home Appliances, Automotive) generate 56.7% of
--          net revenue but only 49.4% of CM, with the lowest CM % (25-33% vs 37-45% for the rest).
--          Electronics is the biggest gap: 21.6% of revenue, 15.8% of CM.
--          Cause: product cost, not discounts. Discount rates are ~19-20% in every category, while product cost
--          takes 66-75% of revenue in the big four vs 46-61% in the others.
--          Shipping hits small, low-priced categories hardest (Books & Media 11%, Grocery 9% of revenue).
-- Note: a "line" = one product in an order (one row in order_items).
--       Amounts in USD (7 currency labels in the data, never converted; USD is the most common).


-- Step 1: revenue and profitability by product category
SELECT
  p.product_category
  ,COUNT(*) AS total_lines
  ,ROUND(CAST(SUM(i.gross_sales - i.discount_amount) AS NUMERIC), 2) AS net_revenue
  ,ROUND(CAST(SUM(i.gross_sales - i.discount_amount - i.product_cost - i.shipping_cost) AS NUMERIC), 2) AS contribution_margin
  ,ROUND(SAFE_DIVIDE(SUM(i.gross_sales - i.discount_amount - i.product_cost - i.shipping_cost), SUM(i.gross_sales - i.discount_amount)),3) AS cm_pct
FROM `analytics-reboot.ecommerce.order_items` AS i
JOIN `analytics-reboot.ecommerce.product_catalog` AS p
  ON i.product_id = p.product_id
JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
  ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_category
ORDER BY net_revenue DESC;

-- Result:
-- Row	product_category	total_lines	net_revenue	contribution_margin	cm_pct
-- 1	Electronics	21674	30071415.82	7496257.16	0.249
-- 2	Jewelry	19124	18630542.94	5981115.71	0.321
-- 3	Home Appliances	21713	18168346.14	5970885.91	0.329
-- 4	Automotive	22506	11881224.9	3589499.63	0.302
-- 5	Sports & Outdoors	25180	11365547.64	4270603.95	0.376
-- 6	Home & Kitchen	19263	7937831.01	3109273.5	0.392
-- 7	Baby & Kids	21074	7029594.1	2926991.86	0.416
-- 8	Health & Wellness	24007	6608407.52	2460445.33	0.372
-- 9	Office Supplies	22314	6365291.33	2780343.45	0.437
-- 10	Fashion	18945	5350862.76	2193998.08	0.41
-- 11	Pet Supplies	20523	4546984.46	1923356.34	0.423
-- 12	Toys & Games	21760	3880529.94	1643615.36	0.424
-- 13	Beauty & Personal Care	23143	3314845.85	1429242.22	0.431
-- 14	Grocery	21750	2041907.69	919164.16	0.45
-- 15	Books & Media	24052	1900883.56	767293.62	0.404

-- Step 2: why are some categories more profitable than others?
SELECT
  p.product_category
  ,ROUND(CAST(SUM(i.gross_sales - i.discount_amount) AS NUMERIC), 2) AS net_revenue
  ,COUNT(*) AS total_lines
  ,ROUND(SAFE_DIVIDE(SUM(i.discount_amount), SUM(i.gross_sales)),3) AS discount_rate
  ,ROUND(SAFE_DIVIDE(SUM(i.product_cost), SUM(i.gross_sales - i.discount_amount)),3) AS product_cost_pct
  ,ROUND(SAFE_DIVIDE(SUM(i.shipping_cost), SUM(i.gross_sales - i.discount_amount)),3) AS shipping_cost_pct
FROM `analytics-reboot.ecommerce.order_items` AS i
JOIN `analytics-reboot.ecommerce.product_catalog` AS p
  ON i.product_id = p.product_id
JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
  ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_category
ORDER BY net_revenue DESC;

-- Result:
-- Row	product_category	net_revenue	total_lines	discount_rate	product_cost_pct	shipping_cost_pct
-- 1	Electronics	30071415.82	21674	0.191	0.745	0.006
-- 2	Jewelry	18630542.94	19124	0.194	0.67	0.009
-- 3	Home Appliances	18168346.14	21713	0.196	0.661	0.01
-- 4	Automotive	11881224.9	22506	0.192	0.682	0.016
-- 5	Sports & Outdoors	11365547.64	25180	0.193	0.606	0.019
-- 6	Home & Kitchen	7937831.01	19263	0.194	0.588	0.021
-- 7	Baby & Kids	7029594.1	21074	0.196	0.559	0.025
-- 8	Health & Wellness	6608407.52	24007	0.195	0.597	0.031
-- 9	Office Supplies	6365291.33	22314	0.193	0.534	0.029
-- 10	Fashion	5350862.76	18945	0.194	0.56	0.03
-- 11	Pet Supplies	4546984.46	20523	0.195	0.539	0.038
-- 12	Toys & Games	3880529.94	21760	0.194	0.53	0.047
-- 13	Beauty & Personal Care	3314845.85	23143	0.194	0.511	0.058
-- 14	Grocery	2041907.69	21750	0.193	0.46	0.09
-- 15	Books & Media	1900883.56	24052	0.192	0.49	0.107
