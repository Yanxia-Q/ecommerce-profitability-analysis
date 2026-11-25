-- Purpose: find which brands generate high revenue but relatively little profit, compared with their own category.
-- Method: Step 1: net revenue and contribution margin (CM) per brand, completed orders only.
--         Step 2: brand CM %, its category's CM % (the benchmark) and the brand's share of its category's revenue,
--                 using window functions (SUM(...) OVER (PARTITION BY product_category)).
--         Step 3: gap = brand CM % - category CM %, and a flag applying the definitions below.
--         Brands are grouped by category AND brand, so the 7 brands that sell in two categories are assessed in each.
--         Brands are compared within their category, not across categories, because normal margins differ by
--         category (see docs/q2_revenue_vs_profit_analysis.md, section 3.5).
--         The flag is calculated on unrounded values: rounding can hide a brand just past a threshold
--         (e.g. Pure Vitamin's gap is -0.0302, displayed as -0.03).
-- Outcome: 151 rows (144 brands, 7 of them in two categories). Smallest brand: Lenovo (Electronics), 556 lines,
--          so every brand is large enough to be reliable.
--          13 brands are flagged (high revenue, CM % more than 3 points below their category), across 11 categories.
--          Castrol, Gerber and Hasbro are flagged under every threshold tested (revenue share 8-12%, gap -2 to -5 points).
--          No Electronics brand is flagged: the Electronics issue is the whole category's product cost, not one weak brand.
--          If all 13 brands reached their category's CM %, CM would rise by about USD 0.66M over 2021-2025
--          (1.4% of total CM).
-- Note: a "line" = one product in an order (one row in order_items).
--       Amounts in USD (7 currency labels in the data, never converted; USD is the most common).


-- Definitions (see docs/q2_revenue_vs_profit_analysis.md, section 3.6)
DECLARE min_revenue_share FLOAT64 DEFAULT 0.10;  -- "high revenue": more than 10% of its category's net revenue
DECLARE max_cm_pct_gap    FLOAT64 DEFAULT -0.03; -- "little profit": CM % more than 3 points below its category's CM %


-- Step 1: one row per brand (within its category), with its totals
WITH brand_totals AS (
  SELECT
    p.product_category
    ,p.brand
    ,COUNT(*) AS total_lines
    ,SUM(i.gross_sales - i.discount_amount) AS net_revenue
    ,SUM(i.gross_sales - i.discount_amount - i.product_cost - i.shipping_cost) AS cm
  FROM `analytics-reboot.ecommerce.order_items` AS i
  JOIN `analytics-reboot.ecommerce.product_catalog` AS p
    ON i.product_id = p.product_id
  JOIN `analytics-reboot.ecommerce.sales_customer_analytics` AS o
    ON i.order_id = o.order_id
  WHERE o.order_status = 'Completed'
  GROUP BY p.product_category, p.brand
),

-- Step 2: brand CM %, its category's CM % and its share of category revenue
brand_vs_category AS (
  SELECT
    product_category
    ,brand
    ,total_lines
    ,net_revenue
    ,cm
    ,SAFE_DIVIDE(cm, net_revenue) AS cm_pct
    ,SAFE_DIVIDE(SUM(cm) OVER (PARTITION BY product_category),
                 SUM(net_revenue) OVER (PARTITION BY product_category)) AS category_cm_pct
    ,SAFE_DIVIDE(net_revenue, SUM(net_revenue) OVER (PARTITION BY product_category)) AS revenue_share_in_category
  FROM brand_totals
)

-- Step 3: the gap, the flag (on unrounded values), and rounding for display
SELECT
  product_category
  ,brand
  ,total_lines
  ,ROUND(CAST(net_revenue AS NUMERIC), 2) AS net_revenue
  ,ROUND(CAST(cm AS NUMERIC), 2) AS contribution_margin
  ,ROUND(cm_pct, 3) AS cm_pct
  ,ROUND(category_cm_pct, 3) AS category_cm_pct
  ,ROUND(cm_pct - category_cm_pct, 3) AS cm_pct_gap
  ,ROUND(revenue_share_in_category, 3) AS revenue_share_in_category
  ,(revenue_share_in_category > min_revenue_share
    AND cm_pct - category_cm_pct < max_cm_pct_gap) AS flagged
FROM brand_vs_category
ORDER BY product_category, net_revenue DESC;

-- Result: 151 rows. Flagged brands (flagged = true):
-- product_category        brand          revenue_share_in_category  cm_pct  category_cm_pct  cm_pct_gap
-- Automotive              Castrol        0.175                      0.249   0.302            -0.053
-- Baby & Kids             Gerber         0.158                      0.346   0.416            -0.071
-- Baby & Kids             Evenflo        0.112                      0.330   0.416            -0.086
-- Beauty & Personal Care  Clinique       0.110                      0.388   0.431            -0.043
-- Books & Media           Pearson        0.115                      0.351   0.404            -0.053
-- Fashion                 Zara           0.111                      0.362   0.410            -0.048
-- Health & Wellness       Pure Vitamin   0.106                      0.342   0.372            -0.030 (unrounded -0.0302)
-- Home & Kitchen          Wayfair        0.146                      0.347   0.392            -0.044
-- Jewelry                 Tiffany        0.106                      0.261   0.321            -0.060
-- Pet Supplies            Blue Buffalo   0.122                      0.378   0.423            -0.045
-- Pet Supplies            Petmate        0.111                      0.366   0.423            -0.057
-- Sports & Outdoors       Adidas         0.160                      0.340   0.376            -0.036
-- Toys & Games            Hasbro         0.145                      0.362   0.424            -0.062
--
-- Sensitivity (number of brands flagged):
--   revenue share threshold 8% / 10% / 12%  -> 16 / 13 / 6 brands (gap threshold -3 points)
--   gap threshold -2 / -3 / -5 points        -> 21 / 13 / 7 brands (revenue share threshold 10%)
