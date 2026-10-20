---
type: open-questions
cr: 125299
updated: 2026-10-14
---

# CR-125299 — Open questions

| # | Question | Needed by | Status |
|---|---|---|---|
| Q1 | UNP-Ali has 0 active `PR_MedicalInsurance` rows. Which tenant has medical-insurance data for the Medical parity check? | P2 parity | **partly answered** (agent, 2026-10-15): ERP_MainDB-Ali has 2 active delivered rows — parity PASS there (no DDL). Open only: undelivered / expired rows exist on no tenant; inserting test rows on UNP-Ali needs the engineer's OK |
| Q2 | The insurance-report route has no `data: { ModuleId }`. Which ModuleId governs Medical Insurance (menu/permission table)? Agent will look it up in the permissions/module tables first | P3 backend | **answered** (agent, 2026-10-14): `Acc_Module` 521 "Medical Insurance Report", HR Reports, ApplicationId 4 (UNP-Ali). Others confirmed there: 767 Employee Save Report, 459 Employee Statistics, 343 Risk analysis-Settlements |
| Q3 | Risk Analysis: legacy `rptRiskAnalysis.BeforePrint` sums salary (Risk, Vacations) and the policy-band salary (Compensation) over **all listed employees'** incomes in the row's currency (no EmployeeId filter), so every row over 90 days shows the same RiskAmount and the figures change with the selection. Keep it (D2 "same numbers", what `PR_RiskAnalysisReport` does now, parity PASS) or fix it to per-employee as a calculation bug? (phase P1c) | engineer / business before P6 | **answered**: Fix, per-employee — engineer 2026-10-15, D6 (`PR_RiskAnalysisReport` updated, parity PASS against the fixed oracle) |
| Q4 | Risk Analysis `Vacations` rounding: after D6, exact .xx5 ties appear; `PR_RiskAnalysisReport` emulates .NET System.Decimal's 26-digit division error (~45 lines, `q` / `vacTie` CROSS APPLYs) so 10 of 34 ties round the way legacy C# would. Keep, or simplify to plain half-to-even on the exact value (0.01 off the "legacy + D6" oracle on those ties; no business-seen figure, since D6 already changed the numbers)? Agent recommends simplify | review-code | **answered**: simplify (review round 1 row 1, reviewer + orchestrator, 2026-10-15), decision D8; emulation removed, the 10 legacy-error ties now differ by 0.01 from the D6 oracle (`parity-results.md`) |
