-- Run this whole file as a separate query in WH_Olist_Gold.
CREATE OR ALTER VIEW dbo.vw_GoldValidation
AS
SELECT CAST('DimDate.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[DimDate]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimDate.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [date_key] FROM [dbo].[DimDate] GROUP BY [date_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimDate.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[DimDate] WHERE [date_key] IS NULL OR [full_date] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimDate.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[DimDate]) - (SELECT COUNT_BIG(*) FROM staging.[date]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimCustomer.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[DimCustomer]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimCustomer.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_unique_id] FROM [dbo].[DimCustomer] GROUP BY [customer_unique_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimCustomer.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[DimCustomer] WHERE [customer_key] IS NULL OR [customer_unique_id] IS NULL OR LTRIM(RTRIM([customer_unique_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimCustomer.duplicate_surrogate' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_key] FROM dbo.[DimCustomer] GROUP BY [customer_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimCustomer.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[DimCustomer]) - (SELECT COUNT_BIG(*) FROM staging.[customer_current]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimProduct.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[DimProduct]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimProduct.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [product_id] FROM [dbo].[DimProduct] GROUP BY [product_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimProduct.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[DimProduct] WHERE [product_key] IS NULL OR [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimProduct.duplicate_surrogate' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [product_key] FROM dbo.[DimProduct] GROUP BY [product_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimProduct.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[DimProduct]) - (SELECT COUNT_BIG(*) FROM staging.[products]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimSeller.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[DimSeller]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimSeller.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [seller_id] FROM [dbo].[DimSeller] GROUP BY [seller_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimSeller.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[DimSeller] WHERE [seller_key] IS NULL OR [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimSeller.duplicate_surrogate' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [seller_key] FROM dbo.[DimSeller] GROUP BY [seller_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('DimSeller.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[DimSeller]) - (SELECT COUNT_BIG(*) FROM staging.[sellers]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[FactOrders]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id] FROM [dbo].[FactOrders] GROUP BY [order_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrders] WHERE [order_key] IS NULL OR [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' OR [purchase_date_key] IS NULL OR [customer_key] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.duplicate_surrogate' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_key] FROM dbo.[FactOrders] GROUP BY [order_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[FactOrders]) - (SELECT COUNT_BIG(*) FROM staging.[orders]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[FactOrderItem]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [order_item_id] FROM [dbo].[FactOrderItem] GROUP BY [order_id], [order_item_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrderItem] WHERE [sales_key] IS NULL OR [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' OR [order_item_id] IS NULL OR [purchase_date_key] IS NULL OR [customer_key] IS NULL OR [product_key] IS NULL OR [seller_key] IS NULL OR [price] IS NULL OR [freight_value] IS NULL OR [item_gmv] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.duplicate_surrogate' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [sales_key] FROM dbo.[FactOrderItem] GROUP BY [sales_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[FactOrderItem]) - (SELECT COUNT_BIG(*) FROM staging.[order_items]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [dbo].[FactPayments]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [payment_sequential] FROM [dbo].[FactPayments] GROUP BY [order_id], [payment_sequential] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactPayments] WHERE [payment_key] IS NULL OR [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' OR [purchase_date_key] IS NULL OR [customer_key] IS NULL OR [payment_sequential] IS NULL OR [payment_value] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.duplicate_surrogate' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [payment_key] FROM dbo.[FactPayments] GROUP BY [payment_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.staging_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[FactPayments]) - (SELECT COUNT_BIG(*) FROM staging.[payments]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.customer_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrders] c WHERE c.[customer_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimCustomer] p WHERE p.[customer_key] = c.[customer_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.purchase_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrders] c WHERE c.[purchase_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] p WHERE p.[date_key] = c.[purchase_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.customer_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrderItem] c WHERE c.[customer_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimCustomer] p WHERE p.[customer_key] = c.[customer_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.purchase_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrderItem] c WHERE c.[purchase_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] p WHERE p.[date_key] = c.[purchase_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.customer_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactPayments] c WHERE c.[customer_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimCustomer] p WHERE p.[customer_key] = c.[customer_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.purchase_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactPayments] c WHERE c.[purchase_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] p WHERE p.[date_key] = c.[purchase_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.delivered_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrders] c WHERE c.[delivered_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] p WHERE p.[date_key] = c.[delivered_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrders.estimated_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrders] c WHERE c.[estimated_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] p WHERE p.[date_key] = c.[estimated_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.product_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrderItem] c WHERE c.[product_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimProduct] p WHERE p.[product_key] = c.[product_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.seller_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrderItem] c WHERE c.[seller_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[DimSeller] p WHERE p.[seller_key] = c.[seller_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.order_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactOrderItem] c WHERE c.[order_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[FactOrders] p WHERE p.[order_id] = c.[order_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.order_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [dbo].[FactPayments] c WHERE c.[order_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[FactOrders] p WHERE p.[order_id] = c.[order_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.price.sum' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN (SELECT COALESCE(SUM([price]), 0) FROM dbo.[FactOrderItem]) = (SELECT COALESCE(SUM([price]), 0) FROM staging.[order_items]) THEN 0 ELSE 1 END) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.freight_value.sum' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN (SELECT COALESCE(SUM([freight_value]), 0) FROM dbo.[FactOrderItem]) = (SELECT COALESCE(SUM([freight_value]), 0) FROM staging.[order_items]) THEN 0 ELSE 1 END) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactOrderItem.item_gmv.sum' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN (SELECT COALESCE(SUM([item_gmv]), 0) FROM dbo.[FactOrderItem]) = (SELECT COALESCE(SUM([item_gmv]), 0) FROM staging.[order_items]) THEN 0 ELSE 1 END) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('FactPayments.payment_value.sum' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN (SELECT COALESCE(SUM([payment_value]), 0) FROM dbo.[FactPayments]) = (SELECT COALESCE(SUM([payment_value]), 0) FROM staging.[payments]) THEN 0 ELSE 1 END) AS bigint) AS failed_rows;
