---
type: test-results
cr: 125299
updated: 2026-10-15
---

# CR-125299 — In-app check (P6)

Setup: AnalyticsReader (set cr125299, Debug, Development) on `https://localhost:7685` with `DebugTenantConnection` → **UNP-Ali on db-all**, Authority localbeta; Front (set) `npm run dev` on 4200, local `config.json` `analyticsreaderapi` → 7685 only (changing `miscapi` to localbeta redirected the app to localstable — reverted). Signed in with `scripts\app-login.ps1 -Company UNP-Ali`. Override proof: `sys.dm_exec_sessions` on UNP-Ali showed a session from DEV5 at the moment of the preview. cr103744's `ng serve` (pid 34636) was stopped on the engineer's OK. Torn down after: processes stopped, env vars removed, `config.json` restored, trees clean.

| Screen | Language | Result |
|---|---|---|
| Employee Save | ar | report-grid, no report iframe; `odata/EmployeeSave` 200; **9 rows** (= parity) |
| Medical Insurance | ar | report-grid, card radios (all / delivered / not); `odata/EmployeesMedicalInsurance` 200; 0 rows (UNP-Ali has no active policy, Q1) |
| Employee Statistics | ar + en | report-grid-multi-request; **88 rows** (= parity); expand → `odata/EmployeeVacationStatistics` 200, 7 types, Σ = master VacationBalance (990.57534); en: LTR, English captions, second-language names, tab "Vacation Balances" |
| Risk Analysis | ar | report-grid grouped by currency; employees 17/30/31 at 2026-10-15: 17 → Risk 13,829.00, Total 418,555.23; 31 → 14,050.00 / 57,924.94 (= D6 parity); group sums Compensation 204,243 · Risk 43,429 · Vacations 293,037.82 · Total 540,709.82 |
| Print Risk Analysis | ar | layout dialog offers the seeded "الافتراضي"; viewer "Document is ready"; RTL, company header, as-of date, currency box, rows, totals → `in-app\cr125299-risk-print-ar.png` |
| Print Employee Statistics | en | seeded "Default"; LTR, From/To from Parameters, nested vacation band per employee, N2, 19 pages → `in-app\cr125299-statistics-print-en.png` |

Not exercised: print of Employee Save and Medical Insurance, Excel/PDF export, Medical with real rows (Q1).

## Findings

| # | Finding | Scope | Action |
|---|---|---|---|
| F1 | Date columns show `7/16/2025, 12:00:00 AM` and VacationBalance shows `٩٩٠٫٥٧٥` (3 decimals, Arabic digits) although the columns carry `dataType: 'date'` → `dd/MM/yyyy` and `Format: '#0.00'` | **Pre-existing shared bug, not this CR**: `report-grid.component.ts:741` sets `customizeText = value.toLocaleString('en-US')` and `report-grid-multi-request.component.ts:544/615` `value.toLocaleString(numberLocale)` on every column, overriding the column format. From commit `faf5b9924e` (2026-07-26, "return number in english"), on Master_Stable, Stage_Beta, Stage_Stable. Affects every report grid | Separate work item; not fixed here (surgical-change rule). Print layouts are unaffected (dd/MM/yyyy, N2) |
| F2 | SignalR notifications hub `accesscontrol.localbeta…/notifications` 404 / handshake errors in the console | Environment, unrelated | none |

## Round 2 additions (2026-10-15, review row 5) — after review-1 fixes (DB bb558984c, ERP 9b19622f57, Front 1b3ea4f3a0)
| Screen | Language | Result |
|---|---|---|
| Print Employee Save | ar | 9 rows; layout dialog offers seeded "الافتراضي"; "Document is ready"; RTL, company header, title, # 1..n, dates dd/MM/yyyy → `in-app\cr125299-save-print-ar.png`. Cosmetic: Description column narrow, long serial numbers wrap 3–4 lines |
| Print Medical Insurance | ar | seeded "الافتراضي" offered; "Document is ready" (0 rows on UNP-Ali, layout renders without binding errors) |
| Excel / PDF export | — | **not exercised**: it downloads a file; left for the engineer / QA |
Torn down again: processes stopped, env vars removed, `config.json` restored, wwwroot restored, all three trees clean.
