# Dynamic RLS — CustomerStateAccess

Status (19 September 2026): single-user pilot role deployed on Fabric and verified through XMLA role impersonation. User confirmed Service role assignment; supplied UI shows CustomerStateAccess with one member. Web Test as role was attempted but Fabric reported that it does not work with Single Sign-On (SSO). User explicitly chose to skip this web test and continue to stage 9. Actual Viewer/report behavior remains unverified; skipped tests are not marked passed.

## Deployed pilot

Role `CustomerStateAccess` has Read permission and these two table filters:

```dax
-- DimCustomer
USERPRINCIPALNAME() = "analyst@example.com"
    && DimCustomer[state_code] = "SP"

-- GoldLoadAudit
FALSE()
```

This pilot uses the approved email/SP mapping directly in the role. The physical `SecurityUserState` table and the scalable implementation described below have NOT been deployed. There are still eight model tables and nine relationships; the three active DimCustomer-to-fact paths were verified before deployment.

Verified with the authenticated UPN and the role imposed on the DAX connection:

| Check | Result |
| --- | --- |
| Visible customer states | SP only |
| Orders | 41,752 |
| Order items | 47,461 |
| Payment records | 43,625 |
| Order value including freight | R$5,924,087.82 |
| Payment value | R$6,000,585.04 |
| Compare role totals to explicit SP filter without role | Equal for all five metrics |
| REMOVEFILTERS() | Visible state remains SP |
| Request RJ orders under role | BLANK, no accessible rows |
| Audit rows, including ALL(GoldLoadAudit) | BLANK, no accessible rows |

Evidence: `rls-evidence-20260919.json`. This is DAX-to-DAX verification, not SQL reconciliation. Other-user denial follows from the predicate but has not been tested with a second real identity. No role member has been assigned by these tools.

The user completed role membership assignment through Fabric. Web Test as role is deferred at the user's request because of the SSO limitation shown in the supplied screenshot. Do not change the connection identity merely to bypass this test. Stage 9 can proceed under this recorded exception; do not describe the web or actual Viewer tests as passed.

Approved mapping: `analyst@example.com` → `SP` (São Paulo).
Scope: customer current state, not seller state or historical order address.
Target: `WS_Olist_Demo / SM_Olist_Analytics`.

## Planned expansion to a mapping table (not yet deployed)

1. Execute `../fabric/sql/07_security_user_state.sql` in `WH_Olist_Gold`.
2. Add physical table `dbo.SecurityUserState` to the existing Direct Lake model, with text columns `user_upn` and `state_code`. Keep it disconnected and hidden. Hiding alone is not security.
3. Check the active one-to-many paths from DimCustomer to all three facts. Keep the existing single-direction relationships; do not enable bidirectional filtering.
4. Update the existing `CustomerStateAccess` role: replace its pilot DimCustomer filter with the mapping-table expression below, add the SecurityUserState filter, and preserve the GoldLoadAudit filter. Preserve unrelated existing roles and permissions.
5. On the Fabric semantic model Security screen, add the approved email to this role. Do not add it to a second unrestricted role. Do not downgrade the owner's workspace role.
6. Verify the Direct Lake cloud connection identity and source permissions. For consumer access through semantic-model RLS, use the supported fixed-identity setup; do not grant broad source access merely to make a test pass.
7. Run the acceptance tests below on the uploaded report connected to this model.

RLS belongs to the shared Fabric semantic model, not this live-connected PBIX report. Adding the security table changes the model table count, but does not change the seven business tables or require another business relationship.

## Table filters in the same role

`SecurityUserState`:

```dax
SecurityUserState[user_upn] = USERPRINCIPALNAME()
```

`DimCustomer`:

```dax
VAR CurrentUPN = USERPRINCIPALNAME()
VAR AllowedStates =
    SELECTCOLUMNS (
        FILTER (
            SecurityUserState,
            SecurityUserState[user_upn] = CurrentUPN
        ),
        "AllowedState", SecurityUserState[state_code]
    )
RETURN
    DimCustomer[state_code] IN AllowedStates
```

`GoldLoadAudit`:

```dax
FALSE()
```

Audit rows contain all-country counts and are not related to DimCustomer. Blocking them prevents disclosure of those totals. On Data Health, latest-load cards and history will be empty for this role; current fact-count cards will reflect only SP through DimCustomer. ALL/REMOVEFILTERS in measures cannot remove RLS. General product/seller catalog metadata remains visible, while transaction measures are restricted by customer state. This role is not a seller-tenant isolation design.

## Remaining report-level acceptance tests

| Test | Required result |
| --- | --- |
| Test as role with approved UPN | Customer state only SP; transaction KPIs match the SQL outputs |
| Date selection | Orders, item values and payments respect selected purchase dates within SP |
| Category/seller selection | Only permitted SP item transactions contribute to Sales & Sellers |
| Reset filters | SP security remains enforced |
| Navigate all pages | No unrestricted transaction totals appear |
| Data Health | Audit history/latest-load values unavailable; current counts restricted to SP |
| Unmapped identity evaluated under the role | No customer/transaction rows and no audit rows |
| Actual Viewer/read-only consumer | Same authorized data, with cloud connection working |
| Owner without role simulation | Full data can remain visible because workspace write roles bypass RLS |

Capture SQL values, membership and report-level role-test screenshots before marking stage 8 complete. Desktop schema validation and screenshots alone are not RLS evidence. The deployed pilot and XMLA tests are documented above; this checklist covers the remaining report/consumer tests and future mapping-table expansion.

## References

- [Microsoft: RLS and role testing](https://learn.microsoft.com/en-us/fabric/security/service-admin-row-level-security)
- [Microsoft: Direct Lake security integration](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-security-integration)
- [Microsoft: RLS guidance](https://learn.microsoft.com/en-us/power-bi/guidance/rls-guidance)
