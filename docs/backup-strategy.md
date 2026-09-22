# Backup strategy

Fabric trial capacity is not a durable backup target. Microsoft states that after a trial expires, Fabric content remains in OneLake for seven days and becomes inactive unless the workspace is assigned to a paid capacity. Export before expiry.

Use three independent copies:

1. **GitHub** — definitions and code: notebooks, SQL, pipeline/Dataflow templates, PBIP/PBIR, TMDL, documentation, and selected evidence. This repository is the sanitized copy.
2. **SQL Server Express** — the seven Gold business tables and GoldLoadAudit in `OlistDW`. Create a `COPY_ONLY` `.bak`, run `RESTORE VERIFYONLY`, and store the file in OneDrive/SharePoint or an external drive. Do not commit it to GitHub.
3. **External file storage** — keep the raw Olist CSV files, exported `.pqt`/pipeline templates, notebook exports, PBIP package, evidence, and the SQL backup in a dated folder. OneDrive or SharePoint is convenient; an external drive provides a second independent copy.

## Immediate action

Run the backup script on the SQL Server machine after replacing the sample server and output path:

```powershell
.\sql\backup-olistdw.ps1 `
  -Server 'YOUR-SQL-SERVER\SQLEXPRESS' `
  -Database 'OlistDW' `
  -BackupFile 'C:\Backup\OlistDW_2026-09-22.bak'
```

Copy the verified `.bak` to external storage. Keep the date, SQL Server version, database name, and SHA-256 hash in a text file beside it. Test restoration to a different database name when possible.

## What can be restored

- GitHub restores code, definitions, report layout, measures, relationships, and documentation.
- The `.bak` restores the local SQL Server serving path and its data.
- Raw CSV/Parquet restores the source layer for rebuilding Fabric.
- Fabric item exports restore much of the item configuration, but connections, credentials, capacity, workspace IDs, and some service settings must be configured again.

Do not put passwords, gateway recovery keys, access tokens, `.pbix` caches, or raw customer data in the public repository. The SQL backup is a private data backup, not a GitHub artifact.
