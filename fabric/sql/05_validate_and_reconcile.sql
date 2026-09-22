-- Run after all nine copies; staging must have zero failing rules.
SELECT [rule], failed_rows, CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM dbo.vw_StageValidation ORDER BY failed_rows DESC, [rule];

-- Run after usp_build_gold; Gold must have zero failing rules.
SELECT [rule], failed_rows, CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM dbo.vw_GoldValidation ORDER BY failed_rows DESC, [rule];

SELECT TOP (10) * FROM dbo.GoldLoadAudit ORDER BY completed_at DESC;

SELECT 'Silver' AS layer, SUM(price) AS merchandise_value,
       SUM(freight_value) AS freight_value, SUM(item_gmv) AS order_value_including_freight
FROM LH_Olist_Silver.dbo.slv_order_items
UNION ALL
SELECT 'Staging', SUM(price), SUM(freight_value), SUM(item_gmv) FROM staging.order_items
UNION ALL
SELECT 'Gold', SUM(price), SUM(freight_value), SUM(item_gmv) FROM dbo.FactOrderItem;

SELECT 'Silver' AS layer, SUM(payment_value) AS payment_value FROM LH_Olist_Silver.dbo.slv_payments
UNION ALL SELECT 'Staging', SUM(payment_value) FROM staging.payments
UNION ALL SELECT 'Gold', SUM(payment_value) FROM dbo.FactPayments;

-- Inspect retained warnings; these are not automatically transformed into valid delivery observations.
SELECT order_status, COUNT_BIG(*) AS orders,
       SUM(CASE WHEN is_late IS NULL THEN 1 ELSE 0 END) AS unknown_lateness,
       SUM(CASE WHEN delivery_days < 0 THEN 1 ELSE 0 END) AS negative_delivery_days,
       SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS missing_review
FROM dbo.FactOrders GROUP BY order_status;
