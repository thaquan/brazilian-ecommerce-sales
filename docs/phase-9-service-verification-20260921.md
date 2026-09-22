# Phase 9 Service verification — 21 September 2026

Read-only verification using Power BI Modeling MCP, Fabric MCP and Playwright. No refresh, pipeline execution or schedule modification was triggered.

## Confirmed

- Workspace: WS_Olist_Demo (`23f4a256-949e-5f7d-8c35-b63242139c25`).
- Published SQL semantic model: Olist_SQLServer (`0296012b-e83f-508d-b500-5301070fdadd`).
- Published report: `99e4e5f6-03c5-5e9b-84e1-582faea9b595`.
- Live XMLA model statistics: 7 tables, 33 measures, 9 relationships, 7 partitions, 0 security roles.
- Live DAX totals: 99,441 orders; 112,650 order items; order value including freight BRL 15,843,553.24; payments BRL 16,008,872.12. These match the previously checked SQL totals.
- Service refresh history: On demand, Completed, displayed start 9/20/2026 3:43:29 PM and end 3:43:56 PM (27 seconds). Times are recorded as displayed by the browser, without an assumed UTC conversion.
- Gateway GW_Olist_Demo: Running on SQLSERVER-DEMO. SQL source SQLSERVER-DEMO\\sqlexpress / olistdw maps to CN_Olist_SQLServer.
- Report Overview renders on Service with populated KPIs and charts.
- Pipeline PL_Olist_Gold_To_SQLServer: latest listed run Succeeded, displayed 09/20/2026 11:09 AM; run ID 9e6def9b-3a02-5d9d-acb8-47734b6adf96.
- Run details confirm all seven Copy activities Succeeded. Pipeline start 11:09:12 AM, end 11:11:34 AM. Activity durations: DimDate 19s, DimCustomer 16s, DimProduct 18s, DimSeller 15s, FactOrders 17s, FactOrderItem 23s, FactPayments 18s.

## Remaining limitations

- Scheduled refresh is Off; configured timezone is UTC. These settings were not changed.
- SQL semantic model has no RLS role. Do not treat the Fabric model's RLS as applied to this separate model.
- This verification did not rerun the load or perform a new simultaneous Fabric-to-SQL source snapshot comparison.

## Screenshots

Captured under workspace `output/playwright/phase-9/` and copied into `docs/evidence/phase-9/` for the project evidence bundle.

- `02-model-service.png`: published semantic model.
- `01-pipeline-success.png`: successful pipeline and seven activity results.
- `03-gateway-mapping.png`: Running gateway and SQL connection mapping.
- `04-refresh-success.png`: completed Service refresh.
- `05-report-overview.png`: report on Service.
