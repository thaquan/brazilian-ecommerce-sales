import ast
import copy
import json
from pathlib import Path

original = json.loads(Path('D:/NB_Olist_Silver.ipynb').read_text(encoding='utf-8-sig'))
nb = copy.deepcopy(original)
cells = nb['cells']
def source(i):
    return ''.join(cells[i]['source'])
def put(i, text):
    cells[i]['source'] = text.splitlines(keepends=True)
def code(text):
    return {'cell_type': 'code', 'metadata': {}, 'execution_count': None,
            'outputs': [], 'source': text.splitlines(keepends=True)}

put(0, '''from pyspark.sql import functions as F
from pyspark.sql.window import Window
from datetime import datetime, timezone
from uuid import uuid4

# Run all cells from a fresh session. Preserve Olist wall-clock dates using UTC.
spark.conf.set("spark.sql.session.timeZone", "UTC")
BRONZE = "LH_Olist_Bronze.dbo"
SILVER = "LH_Olist_Silver.dbo"
RUN_ID = str(uuid4())
dq = []
def check(rule, failed, total, severity="ERROR"):
    dq.append((RUN_ID, rule, int(total), int(failed), severity,
               "PASS" if failed == 0 else ("FAIL" if severity == "ERROR" else "WARN"),
               datetime.now(timezone.utc).replace(tzinfo=None)))

def gate():
    result = spark.createDataFrame(dq, "run_id string, rule string, row_count long, failed_rows long, severity string, status string, checked_at timestamp")
    result.write.format("delta").mode("append").saveAsTable(f"{SILVER}.dq_results")
    result.show(200, truncate=False)
    if any(row[5] == "FAIL" for row in dq):
        raise RuntimeError("DQ failed. Silver data tables were not written. See dq_results for run " + RUN_ID)

def zip5(df, col):
    value = F.trim(F.col(col).cast("string"))
    return df.withColumn(col, F.when(value.rlike(r"^[0-9]{1,5}$"), F.lpad(value, 5, "0")))
''')
raw_check = '''# Check source keys BEFORE dropDuplicates; do not silently discard conflicting rows.
raw = {"orders": orders, "items": items, "customers": customers,
       "products": products, "sellers": sellers, "payments": payments,
       "reviews": reviews, "geo": geo, "category_translation": category_translation}
raw_counts = {name: df.count() for name, df in raw.items()}
keys = {"orders": ["order_id"], "items": ["order_id", "order_item_id"],
        "customers": ["customer_id"], "products": ["product_id"],
        "sellers": ["seller_id"], "payments": ["order_id", "payment_sequential"],
        "category_translation": ["product_category_name"]}
metadata_cols = ["_batch_id", "_source_file", "_source_system", "_ingest_ts"]
for name, df in raw.items():
    missing = [c for c in metadata_cols if c not in df.columns]
    check(name + ".metadata_columns", len(missing), len(metadata_cols))
    if missing:
        print(name, "missing columns:", missing, "Fix Dataflow destination mapping and refresh Bronze first.")
    else:
        invalid = F.lit(False)
        for c in metadata_cols:
            invalid = invalid | F.col(c).isNull() | (F.trim(F.col(c).cast("string")) == "")
        check(name + ".metadata_values", df.filter(invalid).count(), raw_counts[name])
for name, key in keys.items():
    df = raw[name]
    check(name + ".duplicate_key", raw_counts[name] - df.select(*key).distinct().count(), raw_counts[name])
    invalid = F.lit(False)
    for c in key:
        invalid = invalid | F.col(c).isNull() | (F.trim(F.col(c).cast("string")) == "")
    check(name + ".null_or_blank_key", df.filter(invalid).count(), raw_counts[name])
if any(row[5] == "FAIL" for row in dq):
    gate()
'''
raw_check += '''# Normalize empty source strings to null in memory before casts (Bronze stays unchanged).
def blank_to_null(df):
    return df.select(*[F.when(F.trim(F.col(c)) == "", F.lit(None)).otherwise(F.col(c)).alias(c)
                      if t == "string" else F.col(c) for c, t in df.dtypes])
orders, items, customers, products, sellers, payments, reviews, geo, category_translation = [
    blank_to_null(raw[n]) for n in ["orders", "items", "customers", "products", "sellers", "payments", "reviews", "geo", "category_translation"]]
'''
# Date-level promised delivery: estimated midnight represents the promised day.
s = source(2).replace('.isNull(),', '.isNull() | F.col("order_estimated_delivery_date").isNull(),')
s = s.replace("F.col(\n                'order_delivered_customer_date'\n            )", "F.to_date('order_delivered_customer_date')")
s = s.replace("F.col(\n                'order_estimated_delivery_date'\n            )", "F.to_date('order_estimated_delivery_date')")
put(2, '# is_late compares calendar dates, consistent with delay_days.\n' + s)
put(3, source(3) + '\nitems = items.withColumn("shipping_limit_date", F.to_timestamp("shipping_limit_date"))\n')
put(5, source(5) + '\nfor col in ["product_name_lenght", "product_description_lenght", "product_photos_qty"]:\n    products = products.withColumn(col, F.col(col).cast("int"))\n')
put(6, '''geo = zip5(geo, "geolocation_zip_code_prefix")
geo = (geo.withColumn("geolocation_lat", F.col("geolocation_lat").cast("double"))
          .withColumn("geolocation_lng", F.col("geolocation_lng").cast("double"))
          .withColumn("geolocation_city", F.lower(F.trim("geolocation_city")))
          .withColumn("geolocation_state", F.upper(F.trim("geolocation_state"))))
centroids = geo.filter(F.col("geolocation_zip_code_prefix").isNotNull()).groupBy("geolocation_zip_code_prefix").agg(
    F.avg("geolocation_lat").alias("latitude"), F.avg("geolocation_lng").alias("longitude"))
# Most frequent city/state pair; stable lexical tie-break rather than unordered first().
labels = geo.filter(F.col("geolocation_zip_code_prefix").isNotNull()).groupBy(
    "geolocation_zip_code_prefix", "geolocation_city", "geolocation_state").count()
w_geo = Window.partitionBy("geolocation_zip_code_prefix").orderBy(
    F.desc("count"), F.col("geolocation_city").asc_nulls_last(), F.col("geolocation_state").asc_nulls_last())
labels = labels.withColumn("rn", F.row_number().over(w_geo)).filter("rn = 1").select(
    "geolocation_zip_code_prefix", F.col("geolocation_city").alias("geo_city"), F.col("geolocation_state").alias("geo_state"))
geo_zip = centroids.join(labels, "geolocation_zip_code_prefix", "left")
''')
for i, df, col in [(7, 'customers', 'customer_zip_code_prefix'), (9, 'sellers', 'seller_zip_code_prefix')]:
    s = source(i).replace('.cast("int")', '.cast("string")')
    put(i, f'{df} = zip5({df}, "{col}")\n' + s)
s = source(8).replace(').desc_nulls_last()\n    )', ').desc_nulls_last(),\n        F.col("customer_id").asc_nulls_last()\n    )')
put(8, s)
s = source(10).replace(').desc_nulls_last()\n    )', ').desc_nulls_last(),\n        F.col("review_creation_date").desc_nulls_last(),\n        F.col("review_id").asc_nulls_last(),\n        F.to_json(F.struct(*[F.col(c) for c in sorted(reviews.columns)])).asc()\n    )')
put(10, s)
validation = '''silver_tables = {
    "slv_orders": orders, "slv_order_items": items, "slv_customers": customers,
    "slv_customer_current": customer_current, "slv_products": products,
    "slv_sellers": sellers, "slv_payments": payments,
    "slv_reviews_order": reviews_order, "slv_geolocation_zip": geo_zip, "slv_date": date_df}
counts = {name: df.count() for name, df in silver_tables.items()}
for src, dst in [("orders", "slv_orders"), ("items", "slv_order_items"), ("customers", "slv_customers"),
                 ("products", "slv_products"), ("sellers", "slv_sellers"), ("payments", "slv_payments")]:
    check(dst + ".row_reconciliation", abs(counts[dst] - raw_counts[src]), raw_counts[src])
for name, df, key in [("customer_current", customer_current, "customer_unique_id"),
                     ("reviews_order", reviews_order, "order_id"), ("geo_zip", geo_zip, "geolocation_zip_code_prefix")]:
    check(name + ".unique", df.count() - df.select(key).distinct().count(), df.count())
for dst, src, key in [("slv_customer_current", raw["customers"], "customer_unique_id"),
                      ("slv_reviews_order", raw["reviews"], "order_id"),
                      ("slv_geolocation_zip", zip5(raw["geo"], "geolocation_zip_code_prefix"), "geolocation_zip_code_prefix")]:
    expected = src.filter(F.col(key).isNotNull()).select(key).distinct().count()
    check(dst + ".grain_count", abs(counts[dst] - expected), expected)
for name, child, parent, key in [("items_orders", items, orders, "order_id"),
    ("orders_customers", orders, customers, "customer_id"), ("items_products", items, products, "product_id"),
    ("items_sellers", items, sellers, "seller_id"), ("payments_orders", payments, orders, "order_id"),
    ("reviews_orders", reviews_order, orders, "order_id")]:
    check(name + ".orphan", child.join(parent.select(key).distinct(), key, "left_anti").count(), child.count())
for name, df, col in [("price", items, "price"), ("freight", items, "freight_value"), ("payment", payments, "payment_value")]:
    check(name + ".nonnegative_required", df.filter(F.col(col).isNull() | (F.col(col) < 0)).count(), df.count())
check("reviews.score", reviews.filter(F.col("review_score").isNull() | ~F.col("review_score").between(1, 5)).count(), reviews.count())
for name, df, col in [("customers", customers, "customer_zip_code_prefix"), ("sellers", sellers, "seller_zip_code_prefix"), ("geo", geo, "geolocation_zip_code_prefix")]:
    check(name + ".zip", df.filter(F.col(col).isNull() | ~F.col(col).rlike(r"^[0-9]{5}$")).count(), df.count())
# Detect nonblank source values lost during conversion, including optional fields.
conversions = [(raw["orders"], orders, "order_id", timestamp_cols),
 (raw["items"], items, ["order_id", "order_item_id"], ["shipping_limit_date", "price", "freight_value"]),
 (raw["products"], products, "product_id", ["product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm", "product_name_lenght", "product_description_lenght", "product_photos_qty"])]
for old, new, key, cols in conversions:
    joined = old.alias("r").join(new.alias("s"), key)
    for c in cols:
        present = F.col("r." + c).isNotNull() & (F.trim(F.col("r." + c).cast("string")) != "")
        check("parse." + c, joined.filter(present & F.col("s." + c).isNull()).count(), old.count())
check("orders.purchase_required", orders.filter(F.col("order_purchase_timestamp").isNull()).count(), counts["slv_orders"])
check("orders.delivery_before_purchase", orders.filter(F.col("order_delivered_customer_date") < F.col("order_purchase_timestamp")).count(), counts["slv_orders"], "WARN")
unknown_delivery = F.col("order_delivered_customer_date").isNull() | F.col("order_estimated_delivery_date").isNull()
check("orders.unknown_lateness", orders.filter(unknown_delivery & F.col("is_late").isNotNull()).count(), counts["slv_orders"])
for name, df in [("customer_current", customer_current), ("sellers", sellers)]:
    check(name + ".unmatched_geo", df.filter(F.col("latitude").isNull() | F.col("longitude").isNull()).count(), df.count(), "WARN")
check("date.row_count", abs(counts["slv_date"] - 1096), 1096)
check("date.unique", counts["slv_date"] - date_df.select("date_key").distinct().count(), counts["slv_date"])
for c in ["purchase_date_key", "delivered_date_key", "estimated_date_key"]:
    check("date.coverage." + c, orders.filter(F.col(c).isNotNull()).join(date_df.select(F.col("date_key").alias(c)), c, "left_anti").count(), counts["slv_orders"])
gate()  # Persist audit first; block all Silver data-table writes on ERROR.
'''
put(13, '''# Run this cell only after all preceding cells succeed. Each table is written once.
# These ten Delta writes are not a cross-table transaction; a write failure fails the notebook.
for name, df in silver_tables.items():
    (df.write.format("delta").mode("overwrite").option("overwriteSchema", "true")
       .saveAsTable(f"{SILVER}.{name}"))
''')
put(14, '''# Read persisted tables, so this inspection does not depend on orders/items variables.
for name in ["slv_orders", "slv_order_items", "slv_customers", "slv_customer_current",
             "slv_products", "slv_sellers", "slv_payments", "slv_reviews_order", "slv_geolocation_zip", "slv_date"]:
    print(name, spark.read.table("LH_Olist_Silver.dbo." + name).count())
''')
nb['cells'] = [dict(cell_type='markdown', metadata={}, source=[
    '# Reviewed Olist Silver notebook\nRun All from a fresh Spark session after publishing and refreshing the corrected Bronze Dataflow.\n'
    'ERROR checks stop before Silver data writes; WARN checks preserve source anomalies for review.\n'
    'is_late uses calendar-day delivery deadlines. Missing actual/estimated dates remain null.\n'])] + cells[:2] + [code(raw_check)] + cells[2:13] + [code(validation)] + cells[13:]
for i, cell in enumerate(nb['cells']):
    if cell['cell_type'] == 'code':
        ast.parse(''.join(cell['source']), filename=f'cell_{i}')
        cell['outputs'] = []
        cell['execution_count'] = None
        cell['metadata'] = {}
out = Path(__file__).parent / 'NB_Olist_Silver_reviewed.ipynb'
out.write_text(json.dumps(nb, ensure_ascii=False, indent=1), encoding='utf-8')
print(f'Created {out}; parsed all code cells successfully. Spark execution not performed.')
