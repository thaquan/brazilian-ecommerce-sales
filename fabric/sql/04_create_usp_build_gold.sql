-- Run as its own query in WH_Olist_Gold. This creates, but does not execute, the procedure.
-- Full rebuild only. Do not run overlapping notebook/copy/build jobs.
-- ROW_NUMBER keys are repeatable for unchanged sources, NOT stable across changed sources.
CREATE OR ALTER PROCEDURE dbo.usp_build_gold
    @silver_run_id varchar(36)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @gold_run_id varchar(36) = CONVERT(varchar(36), NEWID());
    DECLARE @latest_run_id varchar(36);
    SELECT TOP (1) @latest_run_id = run_id
    FROM LH_Olist_Silver.dbo.dq_results
    GROUP BY run_id ORDER BY MAX(checked_at) DESC, run_id DESC;

    IF @silver_run_id IS NULL OR @latest_run_id IS NULL OR @silver_run_id <> @latest_run_id
        THROW 51001, 'Use the latest verified Silver run_id.', 1;
    IF EXISTS (SELECT 1 FROM LH_Olist_Silver.dbo.dq_results
               WHERE run_id = @silver_run_id AND (status = 'FAIL' OR (severity = 'ERROR' AND status <> 'PASS')))
        THROW 51002, 'Latest Silver DQ failed. Gold was not changed.', 1;

    -- DQ is written BEFORE Silver writes in the notebook. Successful Run All
    -- and persisted table checks remain a manual prerequisite in phase 5.
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.vw_StageValidation WHERE failed_rows > 0)
            THROW 51003, 'Staging validation failed. Inspect dbo.vw_StageValidation.', 1;

        DELETE FROM dbo.[FactPayments];
        DELETE FROM dbo.[FactOrderItem];
        DELETE FROM dbo.[FactOrders];
        DELETE FROM dbo.[DimSeller];
        DELETE FROM dbo.[DimProduct];
        DELETE FROM dbo.[DimCustomer];
        DELETE FROM dbo.[DimDate];

        INSERT INTO dbo.[DimDate] ([date_key], [full_date], [year], [quarter], [month_number], [month_name], [year_month], [week_number], [day_of_week], [day_name], [is_weekend])
        SELECT [date_key], [full_date], [year], [quarter], [month_number], [month_name], [year_month], [week_number], [day_of_week], [day_name], [is_weekend] FROM staging.[date];

        INSERT INTO dbo.[DimCustomer] ([customer_key], [customer_unique_id], [zip_code_prefix], [city], [state_code], [latitude], [longitude])
        SELECT ROW_NUMBER() OVER (ORDER BY customer_unique_id), customer_unique_id,
        customer_zip_code_prefix, customer_city, customer_state, latitude, longitude
        FROM staging.customer_current;

        INSERT INTO dbo.[DimProduct] ([product_key], [product_id], [category_pt], [category_en], [weight_g], [length_cm], [height_cm], [width_cm])
        SELECT ROW_NUMBER() OVER (ORDER BY product_id), product_id,
        product_category_name, product_category_name_english,
        product_weight_g, product_length_cm, product_height_cm, product_width_cm
        FROM staging.products;

        INSERT INTO dbo.[DimSeller] ([seller_key], [seller_id], [zip_code_prefix], [city], [state_code], [latitude], [longitude])
        SELECT ROW_NUMBER() OVER (ORDER BY seller_id), seller_id,
        seller_zip_code_prefix, seller_city, seller_state, latitude, longitude
        FROM staging.sellers;

        INSERT INTO dbo.[FactOrders] ([order_key], [order_id], [purchase_date_key], [delivered_date_key], [estimated_date_key], [customer_key], [order_status], [delivery_days], [delay_days], [is_late], [review_score])
        SELECT ROW_NUMBER() OVER (ORDER BY o.order_id), o.order_id,
        o.purchase_date_key, o.delivered_date_key, o.estimated_date_key, d.customer_key,
        o.order_status, o.delivery_days, o.delay_days, o.is_late, r.review_score
        FROM staging.orders o
        JOIN staging.customers c ON o.customer_id = c.customer_id
        JOIN dbo.DimCustomer d ON c.customer_unique_id = d.customer_unique_id
        LEFT JOIN staging.reviews_order r ON o.order_id = r.order_id;

        INSERT INTO dbo.[FactOrderItem] ([sales_key], [order_id], [order_item_id], [purchase_date_key], [customer_key], [product_key], [seller_key], [price], [freight_value], [item_gmv])
        SELECT ROW_NUMBER() OVER (ORDER BY i.order_id, i.order_item_id),
        i.order_id, i.order_item_id, o.purchase_date_key, o.customer_key,
        p.product_key, s.seller_key, i.price, i.freight_value, i.item_gmv
        FROM staging.order_items i
        JOIN dbo.FactOrders o ON i.order_id = o.order_id
        JOIN dbo.DimProduct p ON i.product_id = p.product_id
        JOIN dbo.DimSeller s ON i.seller_id = s.seller_id;

        INSERT INTO dbo.[FactPayments] ([payment_key], [order_id], [purchase_date_key], [customer_key], [payment_sequential], [payment_type], [payment_installments], [payment_value])
        SELECT ROW_NUMBER() OVER (ORDER BY p.order_id, p.payment_sequential),
        p.order_id, o.purchase_date_key, o.customer_key,
        p.payment_sequential, p.payment_type, p.payment_installments, p.payment_value
        FROM staging.payments p
        JOIN dbo.FactOrders o ON p.order_id = o.order_id;

        IF EXISTS (SELECT 1 FROM dbo.vw_GoldValidation WHERE failed_rows > 0)
            THROW 51004, 'Gold validation failed; this rebuild will roll back.', 1;

        INSERT INTO dbo.GoldLoadAudit
            (gold_run_id, silver_run_id, completed_at, order_rows, item_rows, payment_rows)
        SELECT @gold_run_id, @silver_run_id, SYSUTCDATETIME(),
            (SELECT COUNT_BIG(*) FROM dbo.FactOrders),
            (SELECT COUNT_BIG(*) FROM dbo.FactOrderItem),
            (SELECT COUNT_BIG(*) FROM dbo.FactPayments);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT * FROM dbo.GoldLoadAudit WHERE gold_run_id = @gold_run_id;
END;
