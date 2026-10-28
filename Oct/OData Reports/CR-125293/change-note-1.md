# CR-125293 change note 1 — Pay Check totals (Sabreen, ADO comment 2026-10-20)

- **What**: Pay Check screen grid gets a grand total of net salary (EmployeeSalary) and a subtotal per group when the user groups by branch / bank / any column; «مصروف» column shows مصروف / غير مصروف instead of a raw checkbox.
- **Where**: Front only, set `D:\Hadaf\worktrees\cr125293\AccFlex_Cloud_Front` — `report-grid` (opt-in `totalSummaryOptions` input + opt-in `ColumnIndex.Lookup`), `pay-check-shell.component.ts/html`. No DB / API change: the print layout 0424 already has group footers, grand total and a serial column.
- **Test**: `npm run testing` gate + prettier; browser on Sabreen month 07/2026: total row = SUM(EmployeeSalary) from the TVF; group by BranchName / BankName shows group sums; «مصروف» column text in ar and en, filter row on it still works.
- **Risk**: report-grid is shared; both additions are opt-in inputs, null by default, so other reports render unchanged.
- **Rollback**: revert the front commit on cr125293.

Point 3 of the comment (PRs !67218/!67220/!67267 carry foreign files): no code change. cr125293 vs Master_Stable touches only CR files; the extra files in the Stage_Beta PRs are other tickets' Master_Stable commits not yet on Stage_Beta (e.g. CR_124989 physical inventory), and !67267 was the Stage_Beta build fix (enum comma) from branch fxConflict. All three PRs are already merged. Old print's serial column: not asked under «المطلوب»; the new print layout already has it (sumRecordNumber).
