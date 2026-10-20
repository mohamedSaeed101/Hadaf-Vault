# CR-94062 — decisions during implementation

- **2026-10-07: permission id 494 → 500.** The SQL review (round 1) found 494 already used on `origin/Stage_Beta` and `fx123089` ("Add new price to confirmed purchase order", module 623). Stage_Beta also holds 495–499. Our row sat mid-list, so the merge would produce no conflict and the MERGE would fail on Stage Beta with a duplicate key.
  - Checked after a fetch on 2026-10-07: no remote branch uses 500–509.
  - New row `(500, N'Logistics Customers', N'عملاء خدمات لوجستية', 419)` goes at the **end** of `0003_Acc_ModulePermission.sql`.
  - The same id changes in `BankGuaranteePayeeType` (backend) and `AccModulePermissionList` (desktop).
  - Re-check the highest id across `origin/*` right before pushing.
- **2026-10-07: test coverage (review 1, row 7).**
  - **Covered:** Create/Update are refused without a Logistics licence, in `BankGuaranteeLogisticsLicenceGuardTest`. For that, `CashControl.Logic.Test` now references `CashControl.Application` (a project reference, not a package).
  - **Not covered by unit tests:** the Search (ApplicationId, CustomerId) lookup and the payee-type licence filter. Both run async EF queries, and CashControl has no async-queryable test double; the only one is in Logistics. Both are checked on the tenant in P8.
- **2026-10-07: `GetCustomerOrAccount` has no paging (review 1, row 14).** This is pre-existing debt and the endpoint shape is unchanged. The query is now `AsNoTracking` and licence-gated.
- **2026-10-07: report header (review 1, rows 6/9/15).**
  - Customer names come from the TVF rows, which are correct per ApplicationId; there is still no `Cnt_Owner` mapping in AnalyticsReader.
  - A selected customer with no rows is no longer named.
  - The "All" label for customers is dropped.
  - The 3 Logistics product names are repeated in AnalyticsReader, which cannot reference `CashControl.Logic`.
- **2026-10-07: desktop search form (review 1, row 4).** `frmCustomerSearch_New` (shared by about 8 screens) now also matches on code. The change is additive and outside the plan's files; mention it in the PR.
