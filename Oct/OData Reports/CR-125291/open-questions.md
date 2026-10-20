# CR-125291 — open questions

## Q1 — Which tenant may P6 publish to? — ANSWERED 2026-10-17: ELGHONEIM_Primary (db-all), company ELGHONEIM
P6 (app check: local AnalyticsReader on offset 600 + front, ar/en print, XLS/PDF, side by side with the old print) needs the 5 TVFs and seed 0437 on a tenant DB. Nothing has been published yet.
- **A (recommended):** publish branch `cr125291` to one dev tenant with data via `scripts\publish-db.ps1` (e.g. one of the parity tenants, if it is a dev copy), then run P6.
- B: skip P6 here; check on Stage Beta after ship.

## Q2 — Print decimals: fixed N2 or tenant ApproximateNo? — DONE 2026-10-17: option A (approximateNo parameter from DataContext.GetGeneralLedgerApproximatePriceTo(); TextFormatString expression bindings; pivot via BeforePrint script as in seed 0188; null → 0 decimals, same as legacy)
The legacy prints used the tenant ApproximateNo (e.g. 3 on dbselena_Primary). The new layouts use fixed N2, as CR-125290 did; the backend passes no decimals parameter. Numbers are equal (P5); only the displayed rounding differs on tenants where ApproximateNo ≠ 2.
- **A (recommended):** pass `approximateNo` as a report parameter from the 5 `*Ang.cs` and bind the format to it. This is a small change in P2 + P4.
- B: keep N2 (sibling precedent).

## Visible text choices (no numeric effect) for the PO
- Brief row 9 Arabic caption is now "تمويل رأس المال المستثمر" (legacy duplicated row 6's caption).
- Cash Flow English captions have their typos fixed.
- Equity Changing rows are ordered Opening → Change → Net profit in both languages (legacy order was alphabetical and differed between Arabic and English).
- Equity Changing's total column reads "Grand Total" in Arabic too (DevExpress limitation, same as CR-125290).
