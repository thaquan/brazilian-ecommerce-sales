> Ghi chú cập nhật 21/09/2026: nội dung triển khai/kiểm tra dưới đây được giữ theo thời điểm ghi nhận. Xem [trạng thái và evidence mới nhất](testing.md). Không suy luận test đã đạt chỉ từ hướng dẫn cấu hình.

# Stage 9 — SQL Server serving path

## Verified local destination

- Server: `SQLSERVER-DEMO\SQLEXPRESS` (SQL Server Express).
- Database: `OlistDW`, created on 19 September 2026.
- Collation: `Latin1_General_100_CI_AS_SC_UTF8`, preserving Unicode in Fabric varchar columns.
- Tables: DimDate, DimCustomer, DimProduct, DimSeller, FactOrders, FactOrderItem, FactPayments, plus GoldLoadAudit.
- Provisioning verification: all eight tables exist and initially contain zero rows. This was the initial provisioning state; the seven business tables have since been loaded, as recorded below.
- Repeatable script: `sql/provision-sqlserver.ps1`. It uses the project's `fabric/sql/02_create_gold.sql`, preserves existing tables, and uses Windows authentication. Existing table schemas are not automatically migrated.

## Gateway and connections

Progress on 20 September 2026: user registered GW_Olist_Demo (Online/Ready screenshot) and created CN_Olist_SQLServer successfully. Copy_DimDate completed from DataWarehouse to SqlServer: 1,096 rows read and copied, 16 seconds, no errors. Automatic data consistency verification was NotVerified. Independent SQL destination check confirmed 1,096 rows, 1,096 distinct date keys, and dates 2016-01-01 through 2018-12-31. Other seven destination tables, including audit, remained empty at that check. This is the initial manual full-load pilot; staged atomic refresh and scheduling are not implemented yet.

The Microsoft Standard gateway installer 3000.334.2 was downloaded from the official installation guide and verified with a valid Microsoft Corporation Authenticode signature. Installation completed with exit code 0; `PBIEgwService` is Running. No restart was requested. Installer/logs: workspace `.tools/gateway/`. The Gateway configuration application was launched for user sign-in and registration. Subsequent user screenshots confirmed cloud registration and Online status for GW_Olist_Demo.

Register a new gateway with the project account `analyst@example.com`, using a unique name such as `GW_Olist_Demo`. Enter and retain the recovery key privately; do not put it in Git or chat. The gateway must be Online before pipeline runs or Service refresh can succeed.

Fabric destination connection:

| Setting | Value |
| --- | --- |
| Type | SQL Server via on-premises gateway |
| Connection name | CN_Olist_SQLServer |
| Server | SQLSERVER-DEMO\SQLEXPRESS |
| Database | OlistDW |
| Gateway | Registered GW_Olist_Demo cluster |
| Authentication | Windows credentials entered privately in the connection UI |

The Microsoft school login used to register Gateway is distinct from the Windows/SQL credentials used to access local SQL Server. Do not reuse the school email as SQL credentials without confirming the server authentication setup.

## Remaining implementation

Update 20 September 2026, 11:19 local time: seven business tables loaded and independently checked in SQL Server. Counts: DimDate 1,096; DimCustomer 96,096; DimProduct 32,951; DimSeller 3,095; FactOrders 99,441; FactOrderItem 112,650; FactPayments 103,886. All seven surrogate-key duplicate/null checks, ten dimension-reference checks (including non-null delivered/estimated dates), and item/payment grain checks returned zero failures. Merchandise 13,591,643.70; freight 2,251,909.54; order value including freight 15,843,553.24; payments 16,008,872.12 BRL. These match previously recorded Fabric report totals; a fresh simultaneous source snapshot comparison was not performed. Evidence: `phase-9-sql-validation.json`; repeatable check: `sql/validate-sqlserver.ps1`. The separate SQL Server Import report is now saved and verified; see ../powerbi/README-sqlserver.md for model, render, and filter evidence. Gateway cloud refresh scheduling is not completed.

1. Complete installation and gateway registration; verify Online.
2. Create and test the SQL Server destination connection and the Fabric Warehouse source connection.
3. Build `PL_Olist_Gold_To_SQLServer` using actual connection IDs. Copy seven Gold tables and optionally the audit table, with explicit column mappings and decimal precision preserved.
4. For a repeatable full refresh, load into staging tables and validate before promoting a complete batch. Avoid exposing partly refreshed dimensions/facts or appending duplicate snapshots. Do not schedule refresh until the load succeeds and reconciliation passes.
5. Reconcile row counts and monetary KPIs against the same Fabric Gold snapshot; include orphan and duplicate-key checks.
6. Create a separate Import semantic model and report `Olist_SQLServer`, preserving the existing Fabric report. Reproduce relationships and numeric measures, including report-local measures needed by the six pages.
7. Publish, map the semantic model to the gateway SQL connection, perform refresh, and configure its schedule after the data-copy schedule. Record successful refresh evidence.

Stage 8 web Test as role was explicitly skipped by the user because the Service reported an SSO limitation. XMLA RLS test results remain in `powerbi/rls-evidence-20260919.json`; the skipped web test is not a pass.

## Official references

- https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install
- https://learn.microsoft.com/en-us/fabric/data-factory/how-to-access-on-premises-data
- https://learn.microsoft.com/en-us/fabric/data-factory/connector-sql-server-copy-activity
