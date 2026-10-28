# Review round 3 — CR_125288 (iteration 1, uncommitted Front working tree)   base 9e3d83a755 (origin/Master_Stable)  head 546b0f5165 + working tree   verdict: pass

Scope: `git -C D:\Hadaf\worktrees\cr125288\AccFlex_Cloud_Front diff` (10 files, +34/-75). Governing doc: `change-note-1.md` D4–D6, Q1 answered.

## Verified (not findings)

- change-note-1 item 1 (totals) → `period-balance-report-shell.component.{ts,html}` + shared `report-grid`; item 2 (drop account lookup) → `period-estimated-budget-form`, `period-estimated-budget-shell`, `estimated-budget-by-month-shell` (Q1 approved). No change in the diff falls outside those two items.
- (a) report-grid hunk: the +/- lines of the working-tree diff on `report-grid.component.{ts,html}` are identical to `85f9fe329e` (diffed line-by-line, zero delta). `TotalSummaryOptions` already exists in `SummaryOptions.ts` on `origin/Master_Stable`. The new `*ngIf="groupSummaryOptions"` on the count group-item keeps existing reports unchanged.
- `totalSummaryOptions` in the period-balance shell is a plain class field initialised once (`period-balance-report-shell.component.ts:31-38`), not a getter: `template-bound-getters.md` §What to do satisfied.
- `branchesIds` on the budget-period screen: `BranchCheckListComponent.ngOnInit` (`branch-check-list.component.ts:69-83`) emits `whenBranchChange(all ids)` on load, which `whenBranchChange` in the form patches into `FilterForm.branchesIds`, so the legacy print (`whenSubmit`, `FilterForm.value`) carries all branches exactly as it did before, when `updateBranches` set the same list after the mandatory account pick. The grid reads `BranchLookupRef.BranchForm.value.BranchList` (`period-estimated-budget-shell.component.ts:71`), untouched.
- Legacy MVC action `EstimatedBudgetPeriodcs(..., string accountsIds, ...)` receives no `accountsIds` key now → null; it was never forwarded to the query (`AccountList=null`, Legacy note :74), so the print output is unchanged.
- By-month shell: only the dead `isShowAccountError` binding/field, the `accountLookup` collapse (would throw on a missing element) and the no-op `delete obj.accountsIds` are removed; `accountCheck` hiding and `obj.branchesIds` assignment stay. By-day report uses its own form (`estimated-budget-by-day-form`), untouched.
- No new i18n keys; no RTL-specific markup added (`dxi-total-item` inherits grid direction). `config.json` not in the diff. No secrets, ports or local paths. Orphans removed: `AccountsLookupComponent`, `BranchesDataService`, `AccountLookupRef`, `accountsIds`, `updateBranches`, `getSelectedItemsKeys`, `isUpdateBranshList`, the `errMsg`/`account` locals in the shell.
- EOL warnings ("LF will be replaced by CRLF") are autocrlf normalisation; index is `lf`, so the commit will carry only the shown hunks.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | accflex-erp/projects/general-accounting/src/app/modules/advanced-reports/period-estimated-budget/period-estimated-budget-form/period-estimated-budget-form.component.ts:44 | nit | D:\Hadaf\CLAUDE.md §Coding guidelines 3 (orphans your change made) | `BrancheList$` was only ever assigned by the deleted `updateBranches`; it is now never written, and the child `app-branch-check-list` overwrites its own `BrancheList$` input in `ngOnInit`, so the `[BrancheList$]="BrancheList$"` binding (form html:16) always passes `undefined`. Harmless, but an orphan of this change. | Optional: drop the field, the `BranchNode`/`Observable` imports if unused, and the `[BrancheList$]` binding in the form template. Leave as is if you prefer the smaller diff. **done 2026-10-21** (engineer's call): field, `[BrancheList$]` binding and `BranchNode` import removed; `Observable` kept, since `ChildCostCentertList$` still uses it. |
| 2 | accflex-erp/projects/general-accounting/src/app/modules/advanced-reports/period-balance/period-balance-report-shell/period-balance-report-shell.component.ts:33-36 | nit | change-note-1 D4/D5; report-grid.component.html:252 `valueFormat` default `'#,##0.##'` | The four money columns render via `Format: 'money'` (2 dp), while the total row uses the grid default `#,##0.##`, so a zero total shows `0` and e.g. `1,234.50` shows `1,234.5` next to `1,234.50` cells. Verified value 7,329,380.05 is unaffected. | Optional: add `displayFormat: '#,##0.00'` per column in `totalSummaryOptions` (shell only; keeps the report-grid hunk byte-identical per D4). **done 2026-10-21**: `displayFormat: '#,##0.00'` on all four columns in the shell; report-grid untouched. |
| 3 | accflex-erp/projects/general-accounting/src/app/modules/advanced-reports/period-estimated-budget/period-estimated-budget-form/period-estimated-budget-form.component.ts:48 | nit | AP: catalogue Frontend §Unused variables | `isUpdateChileCostCentertList` and `isUpdateJournalTypeList` are unused, **pre-existing** (not created by this change). | None. Out of scope per Coding guideline 3; mention only. |

AP scan (front sub-agent, 2026-10-21): BLOCK 0, FIX 0, NIT 2. Its first nit duplicates row 1 and was merged there; its second nit is row 3. Surfaces checked: Frontend, Git hygiene. No line-ending churn: `--ignore-space-at-eol` gives the same stat.

## Summary

- verdict: pass. Reviewed by Fable 5.1; the change was written by Opus 5.5. AP scan by Sonnet.
- block: 0, should: 0, nit: 3 (one of them pre-existing)
- round 4 not needed (size S, one round per iteration; no block rows).
