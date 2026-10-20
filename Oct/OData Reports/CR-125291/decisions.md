# CR-125291 — decisions

**Status: AGREED at the plan gate on 2026-10-17.** The engineer chose D1, D2, D3 and D5 explicitly, each the recommended option. D4, D6 and D7 are agent defaults written into the plan the engineer approved. The defaults follow the house precedent of the sibling CRs 125288 / 125290 / 125292.

| # | Decision (proposed) | Effect |
|---|---|---|
| D1 | **Full interactive report grid** on all 5 screens, as in CR-125288 / 125290 / 125292 D1 (not printOnlyMode as fx123513 did). | One `odata/<Name>` action in `GLODataController` per report, an `IAngularReport`, a seeded ar/en layout. |
| D2 | **Port the numbers exactly, English legacy variant as reference.** Numeric quirks are reproduced and listed for the PO. **Language-only bugs are not copied** (FPS Arabic "التفاصيل" for Depreciation, Brief's duplicate Arabic "رأس المال المستثمر", Brief/FPS/Compare shell title always "Brief"). | Parity = zero divergence from the English legacy SQL + C# math. |
| D3 | **Keep the old print** as "Print (previous design)" on each form (relabelled Print button opens the iframe). | No `-legacy` routes. |
| D4 | **Equity Changing stays a pivot**: the TVF returns long rows (row kind × equity type), the layout uses `XRPivotGrid` as in CR-125290. | Grid shows long rows, user can group. |
| D5 | **No dependency on fx123513.** `Acc_BalanceSheetReport` is not in `Master_Stable`; Compare gets its own `Acc_CompareBalanceSheetReport` built on the same base TVFs (`Acc_GetAccountBalanceBeforeDate` + `Acc_GetAccountJournalActionsBeforeDate`). The `one-date-form` change is done independently; whichever of fx123513 / cr125291 merges second keeps both edits. | Self-contained branch. |
| D6 | **Branch caption computed server-side** (`GetBranchesName`, as fx123513) instead of the legacy blank-on-first-load caption. Deliberate visible improvement, no numeric effect. | `branchesNames` query key dropped. |
| D7 | **Filters exactly as legacy**: Compare has no branch filter; Equity Changing ignores branches (form shows it in the old screen, MVC ignored it → the new screen hides it). Cash Flow honours branches. | Query keys below. |

## Quirks reproduced (to report to the PO)
- **Brief:** components rounded to tenant decimals before totals; Working Capital = |CA| − |CL|; Invested Capital positive vs Capital Invested negative; Equity row includes P/L (type 12); unmapped-to-sub-item accounts are included (classifies by AccountTypeId).
- **Compare:** prior-year lines matched by SubItemName (prior-only items missing from lines, kept in totals); prior cut-off `DATEADD(year,-1,toDate+1)`; all D−C, liabilities/equity negative.
- **Financial Position:** CL is C−D while Equity / LTL / Investment Financing are D−C (print negative); CA/CL/Equity/LTL show Cost 0 and Net = Depreciation; DevExpress regrouping by SubParentItemName (Equity inverted, LTL single header) reproduced via SortOrder.
- **Cash Flow:** each value printed as ABS in parentheses when negative; Allocations not negated; account types 11/13/14/16/17/18 in no row; closing journals (type 4) excluded from flows but not from cash balances (Start + Net ≠ End); two rows share Ordr 4 (fixed order chosen: Current assets then Inventory).
- **Equity Changing:** closing journals included (the C# exclusion list is never used); types 1/4/5/6 and Net profit ABS, types 2/3 signed; no type-12 accounts → whole ledger; alphabetical row/column order differs Ar vs En.

## Open (need a live MVC print, checked in P6)
- Empty categories in Compare / FPS Equity-LTL: do header + 0 rows print?
- Equity Changing row order and possible double count in the type-3 column.

## Rules bent (recorded after review rounds 1–2, 2026-10-18)
- **report-module-scaffold §Date Range Validation:** when from > to, Cash Flow and Equity Changing cancel the preview and show the `COMMON._dateOutOfRangeMessage_` toast. They do not call `setErrors` on fromDate: that error stays after toDate is corrected and blocks the "Print (previous design)" path. Precedent: `bank-balance-reprot.component.ts:120-125`.
- **report-backend §Artifact 2:** the EF configs use `HasNoKey()` with no `ToFunction`, and the OData entities key on `RowNo`. Precedent: `AccountBalanceWithJournalTypesConfigurations.cs`.
- **The branch caption keeps the literal "All" / "الكل":** `Resource.All` is empty in `Resource.en.resx`.
