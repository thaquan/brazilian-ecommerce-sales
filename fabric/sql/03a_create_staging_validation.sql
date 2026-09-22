-- Run this whole file as a separate query in WH_Olist_Gold.
CREATE OR ALTER VIEW dbo.vw_StageValidation
AS
SELECT CAST('orders.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[orders]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id] FROM [staging].[orders] GROUP BY [order_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[orders] WHERE [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' OR [customer_id] IS NULL OR LTRIM(RTRIM([customer_id])) = '' OR [order_purchase_timestamp] IS NULL OR [purchase_date_key] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_orders]) - (SELECT COUNT_BIG(*) FROM [staging].[orders]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [customer_id], [order_status], [order_purchase_timestamp], [purchase_date_key], [delivered_date_key], [estimated_date_key], [delivery_days], [delay_days], [is_late] FROM [LH_Olist_Silver].[dbo].[slv_orders] EXCEPT SELECT [order_id], [customer_id], [order_status], [order_purchase_timestamp], [purchase_date_key], [delivered_date_key], [estimated_date_key], [delivery_days], [delay_days], [is_late] FROM [staging].[orders]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [customer_id], [order_status], [order_purchase_timestamp], [purchase_date_key], [delivered_date_key], [estimated_date_key], [delivery_days], [delay_days], [is_late] FROM [staging].[orders] EXCEPT SELECT [order_id], [customer_id], [order_status], [order_purchase_timestamp], [purchase_date_key], [delivered_date_key], [estimated_date_key], [delivery_days], [delay_days], [is_late] FROM [LH_Olist_Silver].[dbo].[slv_orders]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[order_items]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [order_item_id] FROM [staging].[order_items] GROUP BY [order_id], [order_item_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[order_items] WHERE [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' OR [order_item_id] IS NULL OR [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = '' OR [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = '' OR [price] IS NULL OR [freight_value] IS NULL OR [item_gmv] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_order_items]) - (SELECT COUNT_BIG(*) FROM [staging].[order_items]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [order_item_id], [product_id], [seller_id], [price], [freight_value], [item_gmv] FROM [LH_Olist_Silver].[dbo].[slv_order_items] EXCEPT SELECT [order_id], [order_item_id], [product_id], [seller_id], [price], [freight_value], [item_gmv] FROM [staging].[order_items]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [order_item_id], [product_id], [seller_id], [price], [freight_value], [item_gmv] FROM [staging].[order_items] EXCEPT SELECT [order_id], [order_item_id], [product_id], [seller_id], [price], [freight_value], [item_gmv] FROM [LH_Olist_Silver].[dbo].[slv_order_items]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[customers]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_id] FROM [staging].[customers] GROUP BY [customer_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[customers] WHERE [customer_id] IS NULL OR LTRIM(RTRIM([customer_id])) = '' OR [customer_unique_id] IS NULL OR LTRIM(RTRIM([customer_unique_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_customers]) - (SELECT COUNT_BIG(*) FROM [staging].[customers]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_id], [customer_unique_id] FROM [LH_Olist_Silver].[dbo].[slv_customers] EXCEPT SELECT [customer_id], [customer_unique_id] FROM [staging].[customers]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_id], [customer_unique_id] FROM [staging].[customers] EXCEPT SELECT [customer_id], [customer_unique_id] FROM [LH_Olist_Silver].[dbo].[slv_customers]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customer_current.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[customer_current]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customer_current.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_unique_id] FROM [staging].[customer_current] GROUP BY [customer_unique_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customer_current.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[customer_current] WHERE [customer_unique_id] IS NULL OR LTRIM(RTRIM([customer_unique_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customer_current.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_customer_current]) - (SELECT COUNT_BIG(*) FROM [staging].[customer_current]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customer_current.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_unique_id], [customer_zip_code_prefix], [customer_city], [customer_state], [latitude], [longitude] FROM [LH_Olist_Silver].[dbo].[slv_customer_current] EXCEPT SELECT [customer_unique_id], [customer_zip_code_prefix], [customer_city], [customer_state], [latitude], [longitude] FROM [staging].[customer_current]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customer_current.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [customer_unique_id], [customer_zip_code_prefix], [customer_city], [customer_state], [latitude], [longitude] FROM [staging].[customer_current] EXCEPT SELECT [customer_unique_id], [customer_zip_code_prefix], [customer_city], [customer_state], [latitude], [longitude] FROM [LH_Olist_Silver].[dbo].[slv_customer_current]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('products.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[products]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('products.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [product_id] FROM [staging].[products] GROUP BY [product_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('products.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[products] WHERE [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('products.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_products]) - (SELECT COUNT_BIG(*) FROM [staging].[products]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('products.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [product_id], [product_category_name], [product_category_name_english], [product_weight_g], [product_length_cm], [product_height_cm], [product_width_cm] FROM [LH_Olist_Silver].[dbo].[slv_products] EXCEPT SELECT [product_id], [product_category_name], [product_category_name_english], [product_weight_g], [product_length_cm], [product_height_cm], [product_width_cm] FROM [staging].[products]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('products.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [product_id], [product_category_name], [product_category_name_english], [product_weight_g], [product_length_cm], [product_height_cm], [product_width_cm] FROM [staging].[products] EXCEPT SELECT [product_id], [product_category_name], [product_category_name_english], [product_weight_g], [product_length_cm], [product_height_cm], [product_width_cm] FROM [LH_Olist_Silver].[dbo].[slv_products]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('sellers.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[sellers]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('sellers.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [seller_id] FROM [staging].[sellers] GROUP BY [seller_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('sellers.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[sellers] WHERE [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('sellers.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_sellers]) - (SELECT COUNT_BIG(*) FROM [staging].[sellers]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('sellers.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [seller_id], [seller_zip_code_prefix], [seller_city], [seller_state], [latitude], [longitude] FROM [LH_Olist_Silver].[dbo].[slv_sellers] EXCEPT SELECT [seller_id], [seller_zip_code_prefix], [seller_city], [seller_state], [latitude], [longitude] FROM [staging].[sellers]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('sellers.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [seller_id], [seller_zip_code_prefix], [seller_city], [seller_state], [latitude], [longitude] FROM [staging].[sellers] EXCEPT SELECT [seller_id], [seller_zip_code_prefix], [seller_city], [seller_state], [latitude], [longitude] FROM [LH_Olist_Silver].[dbo].[slv_sellers]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[payments]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [payment_sequential] FROM [staging].[payments] GROUP BY [order_id], [payment_sequential] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[payments] WHERE [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' OR [payment_sequential] IS NULL OR [payment_value] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_payments]) - (SELECT COUNT_BIG(*) FROM [staging].[payments]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [payment_sequential], [payment_type], [payment_installments], [payment_value] FROM [LH_Olist_Silver].[dbo].[slv_payments] EXCEPT SELECT [order_id], [payment_sequential], [payment_type], [payment_installments], [payment_value] FROM [staging].[payments]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [payment_sequential], [payment_type], [payment_installments], [payment_value] FROM [staging].[payments] EXCEPT SELECT [order_id], [payment_sequential], [payment_type], [payment_installments], [payment_value] FROM [LH_Olist_Silver].[dbo].[slv_payments]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[reviews_order]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id] FROM [staging].[reviews_order] GROUP BY [order_id] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[reviews_order] WHERE [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '') AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_reviews_order]) - (SELECT COUNT_BIG(*) FROM [staging].[reviews_order]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [review_score] FROM [LH_Olist_Silver].[dbo].[slv_reviews_order] EXCEPT SELECT [order_id], [review_score] FROM [staging].[reviews_order]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [order_id], [review_score] FROM [staging].[reviews_order] EXCEPT SELECT [order_id], [review_score] FROM [LH_Olist_Silver].[dbo].[slv_reviews_order]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('date.empty' AS varchar(160)) AS [rule], CAST((SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM [staging].[date]) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('date.duplicate_grain' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [date_key] FROM [staging].[date] GROUP BY [date_key] HAVING COUNT_BIG(*) > 1) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('date.required_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[date] WHERE [date_key] IS NULL OR [full_date] IS NULL) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('date.silver_row_count' AS varchar(160)) AS [rule], CAST((SELECT ABS((SELECT COUNT_BIG(*) FROM [LH_Olist_Silver].[dbo].[slv_date]) - (SELECT COUNT_BIG(*) FROM [staging].[date]))) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('date.missing_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [date_key], [full_date], [year], [quarter], [month_number], [month_name], [year_month], [week_number], [day_of_week], [day_name], [is_weekend] FROM [LH_Olist_Silver].[dbo].[slv_date] EXCEPT SELECT [date_key], [full_date], [year], [quarter], [month_number], [month_name], [year_month], [week_number], [day_of_week], [day_name], [is_weekend] FROM [staging].[date]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('date.extra_or_changed' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM (SELECT [date_key], [full_date], [year], [quarter], [month_number], [month_name], [year_month], [week_number], [day_of_week], [day_name], [is_weekend] FROM [staging].[date] EXCEPT SELECT [date_key], [full_date], [year], [quarter], [month_number], [month_name], [year_month], [week_number], [day_of_week], [day_name], [is_weekend] FROM [LH_Olist_Silver].[dbo].[slv_date]) d) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.customer_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[orders] c WHERE c.[customer_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[customers] p WHERE p.[customer_id] = c.[customer_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('customers.customer_unique_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[customers] c WHERE c.[customer_unique_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[customer_current] p WHERE p.[customer_unique_id] = c.[customer_unique_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.order_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[order_items] c WHERE c.[order_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[orders] p WHERE p.[order_id] = c.[order_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.product_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[order_items] c WHERE c.[product_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[products] p WHERE p.[product_id] = c.[product_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.seller_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[order_items] c WHERE c.[seller_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[sellers] p WHERE p.[seller_id] = c.[seller_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.order_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[payments] c WHERE c.[order_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[orders] p WHERE p.[order_id] = c.[order_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.order_id.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[reviews_order] c WHERE c.[order_id] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[orders] p WHERE p.[order_id] = c.[order_id])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.purchase_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[orders] c WHERE c.[purchase_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[date] p WHERE p.[date_key] = c.[purchase_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.delivered_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[orders] c WHERE c.[delivered_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[date] p WHERE p.[date_key] = c.[delivered_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.estimated_date_key.orphan' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM [staging].[orders] c WHERE c.[estimated_date_key] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [staging].[date] p WHERE p.[date_key] = c.[estimated_date_key])) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('order_items.business_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM staging.[order_items] WHERE price < 0 OR freight_value < 0 OR item_gmv <> price + freight_value) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('payments.business_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM staging.[payments] WHERE payment_value < 0) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('reviews_order.business_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM staging.[reviews_order] WHERE review_score IS NULL OR review_score NOT BETWEEN 1 AND 5) AS bigint) AS failed_rows
UNION ALL
SELECT CAST('orders.business_values' AS varchar(160)) AS [rule], CAST((SELECT COUNT_BIG(*) FROM staging.[orders] WHERE is_late NOT IN (0, 1) OR ((delivered_date_key IS NULL OR estimated_date_key IS NULL) AND is_late IS NOT NULL)) AS bigint) AS failed_rows;
