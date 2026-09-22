# CustomerStateAccess RLS

The Fabric semantic model contains a pilot role named `CustomerStateAccess`.

The role restricts `DimCustomer` to state `SP` for the sample identity `analyst@example.com` and blocks `GoldLoadAudit` with `FALSE()`. The role was verified with XMLA impersonation for customer state, orders, order items, payment records, order value, payment value, `REMOVEFILTERS`, and an inaccessible RJ state.

The Service web “Test as role” flow was skipped because the tenant reported that it does not work with SSO. A second real identity and actual Viewer behavior were not verified. The physical `SecurityUserState` mapping table is not deployed in the pilot. The SQL Server model has no RLS role.

Replace the sample identity, assign membership in the target Service, and repeat the acceptance checks before using this role for restricted sharing.
