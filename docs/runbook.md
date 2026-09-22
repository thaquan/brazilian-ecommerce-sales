# Runbook

## Prerequisites

Prepare a Fabric workspace with Bronze and Silver Lakehouses and a Gold Warehouse, a SQL Server 2019+ instance with Windows authentication, Power BI Desktop with PBIP support, and a Standard gateway that can reach SQL Server.

## Fabric load

1. Import `fabric/dataflows/templates/DF_Olist_Bronze.pqt` and select destination connections.
2. Import the reviewed and TEST notebooks. Attach the correct default Silver Lakehouse.
3. Import the pipeline templates. Replace workspace, Lakehouse, Warehouse, notebook, pipeline, and connection IDs.
4. Run Bronze, then Silver. Require DQ ERROR count zero and a successful persisted-count check.
5. Validate and create staging/Gold objects with the SQL files in `fabric/sql/`.
6. Run the normal E2E pipeline and inspect activity history and GoldLoadAudit.

The exported E2E template includes a nested staging resource. Do not import both nested and standalone staging pipelines without checking for duplicate names and IDs.

## SQL Server serving path

```powershell
.\sql\provision-sqlserver.ps1 -Server 'SQLSERVER-DEMO\SQLEXPRESS'
.\sql\validate-sqlserver.ps1
```

Copy the seven business Gold tables to `OlistDW` through the gateway. Wait for all seven Copy activities to succeed, run reconciliation, and then refresh `Olist_SQLServer`.

## Power BI Service

Publish the PBIP report, map the SQL source to the gateway connection, run Refresh now, and inspect Refresh history. The current verified run was On demand and Completed in 27 seconds. Configure a schedule only after the data load has an atomic completion boundary.

## Troubleshooting

- DQ failure: stop downstream activity, inspect the rule for the current run ID, fix the source or transformation, and rerun.
- Gateway offline: check the gateway service, network access, and the exact server/database connection.
- Missing visuals: confirm the report references the intended semantic model and that measures exist in TMDL.
- RLS SSO limitation: record the web test as skipped; do not claim Viewer validation passed.

The public release uses sample values. Never run it without remapping connections and identities.
