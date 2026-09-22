-- Run after a completed Gold copy in OlistDW, and compare with the same
-- source Gold snapshot. Empty destination tables are not a passing load.
SELECT 'DimDate' AS table_name, COUNT_BIG(*) AS row_count FROM dbo.DimDate
UNION ALL SELECT 'DimCustomer', COUNT_BIG(*) FROM dbo.DimCustomer
UNION ALL SELECT 'DimProduct', COUNT_BIG(*) FROM dbo.DimProduct
UNION ALL SELECT 'DimSeller', COUNT_BIG(*) FROM dbo.DimSeller
UNION ALL SELECT 'FactOrders', COUNT_BIG(*) FROM dbo.FactOrders
UNION ALL SELECT 'FactOrderItem', COUNT_BIG(*) FROM dbo.FactOrderItem
UNION ALL SELECT 'FactPayments', COUNT_BIG(*) FROM dbo.FactPayments;

SELECT COUNT_BIG(*) AS orders,
       COUNT(DISTINCT customer_key) AS ordering_customers
FROM dbo.FactOrders;
SELECT COUNT_BIG(*) AS items, COUNT(DISTINCT order_id) AS orders_with_items,
       SUM(price) AS merchandise_value, SUM(freight_value) AS freight_value,
       SUM(item_gmv) AS order_value_including_freight
FROM dbo.FactOrderItem;
SELECT COUNT_BIG(*) AS payment_records, SUM(payment_value) AS payment_value
FROM dbo.FactPayments;

-- Each orphan count must be zero.
SELECT 'Orders_Customer' AS check_name, COUNT_BIG(*) AS orphan_count
FROM dbo.FactOrders f LEFT JOIN dbo.DimCustomer d ON d.customer_key=f.customer_key
WHERE d.customer_key IS NULL
UNION ALL
SELECT 'Items_Customer', COUNT_BIG(*)
FROM dbo.FactOrderItem f LEFT JOIN dbo.DimCustomer d ON d.customer_key=f.customer_key
WHERE d.customer_key IS NULL
UNION ALL
SELECT 'Payments_Customer', COUNT_BIG(*)
FROM dbo.FactPayments f LEFT JOIN dbo.DimCustomer d ON d.customer_key=f.customer_key
WHERE d.customer_key IS NULL
UNION ALL
SELECT 'Items_Product', COUNT_BIG(*)
FROM dbo.FactOrderItem f LEFT JOIN dbo.DimProduct d ON d.product_key=f.product_key
WHERE d.product_key IS NULL
UNION ALL
SELECT 'Items_Seller', COUNT_BIG(*)
FROM dbo.FactOrderItem f LEFT JOIN dbo.DimSeller d ON d.seller_key=f.seller_key
WHERE d.seller_key IS NULL;
