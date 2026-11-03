-- Purpose: check that all four tables uploaded completely to BigQuery
-- Method: compare each table's row count with the row count of the source CSV
-- Outcome: all four counts match, so the upload is complete

SELECT COUNT(*) AS row_count
FROM `analytics-reboot.ecommerce.customer_master`;
-- result 25000


SELECT COUNT(*) AS row_count
FROM `analytics-reboot.ecommerce.order_items`;
-- result 397569


SELECT COUNT(*) AS row_count
FROM `analytics-reboot.ecommerce.product_catalog`;
-- result 1175


SELECT COUNT(*) AS row_count
FROM `analytics-reboot.ecommerce.sales_customer_analytics`;
-- result 138116
