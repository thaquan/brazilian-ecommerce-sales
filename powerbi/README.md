# Fabric Power BI report

`RPT_Olist_Analytics.pbip` is the Fabric report. It uses a live connection to the Direct Lake semantic model represented by the sanitized TMDL under `fabric/semantic-models/SM_Olist_Analytics/`.

Pages: Overview, Sales & Sellers, Customers, Delivery & Reviews, Payments, and Data Health. The native sidebar changes pages and the Home action returns to Overview. The report design is inspired by AdminLTE v4 but uses native Power BI visuals.

The report model includes the CustomerStateAccess pilot role. XMLA role checks are preserved in `rls-evidence-20260919.json`; web role testing was skipped because of the tenant SSO limitation. Replace the sample identity before deployment.

`build-report.cjs` is the reproducible layout source. Validate PBIR and reload Desktop after regeneration.
