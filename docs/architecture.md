# Architecture

The solution follows a Bronze, Silver, and Gold medallion architecture.

1. Dataflow Gen2 loads nine Olist source datasets into Bronze.
2. A PySpark notebook standardizes types, keys, dates, locations, reviews, and data-quality checks before writing Silver.
3. Fabric pipelines copy nine Silver tables to Warehouse staging.
4. T-SQL validation and `dbo.usp_build_gold` build four dimensions, three facts, and GoldLoadAudit.
5. The Gold layer feeds a Fabric Direct Lake semantic model and a separate SQL Server Import model.

The semantic model has `DimCustomer`, `DimDate`, `DimProduct`, and `DimSeller` dimensions. `FactOrders` has order grain, `FactOrderItem` has `(order_id, order_item_id)` grain, and `FactPayments` has `(order_id, payment_sequential)` grain. Dimensions filter facts in one direction. There are no fact-to-fact relationships.

The default date role uses `purchase_date_key`. `FactOrders[delivered_date_key]` has an inactive relationship to `DimDate[date_key]` and is activated only by the delivery-date measure with `USERELATIONSHIP`.

The Fabric path includes GoldLoadAudit and the CustomerStateAccess role. The SQL Server path copies seven business tables and intentionally excludes audit from the report model.

## Operational boundary

The current SQL copy uses truncate and insert per table. Refresh the Import semantic model only after all seven copy activities succeed and reconciliation passes. A production version should stage and promote a complete batch and add scheduling or CDC.
