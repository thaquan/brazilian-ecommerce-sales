# SQL Server Power BI report

`Olist_SQLServer.pbip` is the Import report for the SQL Server serving path. It contains five report pages: Overview, Sales & Sellers, Customers, Delivery & Reviews, and Payments.

The model contains seven business tables, 33 measures, eight active relationships, and one inactive delivery-date relationship. The reviewed baseline includes 99,441 orders, 112,650 order items, BRL 15,843,553.24 order value including freight, and BRL 16,008,872.12 payments.

The report was published and refreshed through an on-premises gateway in the source environment. The public release has sample connections and must be remapped before use. `build-sql-report.cjs` rebuilds the PBIR page layout.

SQL RLS is not configured in this model. Scheduled refresh is off in the verified source environment.
