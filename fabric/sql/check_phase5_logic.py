"""Small relational checks in SQLite; NOT a Fabric T-SQL compatibility test."""
import contextlib
import io
import re
import runpy
import sqlite3
from pathlib import Path

with contextlib.redirect_stdout(io.StringIO()):
    g = runpy.run_path(str(Path(__file__).with_name('generate_phase5.py')))
db = sqlite3.connect(':memory:')

def sql(s):
    s = s.replace('[LH_Olist_Silver].[dbo].[slv_', '[silver_')
    s = re.sub(r'\[(staging|dbo)\]\.\[([^\]]+)\]', r'[\1_\2]', s)
    s = re.sub(r'\b(staging|dbo)\.\[([^\]]+)\]', r'[\1_\2]', s)
    s = re.sub(r'\b(staging|dbo)\.([A-Za-z_]+)', r'\1_\2', s)
    return s.replace('COUNT_BIG(', 'COUNT(')

for schema, tables in [('staging', g['STAGE']), ('silver', g['STAGE']), ('dbo', g['GOLD'])]:
    for t, columns in tables.items():
        db.execute(f'CREATE TABLE [{schema}_{t}] (' + ', '.join(
            f'[{c}] ' + ('TEXT' if 'varchar' in typ or 'date' in typ else 'NUMERIC')
            for c, typ in columns) + ')')

def add(table, values):
    columns = [n for n, _ in g['STAGE'][table]]
    row = [values.get(c) for c in columns]
    for schema in ['staging', 'silver']:
        db.execute(f'INSERT INTO {schema}_{table} VALUES (' + ','.join('?' for _ in row) + ')', row)

add('date', dict(date_key=20170101, full_date='2017-01-01', year=2017, quarter=1,
    month_number=1, month_name='January', year_month='2017-01', week_number=52,
    day_of_week=1, day_name='Sunday', is_weekend=1))
add('customer_current', dict(customer_unique_id='repeat_customer', customer_state='SP'))
for c in ['c1', 'c2']:
    add('customers', dict(customer_id=c, customer_unique_id='repeat_customer'))
for o, c in [('o1', 'c1'), ('o2', 'c2')]:
    add('orders', dict(order_id=o, customer_id=c, order_status='delivered',
        order_purchase_timestamp='2017-01-01', purchase_date_key=20170101,
        delivered_date_key=20170101, estimated_date_key=20170101,
        delivery_days=0, delay_days=0, is_late=0))
add('products', dict(product_id='p1', product_category_name_english='unknown'))
add('sellers', dict(seller_id='s1', seller_state='SP'))
for o, item, price in [('o1', 1, 10), ('o1', 2, 20), ('o2', 1, 30)]:
    add('order_items', dict(order_id=o, order_item_id=item, product_id='p1',
        seller_id='s1', price=price, freight_value=1, item_gmv=price+1))
for o, seq, amount in [('o1', 1, 12), ('o1', 2, 20), ('o2', 1, 31)]:
    add('payments', dict(order_id=o, payment_sequential=seq, payment_type='credit_card',
        payment_installments=1, payment_value=amount))
add('reviews_order', dict(order_id='o1', review_score=5))

def failures(checks):
    return [(name, n) for name, n in db.execute(sql('\nUNION ALL\n'.join(checks))) if n]

assert not failures(g['stage_checks']), failures(g['stage_checks'])

def build():
    for t in reversed(g['GOLD']):
        db.execute(f'DELETE FROM dbo_{t}')
    for t, select in g['SELECTS'].items():
        db.execute(f'INSERT INTO dbo_{t} ' + sql(select))

build()
assert not failures(g['gold_checks']), failures(g['gold_checks'])
assert db.execute('SELECT COUNT(*), SUM(price), SUM(item_gmv) FROM dbo_FactOrderItem').fetchone() == (3, 60, 63)
assert db.execute('SELECT COUNT(*) FROM dbo_DimCustomer').fetchone()[0] == 1
assert db.execute("SELECT review_score FROM dbo_FactOrders WHERE order_id='o2'").fetchone()[0] is None
snapshot = {t: db.execute(f'SELECT * FROM dbo_{t} ORDER BY 1').fetchall() for t in g['GOLD']}
build()
assert all(snapshot[t] == db.execute(f'SELECT * FROM dbo_{t} ORDER BY 1').fetchall() for t in g['GOLD'])
db.execute("UPDATE staging_order_items SET price=99 WHERE order_id='o1' AND order_item_id=1")
assert any('missing_or_changed' in name for name, _ in failures(g['stage_checks']))
db.execute("UPDATE staging_order_items SET price=10 WHERE order_id='o1' AND order_item_id=1")
db.execute("INSERT INTO staging_order_items SELECT * FROM staging_order_items WHERE order_id='o1' AND order_item_id=1")
assert any('duplicate_grain' in name for name, _ in failures(g['stage_checks']))
db.execute("DELETE FROM dbo_DimProduct")
assert any('product_key.orphan' in name for name, _ in failures(g['gold_checks']))
print('PASS: separate item/payment grains; repeat-customer mapping; missing review preserved;')
print('unchanged-source rebuild; changed copy values, duplicate grain and orphan detection.')
print('118 validation queries evaluated on synthetic data in SQLite after dialect translation.')
print('Fabric procedure compilation, transactions, Copy Activity and real Olist data NOT tested.')
