# E-commerce Profitability Analysis — Q2 Notes

## 1. Question 2
**Original question:** Which categories or brands generate high top-line revenue but little or negative true profit after accounting for discounts and shipping costs?

**In plain words:** Some categories and brands look important because they sell a lot. Do they also keep a fair share of profit, or does most of their revenue go to discounts, suppliers and shipping?

---

## 2. Metrics

*A "line" = one product in an order (one row in `order_items`).*

| Metric | How it's calculated | Source table | Columns needed |
|---|---|---|---|
| Net revenue | SUM(gross_sales − discount_amount) | order_items | gross_sales, discount_amount |
| Contribution margin (CM) | SUM(gross_sales − discount_amount − product_cost − shipping_cost) | order_items | gross_sales, discount_amount, product_cost, shipping_cost |
| CM % | CM ÷ net revenue | order_items | (as above) |
| Share of revenue / share of CM | Category revenue (or CM) ÷ total revenue (or CM) of all categories | calculated in Google Sheets | — |
| Category CM % (brand benchmark) | Category CM ÷ category net revenue, shown next to each brand | window function in SQL | (as CM) |
| CM % gap (brands) | Brand CM % − its category's CM %, in percentage points | calculated in SQL | (as CM) |
| Revenue share in category (brands) | Brand net revenue ÷ its category's net revenue | window function in SQL | gross_sales, discount_amount |
| Discount rate | SUM(discount_amount) ÷ SUM(gross_sales) | order_items | discount_amount, gross_sales |
| Product cost % | SUM(product_cost) ÷ SUM(gross_sales − discount_amount) | order_items | product_cost, gross_sales, discount_amount |
| Shipping cost % | SUM(shipping_cost) ÷ SUM(gross_sales − discount_amount) | order_items | shipping_cost, gross_sales, discount_amount |
| Category and brand | Joined from product_catalog on product_id | product_catalog | product_category, brand |
| Order status filter | Keep only completed orders | sales_customer_analytics (joined on order_id) | order_status |

**Why CM % and shares, not only CM in USD:** a big category always earns more dollars. CM % and the comparison of revenue share vs CM share show whether a category keeps a *fair* part of what it sells.

---

## 3. Method decisions

### 3.1 Profit definition: tax and shipping
The dataset calculates its own sales and profit columns as:

```
net_sales = gross_sales − discount_amount + tax_amount + shipping_cost
profit    = net_sales − shipping_cost − product_cost
```

- **Tax:** tax is added to sales but never subtracted. Since tax is collected on behalf of the government, including it would overstate profit. Tax is excluded and the dataset's `profit` column is not used.
- **Shipping:** treated as a cost absorbed by the business. Under the dataset's original logic, shipping is added to `net_sales` and then subtracted, so it would have no impact on profit, which would make Q2's "after shipping costs" meaningless.
- **Limitation of this choice:** if customers actually paid shipping, CM is slightly understated (conservative assumption).

```
net_revenue         = gross_sales − discount_amount
contribution_margin = gross_sales − discount_amount − product_cost − shipping_cost
```

### 3.2 Completed orders only
Decided **at the start** (lesson from Q1): only `Completed` orders are included. Cancelled and returned orders generated no real profit, pending orders not yet, and cancelled/returned lines carry an artificial 0% discount (data generation rule found in Q1).

### 3.3 Join checks
Q2 joins three tables: `order_items` (numbers), `product_catalog` (category and brand) and `sales_customer_analytics` (order status).
- `product_catalog` is one row per product (1,175 rows, 1,175 unique products), so the join cannot duplicate lines.
- All 397,569 lines find their product, with no missing category or brand.
- The join to `sales_customer_analytics` was already checked in Q1 (no lost or duplicated lines).

### 3.4 Currency
Amounts are treated as **USD**. The data labels orders in 7 currencies but never converts them (average order values are the same in every currency). USD is the most common label (~60% of orders).

### 3.5 Brand comparison: benchmark against the category
As normal margins vary significantly across categories (e.g. 25% for Electronics vs. 45% for Grocery), largely due to differences in product costs, cross-category comparisons could be misleading. To ensure a fair assessment, brands are benchmarked against their respective category's CM%. Brands present in two categories are evaluated independently in each category.

### 3.6 Definitions: "high revenue" and "little profit" (brands)
A brand is **flagged** when **both** conditions are true:

| Term | Definition | Why |
|---|---|---|
| **High revenue** | More than **10%** of its category's net revenue | Each category has about 10 brands, so 10% = bigger than an average brand in its category. Share of category (not USD) is used because a USD 300K brand is small in Electronics but large in Books & Media. |
| **Little profit** | CM % more than **3 percentage points below** its category's CM % (gap < −0.03) | The middle 50% of brands are between −2.7 and +2.3 points from their category's CM %, so −3 points marks a brand as clearly outside the normal range (roughly the weakest quarter). |

- *Percentage points vs percent:* a gap of 30.2% − 24.9% = 5.3 percentage points (a 17.5% relative difference). Gaps are always stated in percentage points.
- *Flags use unrounded values:* rounding can hide a brand just past a threshold (Pure Vitamin's gap is −0.0302, displayed as −0.03).
**Sensitivity check: would the list change with slightly different thresholds?**
Both thresholds are judgement calls, so each one was changed on its own (keeping the other fixed) to see how many brands get flagged:

| What was changed | Looser | **Our choice** | Stricter |
|---|---:|---:|---:|
| "High revenue": more than … of the category's revenue *(profit rule kept at 3 points)* | 8% → 16 brands | **10% → 13 brands** | 12% → 6 brands |
| "Little profit": more than … points below the category *(revenue rule kept at 10%)* | 2 points → 21 brands | **3 points → 13 brands** | 5 points → 7 brands |

**What it means:** the exact number of flagged brands depends on where the line is drawn, so "13 brands" is the result of our definitions, not a fixed fact. But **Castrol, Gerber and Hasbro are flagged in every version tested**, so they are the most reliable findings.

---

## 4. Analysis steps (SQL files on GitHub)

| File | What it does | Result |
|---|---|---|
| q2_01_join_checks | Catalog uniqueness and join completeness | Join is safe: no duplicated or lost lines |
| q2_02_category_profitability | Revenue, CM and CM % per category; discount, product cost and shipping % per category | Big four categories have the lowest CM %, driven by product cost |
| q2_03_brand_profitability | Revenue, CM, CM % per brand vs its category's CM %; revenue share in category; flag | 13 brands flagged; none in Electronics |

---

## 5. Results by category (completed orders only, USD)

| Category | Net revenue | CM | CM % | Share of revenue | Share of CM |
|---|---:|---:|---:|---:|---:|
| Electronics | 30,071,415.82 | 7,496,257.16 | 24.9% | 21.6% | 15.8% |
| Jewelry | 18,630,542.94 | 5,981,115.71 | 32.1% | 13.4% | 12.6% |
| Home Appliances | 18,168,346.14 | 5,970,885.91 | 32.9% | 13.1% | 12.6% |
| Automotive | 11,881,224.90 | 3,589,499.63 | 30.2% | 8.5% | 7.6% |
| Sports & Outdoors | 11,365,547.64 | 4,270,603.95 | 37.6% | 8.2% | 9.0% |
| Home & Kitchen | 7,937,831.01 | 3,109,273.50 | 39.2% | 5.7% | 6.6% |
| Baby & Kids | 7,029,594.10 | 2,926,991.86 | 41.6% | 5.1% | 6.2% |
| Health & Wellness | 6,608,407.52 | 2,460,445.33 | 37.2% | 4.8% | 5.2% |
| Office Supplies | 6,365,291.33 | 2,780,343.45 | 43.7% | 4.6% | 5.9% |
| Fashion | 5,350,862.76 | 2,193,998.08 | 41.0% | 3.8% | 4.6% |
| Pet Supplies | 4,546,984.46 | 1,923,356.34 | 42.3% | 3.3% | 4.1% |
| Toys & Games | 3,880,529.94 | 1,643,615.36 | 42.4% | 2.8% | 3.5% |
| Beauty & Personal Care | 3,314,845.85 | 1,429,242.22 | 43.1% | 2.4% | 3.0% |
| Grocery | 2,041,907.69 | 919,164.16 | 45.0% | 1.5% | 1.9% |
| Books & Media | 1,900,883.56 | 767,293.62 | 40.4% | 1.4% | 1.6% |
| **Total** | **139,094,215.70** | **47,462,086.28** | **34.1%** | **100%** | **100%** |

### Why CM % differs: cost drivers by category

| Category | Discount rate | Product cost % | Shipping cost % |
|---|---:|---:|---:|
| Electronics | 19.1% | 74.5% | 0.6% |
| Jewelry | 19.4% | 67.0% | 0.9% |
| Home Appliances | 19.6% | 66.1% | 1.0% |
| Automotive | 19.2% | 68.2% | 1.6% |
| Sports & Outdoors | 19.3% | 60.6% | 1.9% |
| Home & Kitchen | 19.4% | 58.8% | 2.1% |
| Baby & Kids | 19.6% | 55.9% | 2.5% |
| Health & Wellness | 19.5% | 59.7% | 3.1% |
| Office Supplies | 19.3% | 53.4% | 2.9% |
| Fashion | 19.4% | 56.0% | 3.0% |
| Pet Supplies | 19.5% | 53.9% | 3.8% |
| Toys & Games | 19.4% | 53.0% | 4.7% |
| Beauty & Personal Care | 19.4% | 51.1% | 5.8% |
| Grocery | 19.3% | 46.0% | 9.0% |
| Books & Media | 19.2% | 49.0% | 10.7% |

---

## 6. Findings

### 6.1 Categories
- **No category is loss-making**: all 15 have a positive CM. The answer to Q2 is about *little* profit, not *negative* profit.
- **The four largest categories** (Electronics, Jewelry, Home Appliances, Automotive) generate **56.7% of net revenue but only 49.4% of CM**, with the lowest CM % (25–33% vs 37–45% for the other 11).
- **Electronics** is both the **key** category (largest revenue and largest CM in USD) and the **least efficient** one: 21.6% of revenue, 15.8% of CM, CM % of 24.9%.
- **The cause is product cost, not discounts.** My first hypothesis was discounts, but discount rates are 19–20% in every category. Product cost takes 66–75% of revenue in the big four vs 46–61% in the others.
- **Shipping hits small, low-priced categories hardest**: Books & Media 10.7% and Grocery 9.0% of revenue, vs 0.6% for Electronics. These categories still have good CM % because their product cost is low.

### 6.2 Brands
All 151 brand rows (144 brands, 7 of them in two categories) have at least 556 lines, so every brand is reliable enough to compare.

**13 brands are flagged** (high revenue within their category, CM % more than 3 points below it):

| Category | Brand | Revenue share in category | Brand CM % | Category CM % | Gap (points) |
|---|---|---:|---:|---:|---:|
| Automotive | Castrol | 17.5% | 24.9% | 30.2% | −5.3 |
| Baby & Kids | Gerber | 15.8% | 34.6% | 41.6% | −7.1 |
| Baby & Kids | Evenflo | 11.2% | 33.0% | 41.6% | −8.6 |
| Beauty & Personal Care | Clinique | 11.0% | 38.8% | 43.1% | −4.3 |
| Books & Media | Pearson | 11.5% | 35.1% | 40.4% | −5.3 |
| Fashion | Zara | 11.1% | 36.2% | 41.0% | −4.8 |
| Health & Wellness | Pure Vitamin | 10.6% | 34.2% | 37.2% | −3.0 |
| Home & Kitchen | Wayfair | 14.6% | 34.7% | 39.2% | −4.4 |
| Jewelry | Tiffany | 10.6% | 26.1% | 32.1% | −6.0 |
| Pet Supplies | Blue Buffalo | 12.2% | 37.8% | 42.3% | −4.5 |
| Pet Supplies | Petmate | 11.1% | 36.6% | 42.3% | −5.7 |
| Sports & Outdoors | Adidas | 16.0% | 34.0% | 37.6% | −3.6 |
| Toys & Games | Hasbro | 14.5% | 36.2% | 42.4% | −6.2 |

- **Most robust:** Castrol, Gerber and Hasbro are flagged under every threshold tested.
- **Castrol** is Automotive's largest brand by revenue, but its CM % is 5.3 points below the category, and it earns less CM than Mobil despite higher sales.
- **No Electronics brand is flagged.** LG and Samsung are about 3 points below the category but have less than 10% of its revenue. The Electronics issue is the whole category's product cost, not one weak brand.
- **Size of the opportunity:** if all 13 brands reached their category's CM %, CM would rise by about **USD 0.66M** over 2021–2025, i.e. **1.4% of total CM**.

---

## 7. Possible actions for the business

### Recommendation: where to focus first
**Focus first on product cost in the four largest categories.** Because they generate USD 78.75M of net revenue, improving their product cost by just one percentage point would add about USD 0.79M of contribution margin over the period analysed (five years, 2021–2025), which is more than fixing all 13 underperforming brands combined (about USD 0.66M). In practice, this means supplier negotiations with the largest brands in those categories (e.g. OnePlus, Asus, HP in Electronics; Whirlpool, Dyson in Home Appliances).

**Then address the flagged brands as a targeted second list**, starting with Castrol, Gerber and Hasbro, which fall clearly below their category under every threshold tested. Each case is smaller, but specific and quick to investigate.

**Big four categories (high product cost):**
- Negotiate supplier prices; Electronics alone is 21.6% of revenue, which gives real volume leverage.
- Improve the mix within the category: promote higher-margin products (e.g. accessories).
- Review prices where competition allows.

**Small, low-priced categories (high shipping share):**
- Negotiate shipping rates with logistics partners.
- Set a minimum order value for free shipping, so each parcel carries more revenue.
- Sell in bundles (e.g. books, grocery packs).

---

## 8. Limitations (Q2)
1. Shipping is assumed to be paid by the business; if customers pay it, CM is slightly understated.
2. Contribution margin is not net profit: payment fees, returns handling, marketing and fixed costs are not included.
3. Amounts are treated as USD; the data's currency labels are never converted.
4. Synthetic data: the uniform discount rate (19–20% in every category) likely reflects generation rules rather than real pricing strategy.
5. The analysis shows *where* margin can be improved and how big the opportunity is, not whether suppliers or logistics partners would accept better terms.
6. Pending orders are excluded (~5%, likely the most recent), so the latest period is slightly under-represented.
7. The brand flags depend on two thresholds (10% revenue share, −3 points gap). Only Castrol, Gerber and Hasbro are flagged under every threshold tested; the other flagged brands depend on where the line is drawn.
8. The analysis does not yet explain *why* each flagged brand underperforms (discounts, product cost or shipping); a per-brand cost-driver check would be the next step.
