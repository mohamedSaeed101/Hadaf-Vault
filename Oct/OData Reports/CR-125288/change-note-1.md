---
type: change-note
cr: 125288
iteration: 1
date: 2026-10-21
source: ADO 125288 comment 10010651 (Sabreen Abubakr, PO Check, 2026-10-20)
---

# CR-125288 - change note 1 (PO Check: totals + account lookup)

- **What:**
  1. Period balance grid gets a total row summing Debit, Credit, DebitLocal and CreditLocal. The engineer chose all four columns; the old print totals the local pair only.
  2. «الموازنة التقديرية خلال فترة»: the account lookup is removed from the form. It was required but ignored by the server (D2 quirk), and the old print ignored it too.
- **Where (Front only):**
  - `src/app/shared/components/report-grid/report-grid.component.{ts,html}`: a `totalSummaryOptions` input. The hunk is copied byte-identical from cr125395 `85f9fe329e`, so the two branches merge cleanly in either order. The `SummaryOptions.ts` type already exists on Master_Stable.
  - `period-balance-report-shell.component.{ts,html}`: passes `[totalSummaryOptions]`.
  - `period-estimated-budget-form.component.{ts,html}` and `period-estimated-budget-shell.component.{ts,html}`: drop the account lookup, its required check, and the `accountsIds` plumbing.
  - `estimated-budget-by-month-shell.component.{ts,html}`: this report reuses the same form. Drop its `isShowAccountError` binding and field, and the `accountLookup` collapse, which would throw now that the div is gone. Also drop its no-op `delete obj.accountsIds`. Behaviour is unchanged: this report already hid the lookup. The engineer approved this on 2026-10-21 (Q1).
- **Test:**
  - `npm run testing` exits 0.
  - Grid on a tenant with balances: the DebitLocal total equals the old print's grand total (Sabreen Oct-2025 / branch 1101 = 7,329,380.05 / 0.00).
  - The budget-period grid preview and the previous-design print still work without an account.
- **Risk:** report-grid is shared. The new `*ngIf` on the count group-item is a no-op when `groupSummaryOptions` is set, so existing reports render as before.
- **Rollback:** revert the iteration commit on `cr125288` (Front only).

## Decisions (engineer, 2026-10-21)
- D4: copy cr125395's report-grid `totalSummaryOptions` hunk byte-identical. Do not wait for cr125395, and never merge Stage_Beta.
- D5: total the four money columns.
- D6: remove the account lookup from the budget-period form. Do not make it a filter.
