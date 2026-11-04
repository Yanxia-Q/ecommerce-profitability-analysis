# E-commerce Profitability Analysis — Q1 Notes

## 1. Methodology
**Question-driven analytics:**
Questions → metrics each question needs → check each metric (exists? reliable? or calculate it) → answer the questions.

**For every analysis:**
Business question → Metric → Data → Method → Finding → Interpretation → Limitation → Action

---

## 2. Question 1
**Original question:** At what specific discount threshold does customer order volume cease to offset margin compression, causing net profitability to drop?

**In plain words:** When we give a bigger discount, we earn less on each unit, but customers buy more units. Which effect wins? At what discount level does extra volume stop making up for lost margin?

---

## 3. Metrics

*A "line" = one product in an order (one row in `order_items`).*

| Metric | How it's calculated | Source table | Columns needed |
|---|---|---|---|
| Discount band | Check the actual discount range, then define bands: 0% on its own, then 10-point bands up to 60% (lower bound included) | order_items | discount_percentage |
| Average units per line | AVG(quantity) per band | order_items | quantity |
| Contribution margin (CM) per unit | SUM(gross_sales − discount_amount − product_cost − shipping_cost) ÷ SUM(quantity), per band | order_items | gross_sales, discount_amount, shipping_cost, product_cost, quantity |
| Contribution margin (CM) per line | SUM(gross_sales − discount_amount − product_cost − shipping_cost) ÷ COUNT(*), per band | order_items | gross_sales, discount_amount, shipping_cost, product_cost |
| Order status filter | Keep only completed orders | sales_customer_analytics (joined on order_id) | order_status |

**Contribution margin** = gross_sales − discount_amount − product_cost − shipping_cost
**Check:** avg units per line × CM per unit ≈ CM per line (small differences = rounding only)

---

## 4. Method decisions

### 4.1 Profit definition: tax and shipping
The dataset calculates its own sales and profit columns as:

```
net_sales = gross_sales − discount_amount + tax_amount + shipping_cost
profit    = net_sales − shipping_cost − product_cost
```

- **Tax:** tax is added to sales but is never subtracted. Since tax is collected on behalf of the government rather than retained by the business, including it in revenue would overstate profit. Therefore, I decided to exclude tax from net revenue and not use the `profit` column provided in the dataset.
- **Shipping:** I treat shipping as a cost absorbed by the business, since many e-commerce businesses offer free or subsidised shipping to customers. Under the dataset's original logic, shipping is added to `net_sales` and then subtracted as a cost, so it cancels out and has no impact on profit.
- **Limitation of this choice:** if shipping costs were actually paid by customers, treating them as a business expense would slightly understate the contribution margin. Therefore, I consider this a conservative assumption.

The metrics used instead:

```
net_revenue         = gross_sales − discount_amount
contribution_margin = gross_sales − discount_amount − product_cost − shipping_cost
```

### 4.2 Which table to use
1. **Which table contains the column?** `discount_percentage` exists only in `order_items`. `sales_customer_analytics` has `discount_amount` per order, but no percentage.
2. **At what level does the discount vary?** Discounts are set per line: the same order can have one item at 0% and another at 40%. A line-level table shows the true range; an order-level table shows a blended percentage and can hide the extremes.
3. **Which table is the source of truth?** `order_items`: most detailed, and `sales_customer_analytics` totals disagree with it for ~8% of orders.
4. **Which table will the analysis use?** Check the data on the same table, at the same level, as the analysis.

**Example: order ORD-811651**

In `order_items` (one row per product in the order):

| order_id | product_id | quantity | gross_sales | discount_percentage | discount_amount |
|---|---|---:|---:|---:|---:|
| ORD-811651 | PROD-000397 | 4 | 671.84 | 10.4% | 70.20 |
| ORD-811651 | PROD-000154 | 1 | 183.17 | 18.5% | 33.85 |
| ORD-811651 | PROD-000507 | 4 | 108.16 | 57.8% | 62.52 |

In `sales_customer_analytics` (one row per order):

| order_id | gross_sales | discount_amount |
|---|---:|---:|
| ORD-811651 | 963.17 | 166.57 |

Discount calculated from `sales_customer_analytics`: 166.57 ÷ 963.17 = **17.3%**.
What we'd lose: `order_items` shows one product sold at **57.8% off** (a heavy discount). The order-level figure blends all three products into 17.3%, and the 57.8% disappears.
For this order, the totals match in both tables (963.17 = 671.84 + 183.17 + 108.16), so the difference comes purely from **blending**, not from the 8% mismatch issue.
**Rule:** check the discount range in `order_items`, where each discount is actually set.

### 4.3 Is a band big enough? (reliability)
An average from a small group jumps around by chance; an average from a big group is stable.
*Coin example:* 10 tosses → 7 heads (70%) is normal, so unreliable. 10,000 tosses → very close to 50%, so reliable.

| Lines in a group | Reliability |
|---|---|
| Fewer than ~30 | Unreliable: don't draw conclusions |
| Hundreds | Usually OK |
| Thousands or more | Solid |

What matters is the **number of lines**, not the percentage. A band can be 1% of lines and still be reliable if the table is big enough.

### 4.4 Band width: 10-point bands
- Easier to read: 7 bars instead of 13.
- More lines per band, so more stable averages.
- Trade-off: the threshold can only be located within 10 points (e.g. "between 30% and 40%"). If more precision is needed, zoom in with 5% bands around that area.

### 4.5 Completed orders only
- `order_items` includes lines from cancelled, returned and pending orders, which did not (or not yet) generate real profit.
- `order_status` is only in `sales_customer_analytics`, so it's joined to `order_items` on `order_id`.
- **Decision:** keep only `Completed`. Pending is excluded too (conservative: count only profit actually earned).

### 4.6 Currency
Amounts are treated as **USD**. The data labels orders in 7 currencies but never converts them (average order values are the same in every currency). USD is the most common label (~60% of orders) and is used in the dataset's own summary file.

---

## 5. Analysis steps (SQL files on GitHub)

| File | What it does | Result |
|---|---|---|
| q1_01_discount_range_check | Full discount range in order_items | 0% to 60% |
| q1_02_discount_bands | Assign each line to a band, count lines | All lines assigned; smallest band 7,435 lines |
| q1_03_discount_band_profitability | Units and CM per band (all orders) | First version of the finding |
| q1_04_discount_band_mix_check | Price, cost and shipping per band | Nearly identical across bands |
| q1_05_completed_orders | Join check, order statuses, Q1 rerun on completed orders | Final version: the one to quote |

---

## 6. Results (completed orders only, USD)

| Discount band | Lines | Avg units per line | CM per unit | CM per line |
|---|---:|---:|---:|---:|
| 0% | 3,441 | 1.89 | 113.22 | 214.22 |
| 0%–10% | 107,520 | 1.89 | 101.62 | 191.58 |
| 10%–20% | 123,795 | 1.88 | 76.90 | 144.59 |
| 20%–30% | 46,493 | 2.37 | 55.03 | 130.45 |
| 30%–40% | 21,740 | 3.30 | 31.73 | 104.83 |
| 40%–50% | 17,062 | 3.32 | 6.71 | 22.30 |
| 50%–60% | 6,977 | 3.30 | −21.60 | −71.27 |

---

## 7. Finding and recommendation
- No discount band earns as much profit per purchase as full price (USD 214.22 per purchase).
- Discounts of 20–30% partly offset the loss: customers buy 26% more units per purchase.
- At 40–50% discount, profit per purchase is USD 22.30, about 90% lower than at full price.
- At 50–60% discount, profit per purchase is −USD 71.27: each purchase loses money.
- Discounts below 20% don't increase units per purchase at all.
- **Recommendation:** keep discounts below 40%.
- **Caveat:** this data only shows units per purchase. Small discounts might still bring in more orders or new customers, which we can't measure here.

---

## 8. Robustness checks
1. **Product mix:** unit price (243–247), cost per unit (124–127) and shipping per line (6.6–8.6) are nearly identical across bands, so they do not explain the profit decline. The discount is the main driver.
2. **Completed orders only:** CM per line changes by less than USD 1 in every band, so the finding holds.
3. **Data artefact found:** 93% of lines in cancelled and returned orders are at 0% discount, vs ~1% in completed and pending orders. The extreme, near-identical pattern points to a rule in the synthetic data, not customer behaviour. Because of it, the 0% band shrank from 51,476 to 3,441 lines.
4. **Business fact:** among completed orders, only ~1% of lines sell at full price, so almost every real sale is discounted. (Relevant for Q3.)

---

## 9. Limitations (Q1)
1. Shipping is assumed to be paid by the business; if customers pay it, contribution margin is slightly understated.
2. Only units per purchase are measured; we can't see whether discounts bring more orders or new customers.
3. The data shows association, not cause and effect: timing (e.g. Black Friday), campaigns or customer type were not checked.
4. Synthetic data: the step pattern looks unnaturally neat and likely reflects generation rules.
5. Amounts are treated as USD; the data's currency labels are never converted.
6. Contribution margin is not net profit: payment fees, returns handling, marketing and fixed costs are not included.
7. With 10-point bands, the threshold can only be located to within about 10 points.
8. Pending orders are excluded (~5%, likely the most recent), so the latest period is slightly under-represented.
9. Cancelled and returned orders carry almost no discounts (a data generation rule) and were excluded; the full-price baseline is therefore based on 3,441 lines (still enough to be reliable).

---

## 10. Possible next actions for the business
- Cap discounts at 40%; review any campaign that goes beyond it.
- Question small discounts (under 20%): they cost margin without increasing units per purchase. Test whether they bring more orders or new customers before keeping them.
- If more precision is needed, rerun the analysis with 5% bands between 30% and 50%.
