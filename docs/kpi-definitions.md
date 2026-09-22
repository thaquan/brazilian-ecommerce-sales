# KPI definitions

The SQL model TMDL contains the authoritative DAX. The main measures are:

| KPI | Definition | Grain / filter scope |
|---|---|---|
| Merchandise Value | `SUM(FactOrderItem[price])` | Item; product and seller filters apply |
| Freight Value | `SUM(FactOrderItem[freight_value])` | Item; product and seller filters apply |
| Order Value Including Freight | `SUM(FactOrderItem[item_gmv])` | Item; includes price and freight |
| Total Orders | `COUNTROWS(FactOrders)` | Order; all statuses |
| Orders With Items | `DISTINCTCOUNT(FactOrderItem[order_id])` | Item order IDs |
| Average Order Value | Order value divided by Orders With Items | Item order denominator |
| Payment Value | `SUM(FactPayments[payment_value])` | Payment records |
| Late Delivery Rate | Late delivered orders divided by eligible delivered orders | Purchase-date context |
| Average Delivery Days | Average non-negative delivery days for delivered orders | Purchase-date context |
| Average Review Score | Average non-blank review score | Order context |
| Repeat Customers | Customers with more than one order in current context | Customer/date context |
| Delivered Orders by Delivery Date | Delivered orders using inactive delivery-date relationship | Delivery-date measure |

Customer and purchase-date filters propagate to all three facts. Category and seller filters apply to `FactOrderItem`; they do not reduce independent order or payment totals. Payment method filters apply to `FactPayments`.

Order value and payment value are intentionally separate metrics. AOV uses orders with items as the denominator. Missing lateness is excluded from SLA metrics; missing or negative delivery days are excluded from the delivery-day average.
