# Learning Log

## Phase 1 — Data setup

### What I did

- Checked which business questions we need to answer
- Verified whether the source data can answer them
- Analyzed which metrics are needed to answer the questions
- Selected the tools for the analysis:
  - Google Sheets to initially verify data quality
  - BigQuery to prepare and transform the data
  - GitHub as the project repository
  - Looker Studio for data visualization

### What I learned
- Profit metrics for e-commerce: Contribution margin (revenue - product cost - shipping cost) is a better measure of "true profit" than gross margin in this case because shipping cost can significantly reduce the actual margin.
- Data quality and preparation: Learned how to assess data quality and prepare a data source for further analysis in BigQuery. One important lesson was to be cautious with metrics provided in the source data and always verify them before using them directly
- GitHub: Learned how a GitHub repository works and how it can be used to organize and document a project

### Decisions I made and why
- Set up GitHub repository first: I decided to set up the GitHub repository before starting the analysis because I thought it would be clearer to establish the project documentation and structure before moving into the analysis
- Rejected `customer_segment` as a loyalty tier: a pivot table showed almost identical values across all four segments. Average loyalty points ranged only from 102.7 to 104.5, and average CLV from 8,878 to 9,037. VIP customers did not score higher than Consumer, so I decided not to use this variable as a measure of loyalty
- Defined loyalty by frequency rather than CLV: CLV increases with discount-driven spending, which could make the analysis for Q3 circular. I therefore decided to use purchase frequency as the basis for measuring loyalty
- Counted orders myself: The `customer_order_count` field did not match the actual number of orders (e.g. there are only 4 orders for CUST-000007 in the data source but in the `customer_order_count` column it shows 6), so I decided to calculate the order count myself rather than relying on the provided metric
- Kept the synthetic dataset: Public datasets rarely include the product cost and discount information needed for this analysis, so I decided to continue using a synthetic dataset
- Uploaded native tables instead of connecting directly to Google Sheets: I chose to upload native tables to BigQuery because this approach is more stable and provides better performance

### What I got wrong or found confusing
- Some Git commands and their purposes, for example, what git push -u does
- How to structure a project in GitHub, including files such as .gitignore
- How to prepare and structure a README file



## Phase 2 — Q1: Discount vs. profitability

### What I did
- Found that the dataset's `profit` column counts tax as profit; defined my own contribution margin (gross sales − discount − product cost − shipping) and treated shipping as a business cost
- Defined the metrics for Q1: discount bands, units per line, contribution margin per unit and per line
- Checked the discount range and built 10-point discount bands in BigQuery
- Calculated profitability per band, then challenged the result with a product-mix check
- Joined `order_items` with `sales_customer_analytics` to keep only completed orders, and found a data artefact in cancelled/returned orders
- Wrote up the finding, limitations and recommendations in `docs/q1_discount_analysis.md`

### What I learned

**Discount threshold vs. discount band**
- *Discount threshold* = the answer I'm looking for: the discount level where something changes.
- *Discount band* = the tool I use to find it: discounts grouped into ranges.

**From revenue to net profit (CM1 / CM2 / CM3)**

    Net revenue (after discounts and returns)
    – Product cost (COGS)
    = CM1 (≈ gross profit)
    – Fulfilment: shipping, packaging, warehouse picking, payment fees (~2–3%), returns handling
    = CM2  ← closest to what this project calculates
    – Marketing / advertising (often the biggest cost in e-commerce)
    = CM3
    – Fixed costs: salaries, software/tech, rent, admin
    = EBITDA (operating profit)
    – Depreciation, interest, corporate tax
    = NET PROFIT

- **EBITDA** = Earnings Before Interest, Taxes, Depreciation and Amortisation: profit from running the business day to day.
- **Depreciation** (折旧): the decrease in value of a tangible asset over time (e.g. cars, buildings, machinery) due to wear and tear, age or becoming outdated.
- **Amortisation** (摊销): spreading the cost of an intangible asset (e.g. patents, software, licences) over its useful life. Also used for paying off a loan gradually (分期偿还).

**SQL and analysis skills**
- `CASE WHEN` to create bands, with `ELSE 'unassigned'` to catch gaps
- `GROUP BY`, `COUNT(*)` vs `COUNT(DISTINCT …)`, `COUNTIF`, `ROUND` (only for display)
- `INNER JOIN` vs `LEFT JOIN`, `ON` vs `USING`, and how to check that a join doesn't lose or duplicate rows
- `WHERE` (filters rows) vs `HAVING` (filters groups)
- Always ask "% of what?" and "compared with what?"

### What I found confusing
- I didn't check how discounts differ by order status at the start. That's why the 0% band collapsed when I filtered to completed orders, and I had to investigate it afterwards.

### Decisions I would do differently
- Decide which rows to exclude (e.g. cancelled, returned, and pending orders) at the beginning of the analysis, rather than at the end. In this case, filtering the data too late meant having to redo the Q1 analysis, only to discover that most of the orders in the 0% band were cancelled or returned.
