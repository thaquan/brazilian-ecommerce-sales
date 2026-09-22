# Fabric pipeline exports

The folders contain readable JSON definitions. The `templates/` folder contains the original Fabric pipeline ZIP exports after sanitization.

- `PL_Olist_E2E`: Bronze refresh, Silver notebook, staging invoke, and Gold stored procedure.
- `PL_Olist_Load_Staging`: nine Silver-to-Warehouse Copy activities.
- `PL_Olist_Gold_To_SQLServer`: seven Gold-to-SQL Server Copy activities.
- `PL_Olist_E2E_TEST_DQ`: test pipeline pointing to the forced-failure notebook.

Replace workspace, connection, notebook, pipeline, and Warehouse IDs before import. The E2E templates include a nested staging resource, so review duplicate IDs before importing both the parent and standalone staging template.
