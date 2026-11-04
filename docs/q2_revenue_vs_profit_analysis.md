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

---

## 4. Analysis steps (SQL files on GitHub)

| File | What it does | Result |
|---|---|---|
| q2_01_join_checks | Catalog uniqueness and join completeness | Join is safe: no duplicated or lost lines |
| q2_02_category_profitability | Revenue, CM and CM % per category; discount, product cost and shipping % per category | Big four categories have the lowest CM %, driven by product cost |
| *(brand files to be added)* | | |

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
*(to be added)*

---

## 7. Possible actions for the business

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
