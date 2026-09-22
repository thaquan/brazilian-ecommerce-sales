# Olist SQL Server report

Verified and saved in Power BI Desktop on 20 September 2026.

- Entry point: `Olist_SQLServer.pbip`.
- Import source: `SQLSERVER-DEMO\SQLEXPRESS`, database `OlistDW`.
- Seven business tables; 33 measures; eight active, single-direction relationships and one inactive delivery-date relationship.
- DimDate is marked as the date table; automatic date tables and fact-to-fact relationships removed.
- Five pages: Overview, Sales & Sellers, Customers, Delivery & Reviews, Payments. Sidebar navigation and Home actions preserved.
- Data Health is excluded because GoldLoadAudit has not been loaded into this model.
- Screenshots reviewed: `screenshots/sqlserver/`. All five pages render data without visual error banners.
- PBIR validation: zero errors; one unavailable Microsoft visualContainer 2.12.0 schema warning. Full validation against that remote schema was therefore unavailable.
- Desktop confirms no unsaved changes after native Save.

## Data checks

Baseline matches checked SQL totals: 99,441 orders; 112,650 order items; BRL 15,843,553.24 order value including freight; BRL 16,008,872.12 payments.

Live DAX filter checks after reopening:

| Filter | Orders | Items | Payments BRL |
| --- | ---: | ---: | ---: |
| All | 99,441 | 112,650 | 16,008,872.12 |
| Customer state SP | 41,752 | 47,461 | 6,000,585.04 |
| Purchase year 2017 | 45,101 | 50,864 | 7,249,746.73 |
| Seller state SP | 99,441 | 80,342 | 16,008,872.12 |

Customer/date filters propagate to all three facts. Seller filters affect item metrics only, as intended. Delivery-date measure executes successfully (40,506 delivered orders with customer state SP and no date filter). These are ordinary filter tests, not RLS tests.

## Remaining phase 9 work

1. Publish this separate report from Desktop to `WS_Olist_Demo`.
2. In the published SQL semantic model settings, map the SQL source to `CN_Olist_SQLServer` on `GW_Olist_Demo`.
3. Run Refresh now and record successful refresh history.
4. Establish complete-batch SQL loading before scheduling dependent semantic model refresh. Current copy is a manual full-load pilot.
5. This SQL model does not yet contain the Fabric model's RLS role. Configure and verify it separately before restricted sharing.

The Fabric report and its RLS evidence remain separate. The user-skipped Fabric web role test is not counted as a pass.

## Service verification update — 21 September 2026
Publish, gateway mapping and on-demand Service refresh are now independently verified. All seven copy activities succeeded. See ../docs/phase-9-service-verification-20260921.md and ../docs/evidence/phase-9/. Scheduled refresh remains Off and SQL RLS remains unconfigured.
