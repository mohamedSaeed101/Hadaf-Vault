# Review round 2 — CR_125294   base front 69b8fb2428   head = base + uncommitted working tree   verdict: pass

This round re-checks the review-1 rows only. Diff: `git diff origin/Master_Stable` in `AccFlex_Cloud_Front`. The file set is the same 9 files as round 1: 3 shells (.ts + .html), `accounting-reports.module.ts`, and 2 `payroll.json`. Build gate: I relied on the implementer's report (`npm run testing`: only the 4 baseline errors in logistics SalesQuotation, 0 in payroll). Nothing in the code contradicts it.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | …/advance-report-shell.component.ts:15,37-47; employee-deduction-shell.component.ts:15,37-47; unpaid-advanced-payments-shell.component.ts:18,38-48 | closed | Front `core.md` "Subscriptions: `SubSink`" | Verified in all three shells: `private subs = new SubSink()`, `getLang()` subscription wrapped in `this.subs.add(...)`, `implements OnInit, OnDestroy`, `ngOnDestroy` calls `this.subs.unsubscribe()`. `subsink` ^1.0.2 is already in package.json and used across payroll | none |
| 2 | …/advance-report-shell.component.ts:59,70; employee-deduction-shell.component.ts:59,70; unpaid-advanced-payments-shell.component.ts:82 | closed | Front `core.md` "avoid adding new `any`" | `onDetailExpand(e: DetailExpandEventArgs)` matches `report-grid-multi-request` `@Output onDetailExpand = new EventEmitter<DetailExpandEventArgs>()` (emits `{ parentRowData, tabIndex }`). `handleEmployeeIdChange(e: { selectedRowKeys: number[]; isSelectAll: boolean })` matches the `shared-employee-list` `OnValueChanged.emit({ selectedRowKeys, isSelectAll })` payload (emitter is `EventEmitter<any>`, so it is assignable). The unpaid shell has no detail grid, so it correctly has no `onDetailExpand`. Template bindings unchanged | none |
| 3 | AccFlex_Cloud_ERP/…/AdvanceAndPurchaseRptConfigs.cs:1 | dropped | ERP `report-backend.md` Artifact 2 | Skip accepted: optional nit, no behaviour impact | none |
| 4 | AccFlex_Cloud_ERP/…/PayrollOdataController.cs:206-291 | dropped | ERP `accflex-erp-api.md` §API Layer | Skip accepted: matches every sibling action in the controller | none |
| 5 | AccFlex_Cloud_ERP/…/EmployeesAdvance.cs:28; EmployeePurchase.cs:28 | dropped | ERP `report-backend.md` §Master-Detail | Skip accepted: the Front never sends `$expand`; precedent `PurchaseReturnsReportPrinter` | none |
| 6 | AccFlex_Cloud_ERP/…/UnpaidAdvancePaymentsRptAng.cs:41-45 | dropped | ERP `report-backend.md` §Artifact 4 | Skip accepted: conditional nit (only if the 0413 layout shows the filter) | none |
| 7 | AccFlex_Cloud_Database/…/PR_UnpaidAdvancePaymentsReport.sql:6 (+4 TVFs) | dropped | DB `report-database-functions.md` | Skip accepted: no runtime effect; sibling TVF is the same | none |

No new rows. The fixes did not introduce a `block`. Nothing outside rows 1–2 changed in the three `.ts` files: imports `OnDestroy`, `SubSink` and `DetailExpandEventArgs` are added, and all of them are used.

Still unverified from round 1 (not blocking): A2 parity numbers (`parity-125294.sql` not run, DB credentials blocked) and the A3 in-app print/export.
