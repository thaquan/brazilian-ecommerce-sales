-- Run in WH_Olist_Gold. Existing tables are kept, not migrated.
IF OBJECT_ID('dbo.DimDate', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimDate] (
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

IF OBJECT_ID('dbo.DimCustomer', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimCustomer] (
        [customer_key] bigint NOT NULL,
        [customer_unique_id] varchar(32) NOT NULL,
        [zip_code_prefix] varchar(5),
        [city] varchar(300),
        [state_code] varchar(2),
        [latitude] float,
        [longitude] float
    );
END;

IF OBJECT_ID('dbo.DimProduct', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimProduct] (
        [product_key] bigint NOT NULL,
        [product_id] varchar(32) NOT NULL,
        [category_pt] varchar(200),
        [category_en] varchar(200),
        [weight_g] int,
        [length_cm] int,
        [height_cm] int,
        [width_cm] int
    );
END;

IF OBJECT_ID('dbo.DimSeller', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimSeller] (
        [seller_key] bigint NOT NULL,
        [seller_id] varchar(32) NOT NULL,
        [zip_code_prefix] varchar(5),
        [city] varchar(300),
        [state_code] varchar(2),
        [latitude] float,
        [longitude] float
    );
END;

IF OBJECT_ID('dbo.FactOrders', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[FactOrders] (
        [order_key] bigint NOT NULL,
        [order_id] varchar(32) NOT NULL,
        [purchase_date_key] int NOT NULL,
        [delivered_date_key] int,
        [estimated_date_key] int,
        [customer_key] bigint NOT NULL,
        [order_status] varchar(30),
        [delivery_days] int,
        [delay_days] int,
        [is_late] int,
        [review_score] int
    );
END;

IF OBJECT_ID('dbo.FactOrderItem', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[FactOrderItem] (
        [sales_key] bigint NOT NULL,
        [order_id] varchar(32) NOT NULL,
        [order_item_id] int NOT NULL,
        [purchase_date_key] int NOT NULL,
        [customer_key] bigint NOT NULL,
        [product_key] bigint NOT NULL,
        [seller_key] bigint NOT NULL,
        [price] decimal(18,2) NOT NULL,
        [freight_value] decimal(18,2) NOT NULL,
        [item_gmv] decimal(19,2) NOT NULL
    );
END;

IF OBJECT_ID('dbo.FactPayments', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[FactPayments] (
        [payment_key] bigint NOT NULL,
        [order_id] varchar(32) NOT NULL,
        [purchase_date_key] int NOT NULL,
        [customer_key] bigint NOT NULL,
        [payment_sequential] int NOT NULL,
        [payment_type] varchar(30),
        [payment_installments] int,
        [payment_value] decimal(18,2) NOT NULL
    );
END;

IF OBJECT_ID('dbo.GoldLoadAudit', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[GoldLoadAudit] (
        [gold_run_id] varchar(36) NOT NULL,
        [silver_run_id] varchar(36) NOT NULL,
        [completed_at] datetime2(6) NOT NULL,
        [order_rows] bigint NOT NULL,
        [item_rows] bigint NOT NULL,
        [payment_rows] bigint NOT NULL
    );
END;
