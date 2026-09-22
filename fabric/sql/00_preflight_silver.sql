-- Run in WH_Olist_Gold with LH_Olist_Silver in the same workspace.
-- Add the Silver SQL analytics endpoint to the query Explorer if necessary.
-- DQ PASS alone does NOT prove that all ten Silver writes completed.
SELECT TOP (10) run_id, MIN(checked_at) AS started_check_at,
    MAX(checked_at) AS last_check_at, COUNT_BIG(*) AS rule_count,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS fail_count,
    SUM(CASE WHEN status = 'WARN' THEN 1 ELSE 0 END) AS warn_count
FROM LH_Olist_Silver.dbo.dq_results
GROUP BY run_id ORDER BY last_check_at DESC, run_id DESC;

SELECT 'slv_orders' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_orders]
UNION ALL
SELECT 'slv_order_items' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_order_items]
UNION ALL
SELECT 'slv_customers' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_customers]
UNION ALL
SELECT 'slv_customer_current' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_customer_current]
UNION ALL
SELECT 'slv_products' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_products]
UNION ALL
SELECT 'slv_sellers' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_sellers]
UNION ALL
SELECT 'slv_payments' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_payments]
UNION ALL
SELECT 'slv_reviews_order' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_reviews_order]
UNION ALL
SELECT 'slv_date' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_date];

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION, NUMERIC_SCALE
FROM LH_Olist_Silver.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE 'slv[_]%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
