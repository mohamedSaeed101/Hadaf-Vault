# CR-125292 — open questions

Q1–Q7 answered 2026-10-14 (see [[decisions]]). Only Q8 is open (settled during P8).

- [x] **Q1: Branch and Merge Desk ticket.** Resolved 2026-10-14: Merge Desk ticket #12459, `cr125292` on origin. No repo has `cr125292` on origin, and the `merge-desk` MCP is not connected in the session that did the analysis.
  - **Recommendation:** cut `cr125292` locally off `Master_Stable` in Cloud_Database, Cloud_ERP and Cloud_Front, as `cr125294` was. The engineer creates the Merge Desk ticket (TFS 125292, version Beta, those 3 repos) before ship.
  - **2026-10-14:** the engineer chose to set up Merge Desk instead. `D:\Hadaf\.env.local` was created (git-ignored) with an empty `MERGEDESK_ADO_PAT=`; the engineer pastes a PAT (organization hadafsolutions, scope User Profile (Read) only) and restarts Claude Code. Then `get_ticket(125292)`, `create_ticket` if missing (Beta; AccFlex_Cloud_Database, AccFlex_Cloud_ERP, AccFlex_Cloud_Front), and build on `origin/cr125292`.
  - Blocked on: engineer (PAT + restart).

- [x] **Q2: Screen type.** Full interactive report grid (filter, sort, group, export on screen) or print-only like Total Salaries?
  - **Recommendation:** full grid. The acceptance criteria and business value ask for it, and `cr125294` did the same. R2 and R3 use `report-grid-multi-request` (employee → income lines), like the advance report in `cr125294`.
  - **Answered 2026-10-14:** recommended option → [[decisions]] D2.

- [x] **Q3: Keep the legacy print.** Keep a "Print (previous design)" button during the transition, as fx124062 did for Total Salaries?
  - **Recommendation:** yes; the ticket's risks section asks for it.
  - **Answered 2026-10-14:** recommended option → [[decisions]] D3.

- [x] **Q4: Legacy defects** (listed in [[CR-125292 - Source]]). Acceptance criterion 2 says same numbers.
  - **Recommendation:** port the SQL exactly. One exception: drop the `VarChar(1024)` id-list cut in R8, a limit of the old pipeline and not a business rule. Report R3 (double bank account), R4 ("Main Salary" = `InsuranceCompany`) and R6/R8 (end-of-work join) to the PO as separate Bugs instead of changing numbers inside a migration.
  - **Answered 2026-10-14:** recommended option → [[decisions]] D4.

- [x] **Q5: Security level.** R1, R2, R3, R5, R7 do not filter by the user's security level; R4, R6, R8 do.
  - **Recommendation:** apply the user's security level in all 8. Admins (level 5) see identical numbers, so parity is unaffected. It closes a salary-visibility leak. It is a behaviour change, so the engineer decides.
  - **Answered 2026-10-14:** recommended option → [[decisions]] D5.

- [x] **Q6: Permissions.** Put the menu's ModuleId on each route and OData endpoint: 514 / 537 / 542 / 543 / 539 / 540 / 538 / 541?
  - **Recommendation:** yes, matching "same permissions" in the ticket. Effect: R1, R5, R7 become reachable for non-admins who hold the permission (today admins only), and R4 checks 543 instead of the inherited 285.
  - **Answered 2026-10-14:** recommended option → [[decisions]] D6.

- [x] **Q7: Parity tenant.** Resolved 2026-10-14: the engineer named **UNP-Ali on db-all**; P4 PASS for all 8 (Implementation Log §7). Which tenant database, reachable with `sqlcmd`, has posted payroll data (ideally with an end-of-work in a month and an employee with two bank accounts) for the legacy-vs-TVF comparison?
  - **2026-10-14:** the engineer named **UnitedPlastic** on server `web-test` (SQL login). The workspace env-pin hook blocks `web-test` as retired and points at `support-db2` (any DB there may be read). `support-db2` is unreachable from this PC (named-pipes / login timeout). Not yet checked whether UnitedPlastic exists on `support-db2`.
  - Blocked on: engineer: confirm `web-test` despite the hook (needs the hook's pin changed by the engineer), or a UnitedPlastic copy on `support-db2` plus network access to it.

- [ ] **Q8 (resolve during P8, not blocking the start):** R2 binds the report and its detail band to the same table. From code alone it is unclear whether the employee list prints once or once per employee. Capture a live MVC print with 2+ employees.
