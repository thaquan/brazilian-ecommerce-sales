# Testing and evidence

| Test | Status | Evidence |
|---|---|---|
| Seven SQL table row counts | Verified | `docs/phase-9-sql-validation.json` |
| SQL duplicate, orphan, and grain checks | Zero failures in saved run | Same JSON |
| SQL model structure | 7 tables, 33 measures, 9 relationships | SQL TMDL |
| Fabric model structure | 8 tables, 20 base measures, 9 relationships, RLS role | Fabric TMDL |
| Service KPI totals | Matched saved SQL baseline | `docs/evidence/phase-9/service-dax.json` |
| Seven Gold-to-SQL copy activities | Succeeded | `docs/evidence/phase-9/` notes |
| Gateway mapping | Running and mapped to sample connection in public copy | Public release notes |
| On-demand semantic model refresh | Completed in 27 seconds | Service verification note |
| Desktop report render | Five SQL pages reviewed | `powerbi/screenshots/sqlserver/` |
| Fabric RLS XMLA checks | Passed for the pilot role | `powerbi/rls-evidence-20260919.json` |
| Web Test as role / Viewer identity | Skipped or not verified | Limitations |
| SQL model RLS | Not configured | Limitation |
| Forced DQ failure and recovery | Not accepted as passed; fresh run evidence required | Limitation |

The public export has been checked for JSON parsing, safe ZIP paths, original tenant identifiers, and missing local links. It has not been deployed to a clean tenant.
