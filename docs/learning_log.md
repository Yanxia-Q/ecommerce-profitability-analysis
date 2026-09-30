# Learning Log

## Phase 1 — Data setup (2026-09-30)

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
- Defined a loyalty by frequency rather than CLV: CLV increases with discount-driven spending, which could make the analysis for Q3 circular. I therefore decided to use purchase frequency as the basis for measuring loyalty
- Counted orders myself: The `customer_order_count` field did not match the actual number of orders (e.g. there are only 4 orders for CUST-000007 in the data source but in the `customer_order_count` column it shows 6), so I decided to calculate the order count myself rather than relying on the provided metric
- Kept the synthetic dataset: Public datasets rarely include the product cost and discount information needed for this analysis, so I decided to continue using a synthetic dataset
- Uploaded native tables instead of connecting directly to Google Sheets: I chose to upload native tables to BigQuery because this approach is more stable and provides better performance

### What I got wrong or found confusing
- Some Git commands and their purposes, for example, what git push -u does
- How to structure a project in GitHub, including files such as .gitignore
- How to prepare and structure a README file
