# Data dictionary

The physical schema is defined in `fabric/sql/02_create_gold.sql`. Logical keys are validated by the reconciliation scripts; the SQL DDL does not declare physical foreign-key constraints.

| Table | Grain | Logical key | Purpose |
|---|---|---|---|
| DimDate | One calendar date | `date_key` | Purchase and delivery date roles |
| DimCustomer | One current customer location | `customer_key` | Customer geography and filtering |
| DimProduct | One product | `product_key` | Product and category analysis |
| DimSeller | One seller | `seller_key` | Seller geography and item analysis |
| FactOrders | One order | `order_key` | Status, delivery, and review metrics |
| FactOrderItem | One order item | `sales_key` | Price, freight, category, and seller metrics |
| FactPayments | One payment record | `payment_key` | Payment value and installments |
| GoldLoadAudit | One successful Gold build | `gold_run_id` | Technical load history |

Important fields include `item_gmv = price + freight_value`, `purchase_date_key`, `delivered_date_key`, `delivery_days`, `delay_days`, `is_late`, and `review_score`. Customer geography represents the current dimension record; this is not an SCD2 history.

The model relationships are documented in `fabric/semantic-models/SM_Olist_Analytics/definition/relationships.tmdl` and `powerbi/Olist_SQLServer.SemanticModel/definition/relationships.tmdl`.
