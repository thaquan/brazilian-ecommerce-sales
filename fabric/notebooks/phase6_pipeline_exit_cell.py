# Paste as the LAST code cell of the verified Silver notebook in Fabric.
# Run with all preceding cells; RUN_ID, SILVER and counts come from that notebook.
# Counts confirm persisted row counts, not a cross-table atomic snapshot.
import notebookutils

persisted_counts = {}
for table_name, expected_count in counts.items():
    actual_count = spark.read.table(f"{SILVER}.{table_name}").count()
    if actual_count != expected_count:
        raise RuntimeError(
            f"Persisted Silver count mismatch: {table_name}; "
            f"expected={expected_count}, actual={actual_count}, run_id={RUN_ID}"
        )
    persisted_counts[table_name] = actual_count

print({"silver_run_id": RUN_ID, "persisted_counts": persisted_counts})
# Keep exit outside try/except. Only reached after all writes/checks succeed.
notebookutils.notebook.exit(RUN_ID)
