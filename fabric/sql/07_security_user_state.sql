-- Run in WH_Olist_Gold. Prepared locally; not yet executed on Fabric.
-- Independent of the Gold rebuild: do not truncate this table in usp_build_gold.
IF OBJECT_ID('dbo.SecurityUserState', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SecurityUserState
    (
        user_upn VARCHAR(254) NOT NULL,
        state_code VARCHAR(2) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM dbo.SecurityUserState
    WHERE user_upn = 'analyst@example.com' AND state_code = 'SP'
)
BEGIN
    INSERT INTO dbo.SecurityUserState (user_upn, state_code)
    VALUES ('analyst@example.com', 'SP');
END;

SELECT user_upn, state_code FROM dbo.SecurityUserState
WHERE user_upn = 'analyst@example.com';

-- Expected: no duplicate mappings.
SELECT user_upn, state_code, COUNT_BIG(*) AS mapping_count
FROM dbo.SecurityUserState
GROUP BY user_upn, state_code HAVING COUNT_BIG(*) > 1;

-- Independent expected SP results, using current customer geography.
-- Never join the three facts together: their grains differ.
SELECT COUNT_BIG(*) AS total_orders,
       COUNT(DISTINCT f.customer_key) AS ordering_customers
FROM dbo.FactOrders f
JOIN dbo.DimCustomer c ON c.customer_key = f.customer_key
WHERE c.state_code = 'SP';

SELECT COUNT_BIG(*) AS total_order_items,
       SUM(f.price) AS merchandise_value,
       SUM(f.freight_value) AS freight_value,
       SUM(f.item_gmv) AS order_value_including_freight
FROM dbo.FactOrderItem f
JOIN dbo.DimCustomer c ON c.customer_key = f.customer_key
WHERE c.state_code = 'SP';

SELECT COUNT_BIG(*) AS payment_records,
       SUM(f.payment_value) AS payment_value
FROM dbo.FactPayments f
JOIN dbo.DimCustomer c ON c.customer_key = f.customer_key
WHERE c.state_code = 'SP';
