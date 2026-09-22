# Portfolio status

The repository is ready for portfolio review. It includes the Fabric ingestion and transformation assets, pipeline templates, semantic model metadata, Power BI PBIP/PBIR reports, SQL Server serving path, evidence, and reproducibility notes.

The following boundaries are intentionally documented:

- The SQL Server model has no separate RLS role yet.
- Scheduled refresh is off; an on-demand gateway refresh was verified.
- Fabric web “Test as role” was skipped because the tenant reported an SSO limitation. XMLA role checks are preserved as evidence.
- A forced DQ failure and full recovery run still need a fresh run-history capture before they can be marked as passed.
- The sanitized public release has not been deployed to a clean tenant. Replace all sample connection and identity values before running it.

These limitations do not prevent the project from being shown as a completed portfolio implementation; they define the remaining production-hardening work.
