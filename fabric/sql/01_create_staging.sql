-- Run in WH_Olist_Gold. Existing tables are kept, not migrated.
IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
IF OBJECT_ID('staging.orders', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[orders] (
        [order_id] varchar(32) NOT NULL,
        [customer_id] varchar(32) NOT NULL,
        [order_status] varchar(30),
        [order_purchase_timestamp] datetime2(6) NOT NULL,
        [purchase_date_key] int NOT NULL,
        [delivered_date_key] int,
        [estimated_date_key] int,
        [delivery_days] int,
        [delay_days] int,
        [is_late] int
    );
END;

IF OBJECT_ID('staging.order_items', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[order_items] (
        [order_id] varchar(32) NOT NULL,
        [order_item_id] int NOT NULL,
        [product_id] varchar(32) NOT NULL,
        [seller_id] varchar(32) NOT NULL,
        [price] decimal(18,2) NOT NULL,
        [freight_value] decimal(18,2) NOT NULL,
        [item_gmv] decimal(19,2) NOT NULL
    );
END;

IF OBJECT_ID('staging.customers', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[customers] (
        [customer_id] varchar(32) NOT NULL,
        [customer_unique_id] varchar(32) NOT NULL
    );
END;

IF OBJECT_ID('staging.customer_current', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[customer_current] (
        [customer_unique_id] varchar(32) NOT NULL,
        [customer_zip_code_prefix] varchar(5),
        [customer_city] varchar(300),
        [customer_state] varchar(2),
        [latitude] float,
        [longitude] float
    );
END;

IF OBJECT_ID('staging.products', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[products] (
        [product_id] varchar(32) NOT NULL,
        [product_category_name] varchar(200),
        [product_category_name_english] varchar(200),
        [product_weight_g] int,
        [product_length_cm] int,
        [product_height_cm] int,
        [product_width_cm] int
    );
END;

IF OBJECT_ID('staging.sellers', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[sellers] (
        [seller_id] varchar(32) NOT NULL,
        [seller_zip_code_prefix] varchar(5),
        [seller_city] varchar(300),
        [seller_state] varchar(2),
        [latitude] float,
        [longitude] float
    );
END;

IF OBJECT_ID('staging.payments', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[payments] (
        [order_id] varchar(32) NOT NULL,
        [payment_sequential] int NOT NULL,
        [payment_type] varchar(30),
        [payment_installments] int,
        [payment_value] decimal(18,2) NOT NULL
    );
END;

IF OBJECT_ID('staging.reviews_order', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[reviews_order] (
        [order_id] varchar(32) NOT NULL,
        [review_score] int
    );
END;

IF OBJECT_ID('staging.date', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[date] (
        [date_key] int NOT NULL,
        [full_date] date NOT NULL,
        [year] int,
        [quarter] int,
        [month_number] int,
        [month_name] varchar(20),
        [year_month] varchar(7),
        [week_number] int,
        [day_of_week] int,
        [day_name] varchar(20),
        [is_weekend] int
    );
END;
