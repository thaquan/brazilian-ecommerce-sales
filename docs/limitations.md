# Limitations and next steps

- SQL Server Import scheduled refresh is off; an on-demand gateway refresh was verified.
- SQL loading uses truncate and insert per table, not an atomic staging and promotion process.
- The SQL Server model has no separate RLS role. The Fabric CustomerStateAccess pilot has XMLA evidence; web role testing was skipped because the tenant reported an SSO limitation.
- A fresh DQ failure and complete recovery run still need run-history evidence before being marked passed.
- The sanitized release has not been deployed to a clean tenant. Replace all sample connections, IDs, endpoints, and RLS identities.
- Customer geography is current-state only and does not provide historical address tracking.
- The dataset is static; CDC, incremental loading, production concurrency, and SLA behavior were not evaluated.

These are documented production-hardening tasks. They do not prevent the repository from being used as a portfolio implementation.
