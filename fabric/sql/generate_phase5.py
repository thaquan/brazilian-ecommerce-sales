"""Generate the phase 5 teaching scripts from an explicit Silver column contract.
No connection to Fabric; running this file only writes adjacent SQL/CSV files.
"""
from pathlib import Path
import csv

ROOT = Path(__file__).resolve().parent

def cols(spec):
    return [tuple(x.strip().split(' ', 1)) for x in spec.split('|')]

STAGE = {
    'orders': cols('order_id varchar(32) NOT NULL|customer_id varchar(32) NOT NULL|order_status varchar(30)|order_purchase_timestamp datetime2(6) NOT NULL|purchase_date_key int NOT NULL|delivered_date_key int|estimated_date_key int|delivery_days int|delay_days int|is_late int'),
    'order_items': cols('order_id varchar(32) NOT NULL|order_item_id int NOT NULL|product_id varchar(32) NOT NULL|seller_id varchar(32) NOT NULL|price decimal(18,2) NOT NULL|freight_value decimal(18,2) NOT NULL|item_gmv decimal(19,2) NOT NULL'),
    'customers': cols('customer_id varchar(32) NOT NULL|customer_unique_id varchar(32) NOT NULL'),
    'customer_current': cols('customer_unique_id varchar(32) NOT NULL|customer_zip_code_prefix varchar(5)|customer_city varchar(300)|customer_state varchar(2)|latitude float|longitude float'),
    'products': cols('product_id varchar(32) NOT NULL|product_category_name varchar(200)|product_category_name_english varchar(200)|product_weight_g int|product_length_cm int|product_height_cm int|product_width_cm int'),
    'sellers': cols('seller_id varchar(32) NOT NULL|seller_zip_code_prefix varchar(5)|seller_city varchar(300)|seller_state varchar(2)|latitude float|longitude float'),
    'payments': cols('order_id varchar(32) NOT NULL|payment_sequential int NOT NULL|payment_type varchar(30)|payment_installments int|payment_value decimal(18,2) NOT NULL'),
    'reviews_order': cols('order_id varchar(32) NOT NULL|review_score int'),
    'date': cols('date_key int NOT NULL|full_date date NOT NULL|year int|quarter int|month_number int|month_name varchar(20)|year_month varchar(7)|week_number int|day_of_week int|day_name varchar(20)|is_weekend int'),
}
STAGE_KEYS = {
    'orders': ['order_id'], 'order_items': ['order_id', 'order_item_id'],
    'customers': ['customer_id'], 'customer_current': ['customer_unique_id'],
    'products': ['product_id'], 'sellers': ['seller_id'],
    'payments': ['order_id', 'payment_sequential'], 'reviews_order': ['order_id'],
    'date': ['date_key'],
}
GOLD = {
    'DimDate': STAGE['date'],
    'DimCustomer': cols('customer_key bigint NOT NULL|customer_unique_id varchar(32) NOT NULL|zip_code_prefix varchar(5)|city varchar(300)|state_code varchar(2)|latitude float|longitude float'),
    'DimProduct': cols('product_key bigint NOT NULL|product_id varchar(32) NOT NULL|category_pt varchar(200)|category_en varchar(200)|weight_g int|length_cm int|height_cm int|width_cm int'),
    'DimSeller': cols('seller_key bigint NOT NULL|seller_id varchar(32) NOT NULL|zip_code_prefix varchar(5)|city varchar(300)|state_code varchar(2)|latitude float|longitude float'),
    'FactOrders': cols('order_key bigint NOT NULL|order_id varchar(32) NOT NULL|purchase_date_key int NOT NULL|delivered_date_key int|estimated_date_key int|customer_key bigint NOT NULL|order_status varchar(30)|delivery_days int|delay_days int|is_late int|review_score int'),
    'FactOrderItem': cols('sales_key bigint NOT NULL|order_id varchar(32) NOT NULL|order_item_id int NOT NULL|purchase_date_key int NOT NULL|customer_key bigint NOT NULL|product_key bigint NOT NULL|seller_key bigint NOT NULL|price decimal(18,2) NOT NULL|freight_value decimal(18,2) NOT NULL|item_gmv decimal(19,2) NOT NULL'),
    'FactPayments': cols('payment_key bigint NOT NULL|order_id varchar(32) NOT NULL|purchase_date_key int NOT NULL|customer_key bigint NOT NULL|payment_sequential int NOT NULL|payment_type varchar(30)|payment_installments int|payment_value decimal(18,2) NOT NULL'),
}
MATCH = dict(zip(GOLD, ['date', 'customer_current', 'products', 'sellers', 'orders', 'order_items', 'payments']))
GOLD_KEYS = {'DimDate': ['date_key'], 'DimCustomer': ['customer_unique_id'],
             'DimProduct': ['product_id'], 'DimSeller': ['seller_id'],
             'FactOrders': ['order_id'], 'FactOrderItem': ['order_id', 'order_item_id'],
             'FactPayments': ['order_id', 'payment_sequential']}

def names(columns):
    return ', '.join(f'[{n}]' for n, _ in columns)

def write(name, text):
    (ROOT / name).write_text(text.strip() + '\n', encoding='utf-8')

def ddl(schema, tables):
    return '\n\n'.join(
        f"IF OBJECT_ID('{schema}.{name}', 'U') IS NULL\nBEGIN\n"
        f'    CREATE TABLE [{schema}].[{name}] (\n        '
        + ',\n        '.join(f'[{c}] {t}' for c, t in columns)
        + '\n    );\nEND;'
        for name, columns in tables.items())

write('01_create_staging.sql', """-- Run in WH_Olist_Gold. Existing tables are kept, not migrated.
IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
""" + ddl('staging', STAGE))
write('02_create_gold.sql', '-- Run in WH_Olist_Gold. Existing tables are kept, not migrated.\n'
      + ddl('dbo', GOLD) + '\n\n' + ddl('dbo', {
          'GoldLoadAudit': cols('gold_run_id varchar(36) NOT NULL|silver_run_id varchar(36) NOT NULL|completed_at datetime2(6) NOT NULL|order_rows bigint NOT NULL|item_rows bigint NOT NULL|payment_rows bigint NOT NULL')
      }))

stage_checks = []
gold_checks = []
def check(target, name, expression):
    target.append(f"SELECT CAST('{name}' AS varchar(160)) AS [rule], CAST(({expression}) AS bigint) AS failed_rows")

def basics(target, schema, table, columns, keys):
    table_ref = f'[{schema}].[{table}]'
    check(target, table + '.empty', f'SELECT CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END FROM {table_ref}')
    keylist = ', '.join(f'[{k}]' for k in keys)
    check(target, table + '.duplicate_grain', f'SELECT COUNT_BIG(*) FROM (SELECT {keylist} FROM {table_ref} GROUP BY {keylist} HAVING COUNT_BIG(*) > 1) d')
    required = [f'[{n}] IS NULL' + (f" OR LTRIM(RTRIM([{n}])) = ''" if 'varchar' in t else '')
                for n, t in columns if 'NOT NULL' in t]
    check(target, table + '.required_values', f'SELECT COUNT_BIG(*) FROM {table_ref} WHERE ' + ' OR '.join(required))

for table, columns in STAGE.items():
    basics(stage_checks, 'staging', table, columns, STAGE_KEYS[table])
    source = f'[LH_Olist_Silver].[dbo].[slv_{table}]'
    dest = f'[staging].[{table}]'
    check(stage_checks, table + '.silver_row_count', f'SELECT ABS((SELECT COUNT_BIG(*) FROM {source}) - (SELECT COUNT_BIG(*) FROM {dest}))')
    # Compare the selected data, not metadata discarded by the staging contract.
    for label, left, right in [('missing_or_changed', source, dest), ('extra_or_changed', dest, source)]:
        check(stage_checks, table + '.' + label,
              f'SELECT COUNT_BIG(*) FROM (SELECT {names(columns)} FROM {left} EXCEPT SELECT {names(columns)} FROM {right}) d')

def fk(target, schema, child, col, parent, parent_col):
    check(target, child + '.' + col + '.orphan',
          f'SELECT COUNT_BIG(*) FROM [{schema}].[{child}] c WHERE c.[{col}] IS NOT NULL '
          f'AND NOT EXISTS (SELECT 1 FROM [{schema}].[{parent}] p WHERE p.[{parent_col}] = c.[{col}])')

for child, col, parent, pc in [
    ('orders', 'customer_id', 'customers', 'customer_id'),
    ('customers', 'customer_unique_id', 'customer_current', 'customer_unique_id'),
    ('order_items', 'order_id', 'orders', 'order_id'),
    ('order_items', 'product_id', 'products', 'product_id'),
    ('order_items', 'seller_id', 'sellers', 'seller_id'),
    ('payments', 'order_id', 'orders', 'order_id'),
    ('reviews_order', 'order_id', 'orders', 'order_id'),
    *[('orders', c, 'date', 'date_key') for c in ['purchase_date_key', 'delivered_date_key', 'estimated_date_key']]
]:
    fk(stage_checks, 'staging', child, col, parent, pc)
for table, condition in [
    ('order_items', 'price < 0 OR freight_value < 0 OR item_gmv <> price + freight_value'),
    ('payments', 'payment_value < 0'),
    ('reviews_order', 'review_score IS NULL OR review_score NOT BETWEEN 1 AND 5'),
    ('orders', 'is_late NOT IN (0, 1) OR ((delivered_date_key IS NULL OR estimated_date_key IS NULL) AND is_late IS NOT NULL)')
]:
    check(stage_checks, table + '.business_values', f'SELECT COUNT_BIG(*) FROM staging.[{table}] WHERE {condition}')

for table, columns in GOLD.items():
    basics(gold_checks, 'dbo', table, columns, GOLD_KEYS[table])
    surrogate = columns[0][0]
    if GOLD_KEYS[table] != [surrogate]:
        check(gold_checks, table + '.duplicate_surrogate', f'SELECT COUNT_BIG(*) FROM (SELECT [{surrogate}] FROM dbo.[{table}] GROUP BY [{surrogate}] HAVING COUNT_BIG(*) > 1) d')
    check(gold_checks, table + '.staging_row_count',
          f'SELECT ABS((SELECT COUNT_BIG(*) FROM dbo.[{table}]) - (SELECT COUNT_BIG(*) FROM staging.[{MATCH[table]}]))')
for child in ['FactOrders', 'FactOrderItem', 'FactPayments']:
    fk(gold_checks, 'dbo', child, 'customer_key', 'DimCustomer', 'customer_key')
    fk(gold_checks, 'dbo', child, 'purchase_date_key', 'DimDate', 'date_key')
for col in ['delivered_date_key', 'estimated_date_key']:
    fk(gold_checks, 'dbo', 'FactOrders', col, 'DimDate', 'date_key')
fk(gold_checks, 'dbo', 'FactOrderItem', 'product_key', 'DimProduct', 'product_key')
fk(gold_checks, 'dbo', 'FactOrderItem', 'seller_key', 'DimSeller', 'seller_key')
for child in ['FactOrderItem', 'FactPayments']:
    fk(gold_checks, 'dbo', child, 'order_id', 'FactOrders', 'order_id')
for table, col in [('FactOrderItem', 'price'), ('FactOrderItem', 'freight_value'),
                   ('FactOrderItem', 'item_gmv'), ('FactPayments', 'payment_value')]:
    check(gold_checks, table + '.' + col + '.sum',
          f'SELECT CASE WHEN (SELECT COALESCE(SUM([{col}]), 0) FROM dbo.[{table}]) = '
          f'(SELECT COALESCE(SUM([{col}]), 0) FROM staging.[{MATCH[table]}]) THEN 0 ELSE 1 END')

write('03a_create_staging_validation.sql',
      '-- Run this whole file as a separate query in WH_Olist_Gold.\n'
      'CREATE OR ALTER VIEW dbo.vw_StageValidation\nAS\n' + '\nUNION ALL\n'.join(stage_checks) + ';')
write('03b_create_gold_validation.sql',
      '-- Run this whole file as a separate query in WH_Olist_Gold.\n'
      'CREATE OR ALTER VIEW dbo.vw_GoldValidation\nAS\n' + '\nUNION ALL\n'.join(gold_checks) + ';')

SELECTS = {
    'DimDate': f"SELECT {names(STAGE['date'])} FROM staging.[date]",
    'DimCustomer': '''SELECT ROW_NUMBER() OVER (ORDER BY customer_unique_id), customer_unique_id,
        customer_zip_code_prefix, customer_city, customer_state, latitude, longitude
        FROM staging.customer_current''',
    'DimProduct': '''SELECT ROW_NUMBER() OVER (ORDER BY product_id), product_id,
        product_category_name, product_category_name_english,
        product_weight_g, product_length_cm, product_height_cm, product_width_cm
        FROM staging.products''',
    'DimSeller': '''SELECT ROW_NUMBER() OVER (ORDER BY seller_id), seller_id,
        seller_zip_code_prefix, seller_city, seller_state, latitude, longitude
        FROM staging.sellers''',
    'FactOrders': '''SELECT ROW_NUMBER() OVER (ORDER BY o.order_id), o.order_id,
        o.purchase_date_key, o.delivered_date_key, o.estimated_date_key, d.customer_key,
        o.order_status, o.delivery_days, o.delay_days, o.is_late, r.review_score
        FROM staging.orders o
        JOIN staging.customers c ON o.customer_id = c.customer_id
        JOIN dbo.DimCustomer d ON c.customer_unique_id = d.customer_unique_id
        LEFT JOIN staging.reviews_order r ON o.order_id = r.order_id''',
    'FactOrderItem': '''SELECT ROW_NUMBER() OVER (ORDER BY i.order_id, i.order_item_id),
        i.order_id, i.order_item_id, o.purchase_date_key, o.customer_key,
        p.product_key, s.seller_key, i.price, i.freight_value, i.item_gmv
        FROM staging.order_items i
        JOIN dbo.FactOrders o ON i.order_id = o.order_id
        JOIN dbo.DimProduct p ON i.product_id = p.product_id
        JOIN dbo.DimSeller s ON i.seller_id = s.seller_id''',
    'FactPayments': '''SELECT ROW_NUMBER() OVER (ORDER BY p.order_id, p.payment_sequential),
        p.order_id, o.purchase_date_key, o.customer_key,
        p.payment_sequential, p.payment_type, p.payment_installments, p.payment_value
        FROM staging.payments p
        JOIN dbo.FactOrders o ON p.order_id = o.order_id''',
}
body = '\n\n'.join(f'        INSERT INTO dbo.[{t}] ({names(GOLD[t])})\n        {s};'
                   for t, s in SELECTS.items())
deletes = '\n'.join(f'        DELETE FROM dbo.[{t}];' for t in reversed(GOLD))
write('04_create_usp_build_gold.sql', '''-- Run as its own query in WH_Olist_Gold. This creates, but does not execute, the procedure.
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

''' + deletes + '\n\n' + body + '''

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
''')

preflight = '''-- Run in WH_Olist_Gold with LH_Olist_Silver in the same workspace.
-- Add the Silver SQL analytics endpoint to the query Explorer if necessary.
-- DQ PASS alone does NOT prove that all ten Silver writes completed.
SELECT TOP (10) run_id, MIN(checked_at) AS started_check_at,
    MAX(checked_at) AS last_check_at, COUNT_BIG(*) AS rule_count,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS fail_count,
    SUM(CASE WHEN status = 'WARN' THEN 1 ELSE 0 END) AS warn_count
FROM LH_Olist_Silver.dbo.dq_results
GROUP BY run_id ORDER BY last_check_at DESC, run_id DESC;

'''
preflight += '\nUNION ALL\n'.join(
    f"SELECT 'slv_{t}' AS table_name, COUNT_BIG(*) AS row_count FROM LH_Olist_Silver.dbo.[slv_{t}]" for t in STAGE) + ';\n\n'
preflight += '''SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION, NUMERIC_SCALE
FROM LH_Olist_Silver.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE 'slv[_]%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
'''
write('00_preflight_silver.sql', preflight)
write('05_validate_and_reconcile.sql', '''-- Run after all nine copies; staging must have zero failing rules.
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
''')
with (ROOT / 'copy_activity_mapping.csv').open('w', newline='', encoding='utf-8-sig') as f:
    writer = csv.writer(f)
    writer.writerow(['activity_name', 'source_table', 'destination_table', 'source_column', 'destination_column', 'destination_type', 'pre_copy_script'])
    for table, columns in STAGE.items():
        for name, datatype in columns:
            writer.writerow([f'CP_{table}', f'dbo.slv_{table}', f'staging.{table}', name, name, datatype, f'TRUNCATE TABLE staging.[{table}];'])

write('06_preview_gold.sql', '\n\n'.join(f'SELECT TOP (10) * FROM dbo.[{t}];' for t in GOLD))
print(f'Generated phase 5 SQL and mapping in {ROOT}')
print(f'Staging rules: {len(stage_checks)}; Gold rules: {len(gold_checks)}')
