# CR-125288 change note 2 — Period balance totals like the old print (Muhammed Tariq, ADO comment 10021303, 2026-10-25)

- **What**: Period balance grid totals only DebitLocal / CreditLocal (no cross-currency sum of Debit / Credit), and rows are grouped by AccountNo, expanded, with a per-account DebitLocal / CreditLocal sum, as the old print's AccountNo group footer «الاجمالى» and report footer ([[Legacy - Period Balance]] Layout).
- **Where**: Front only, set `D:\Hadaf\worktrees\cr125288\AccFlex_Cloud_Front` — `period-balance-report-shell.component.ts/html` (`totalSummaryOptions`, `groupSummaryOptions`, `Grouping` on AccountNo; same pattern as contractor-balance-report).
- **Test**: `npm run testing` + prettier; grand total = SUM(DebitLocal), SUM(CreditLocal); each account group shows its own local sums.
- **Risk**: screen only; the print layout already totals local amounts per account. A saved user grid design may override the default grouping.
- **Rollback**: revert the front commit on cr125288.
