# Fabric export review

The repository contains the following exports supplied from Fabric:

| Artifact | Location | Notes |
|---|---|---|
| Bronze Dataflow | `fabric/dataflows/templates/DF_Olist_Bronze.pqt` | Nine source queries and destination queries |
| Main E2E pipeline | `fabric/pipelines/PL_Olist_E2E/` and `templates/` | Bronze → Silver → staging → Gold |
| Staging pipeline | `fabric/pipelines/PL_Olist_Load_Staging/` | Nine Copy activities |
| SQL Server copy pipeline | `fabric/pipelines/PL_Olist_Gold_To_SQLServer/` | Seven Copy activities |
| DQ test pipeline | `fabric/pipelines/PL_Olist_E2E_TEST_DQ/` | Points to the TEST notebook |
| Silver notebooks | `fabric/notebooks/` | Normal and forced-failure source versions |
| Direct Lake model | `fabric/semantic-models/SM_Olist_Analytics/` | TMDL tables, measures, relationships, and RLS role |

The exports are configuration evidence, not a deployment script. Template parameters and credentials must be selected again in the target workspace. The E2E templates include a nested staging resource; avoid importing duplicate resources without reviewing IDs.

Notebook outputs were removed from the public source. The TEST notebook contains a forced-failure rule, but its original saved output matched the normal notebook, so it is not accepted as evidence that the failure run actually executed.
