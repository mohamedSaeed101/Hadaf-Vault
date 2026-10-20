---
type: handoff
cr: 94062
updated: 2026-10-08
status: implemented, reviewed (pass), pushed; desktop check + ship approval pending
---

# HANDOFF — CR-94062: Logistics customers in letters of guarantee

> [!important] Resume on another PC: read this section first
> **The commits are on `origin/cr94062` only once the "Pushed" line below says so.** Until then they live only in this PC's worktree set `D:\Hadaf_Work\worktrees\cr94062`.
> - **Push only:** pushing `cr94062` without moving Merge Desk to Solved opens no PRs. Merge Desk opens PRs only on the Solved move.
> - **Vault:** this vault (`Hadaf Vault`) must be synced to the other PC (Obsidian Sync, OneDrive, or a copy). It is git-ignored in the workspace repo.

**Pushed:** yes, all 4 repos, 2026-10-08. `origin/cr94062` = DB `cda8b811b`, Cloud_ERP `0db81200e5`, Front `718390d9d0`, ERP `57968fb116`. Merge Desk is still at Acknowledge, so no PRs are open. **What's left: [[Remaining]]**

## Where we are (2026-10-07)

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk ticket | done: ticket **#94062**, Beta, Acknowledge, owner Mohamed Saeed |
| 1 Intake | done: [[CR-94062 - Source]] |
| 1b Size | **L** |
| 3 Grill | done: [[CR-94062 - Grilling Decisions]]. Q1–Q5 answered with the recommended options |
| 4–6 Plan + plan gate | done: [[CR-94062 - Plan]], approved by the engineer 2026-10-07 |
| 7 Implement P1–P7 | **done**, all committed (below) |
| 8 Review round 1 | **done**: [[review-1]] (18 rows; all applied or decided, see [[decisions]]) |
| 8 Review round 2 (re-check the rows) | **pass**: [[review-2]] (15 verified, row 7 disagreement accepted on condition that P8 checks the colliding-id search and the payee list of an unlicensed tenant) |
| P8 Tests + end-to-end on tenant | **web done** ([[p8-results]]); desktop check pending. Was: in progress: a full dacpac publish to Sabreen would drop 16 columns from other teams' work, so the engineer chose a targeted script (2 objects + permission 500). Script: `cr94062-sabreen.sql` in this folder |
| 9 Clean (remove-redundant + full gates) | **done**: 1 item applied (`57968fb116`); all gates green |
| 10 Ship (ONE approval: Merge Desk Solved) | **waiting for the engineer**; code already pushed |

Open question, not blocking: **Q6** in [[open-questions]] (which products count as "has Logistics" on web).

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/94062. Change Request, state In Development, assigned Mohamed Saeed.
- Branch `cr94062` → first PR to `Stage_Beta`, second PR to `Master_Stable`. **Never merge `Stage_Beta` into `cr94062`.**
- Merge Desk #94062 (https://support-system.accflex.com/tickets):
  - Version Beta, owner Mohamed Saeed, status Acknowledge, contract change **off**.
  - Repositories: API, Database, Desktop, WebContainer.
  - Deploy components: Database; AnalyticsReader, Cash Control, Logistics; Web Container.
- Permission: **500** "Logistics Customers / عملاء خدمات لوجستية" on module 419. It was 494, renumbered because 494 collides on Stage_Beta (see [[decisions]]). **Re-check that 500 is still free on all `origin/*` branches right before pushing.**

## Commits on `cr94062`

| Repo | Commits (oldest → newest) |
|---|---|
| AccFlex_Cloud_Database | `e5d6512ef` P1 · `cda8b811b` review 1 (permission 500) |
| AccFlex_Cloud_ERP | `efa41d0e46` P2 · `cfe086d423` P3 · `1799f0cb05` P4 · `0db81200e5` review 1 |
| AccFlex_Cloud_Front | `4ea2e9b47e` P5 · `718390d9d0` review 1 |
| AccFlex_ERP (desktop) | `bff7febcb8` P6 · `a1fe5a5b0c` P7 · `cf7e1b9e43` review 1 |

All 4 working trees are clean. No API contract change, so no NSwag client regeneration is needed.

### What changed, by area

- **Database:**
  - Permission 500 (end of `0003_Acc_ModulePermission.sql`).
  - `Lgx_Customer` (app 12) added to the Customers CTE in `Saf_Rpt_BankGuaranteeReport` and `Vw_Saf_BankGuaranteePrint`.
  - No schema change: `Vw_TreasuryCustomers` already exposes Logistics customers (active, with a sales org).
- **Cash Control API:**
  - Payee type `LogisticsCustomers` (12, "عملاء اللوجستيك", permission 500), licence-gated by `BankGuaranteePayeeType.IsLicensed` (products Logistics / LogisticsWeb / LogisticsSubs, Q6).
  - Logistics customers in `GetCustomerOrAccount` (licence-gated, `AsNoTracking`).
  - Licence guard on Create/Update.
  - Fixes: Search name lookup keyed on (ApplicationId, CustomerId); `GetHashCode` replaced by `ApplicationId`.
  - Tests: `BankGuaranteeLogisticsCustomersTest`, `BankGuaranteeLogisticsLicenceGuardTest`.
- **Logistics API:** `DeleteCustomerCommand` refuses a customer linked to a bank guarantee (`ISalesContext.IsCustomerUsedInBankGuarantee`, parameterised SQL on `Saf_BankGuarantee`). Test `DeleteCustomerCommandHandlerTests`.
- **AnalyticsReader:** `BankGuaranteeAng` header:
  - Type names joined in the localised language.
  - "All" only when every usable type is selected.
  - Customer names taken from the TVF rows.
- **Front (cash-control):**
  - Report: type 12 loads Logistics customers, the customer is required, and Construction + Logistics together is refused.
  - Form: the customer is cleared on type change (guarded by `isLoadingGuarantee` while an LG loads); the new key `BANKGUARANTEE._SelectCustomer_` "اختار العميل".
- **Desktop (CashManagement/AccountingSafe/BankGuarantee):**
  - Screen: radio item 12, hidden unless `Program.HasLogistics` and permission 500. Customers come from the CashControl API, filtered by bank branch. A Code column shows for type 12.
  - Liquidation: the account is looked up by the LG's CustomerId when not in the list; the dialog never opens with a null account.
  - Report: type 12 included, customers from `GetCustomerByApplicationTypeForReportAsync`, `Lgx_Customer` added to `dsBankGurantee`.
  - `frmCustomerSearch_New` (shared) now also matches on code; mention this in the PR.

## How to continue (on any PC)

1. **Get the code:** after the push, on the other PC open the workspace and say **"resume 94062"** (`where-are-we`, then `onboard-ticket`). Or create the set by hand: `scripts\new-cr.ps1 -Kind CR -Id 94062 -Repos db,erp,front,desktop` (it tracks `origin/cr94062`). Then:
   - Desktop: junction `References\` from the main checkout (it is git-ignored, about 9 GB). Build serially, never `/m`.
   - Front: `npm install` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1` in `AccFlex_Cloud_Front\accflex-erp`.
2. **Review round 2:** if `review-2.md` is missing or not `pass`, re-run the re-check on `review-1.md`'s rows only (reviewer = Opus 5.5 unless Fable has credits again). A block left after round 2 goes to [[open-questions]] for the engineer.
3. **P8:** end-to-end on test tenant **`Sabreen` on `support-db2`** (`web-test` is retired). Steps:
   1. `scripts\publish-db.ps1 -Database Sabreen -Source Local -RepoPath <set>\AccFlex_Cloud_Database` (preview with `-Script` first).
   2. Run CashControl, Logistics and AnalyticsReader locally against Sabreen (`local-api-run`, ports = launchSettings + **offset 100** from `worktree.json`).
   3. Point the front at them and sign in with `scripts\app-login.ps1`.
   4. Check every item in the Plan's Acceptance list (1–8), including the delete guard and the liquidation journal hitting `Lgx_Customer.InvoiceAccountId`.
4. **Desktop manual check** (by the engineer):
   - Open the LG screen on a Logistics-licensed company: the "عملاء اللوجستيك" option shows only with permission 500.
   - Customers show code + name; search finds a customer by code.
   - Liquidate a type-12 LG: the account is the customer's receivable account.
   - The LG report and single print show the Logistics customer name.
5. **Clean:** `remove-redundant` on the changed lines, then the full gates (below).
6. **Ship:** ONE approval, then:
   1. Push all 4 repos.
   2. Move Merge Desk #94062 to **Solved**: Merge Desk opens the Stage_Beta and Master_Stable PRs.
   3. ADO 94062 → Solved after the stage PR merges.
   4. Afterwards, `remove-cr.ps1 -Id 94062` once Merge Desk shows Closed.

## Build and test gates (what passes today)

| Repo | Command | Result on 2026-10-07 |
|---|---|---|
| Database | `MSYS_NO_PATHCONV=1 "C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/MSBuild.exe" AccFlex_Cloud_Database_State/AccFlex_Cloud_Database_State/AccFlex_Cloud_Database_State.sqlproj -p:VisualStudioVersion=17.0 -v:quiet -nologo -clp:ErrorsOnly` | exit 0 |
| Cloud_ERP | `dotnet build CashControl.sln -c Release`, `Logistics.sln -c Release`, `AnalyticsReader.sln -c Release -p:LibraryRestore=false` | 0 errors |
| Cloud_ERP tests | CashControl.Logic.Test: 34 failures (pre-existing PayableNote), all BankGuarantee tests pass. Logistics.Application.Test: 65 failures (pre-existing SQL/quota) | same as baseline |
| Front | `npm run testing` in `accflex-erp`, run alone: two at once run out of memory (`NODE_OPTIONS=--max-old-space-size=12288` helps) | 0 errors |
| Desktop | serial `MSBuild.exe` (VS 18) `CashManagement\CashManagement.sln -p:Configuration=Debug -v:m` | 0 errors |

**Gotchas**
- The desktop build rewrites the tracked `References\DocumenAttachment.*.dll` and `NetAccounting.BLL.xml`; `git checkout --` them, never commit them.
- The AnalyticsReader build empties 5 tracked `wwwroot` bundles; `git checkout --` them.
- In Git Bash, MSBuild needs `MSYS_NO_PATHCONV=1` and dash switches.

## Files in this folder

[[CR-94062 - Source]] · [[CR-94062 - Grilling Decisions]] · [[CR-94062 - Plan]] · [[review-1]] · `review-2` (when written) · [[decisions]] · [[open-questions]]

## Implementation log

- 2026-10-07: plan approved by the engineer. Q1–Q4 settled on the recommended answers.
- 2026-10-07: worktree set `D:\Hadaf_Work\worktrees\cr94062` created.
  - Port offset 100.
  - All 4 repos track `origin/cr94062` at base `Master_Stable`.
  - Desktop `References` junctioned from the main checkout.
  - Front `npm install` done.
- **P1** `e5d6512ef` (DB): permission (then 494) and `Lgx_Customer` (app 12) added to the report and print CTEs. MSBuild exits 0.
- **P6** `bff7febcb8` (desktop): radio item 12 with licence and permission check, customers from the API filtered by bank branch, search via `frmCustomerSearch_New`, liquidation account from `CustomerForListDto`. 0 errors.
- **P2** `efa41d0e46` (Cash Control): type 12, licence check `IsLicensed`, Logistics customers in `CustomerOrAccount`, search keyed on (ApplicationId, CustomerId), `GetHashCode` fix. 7 tests pass; the 34 PayableNote failures are pre-existing.
- **P7** `a1fe5a5b0c` (desktop report): type 12 and `Lgx_Customer` in both `dsBankGurantee` CTEs. 0 errors.
- **P3** `cfe086d423` (Logistics): delete guard and ar/en error. 1 test; the 65 failures are pre-existing.
- **P4** `1799f0cb05` (AnalyticsReader): Logistics in the report header.
- **P5** `4ea2e9b47e` (front): report and form support for type 12. Build: 0 errors.
- Review round 1 ([[review-1]]), Opus 5.5 standing in for Fable by the engineer's choice: 1 block (permission 494 collision), 9 should, 8 nit.
- Review fixes: DB `cda8b811b`, Cloud_ERP `0db81200e5`, desktop `cf7e1b9e43`, front `718390d9d0`. All gates green.
- Review round 2 (re-check) started.
- 2026-10-07: pushed `cr94062` in all 4 repos (fast-forward, the engineer's yes) so work can continue on another PC. No Merge Desk move.
- 2026-10-07: review round 2 **pass** ([[review-2]]). Follow-ups for the PR text:
  - Mention the shared `frmCustomerSearch_New` change.
  - Mention that Logistics reads CashControl's `Saf_BankGuarantee`.
  - Re-check the highest permission id before the Solved move.
  - Optional: double-clicking Cash during the await could open the dialog twice.
- 2026-10-07: P8 database step:
  - The `publish-db -Script` preview on Sabreen showed 16 data-loss drops: Sabreen holds other branches' unreleased columns.
  - The engineer chose a targeted script instead.
  - Sabreen's `Saf_Rpt_BankGuaranteeReport` and `Vw_Saf_BankGuaranteePrint` were identical to `Master_Stable`, and row 500 was absent.
  - The script (`cr94062-sabreen.sql`) uses CREATE OR ALTER for those 2 objects and inserts permission 500 only if missing.
- 2026-10-07: `cr94062-sabreen.sql` applied to support-db2 / Sabreen with the engineer's yes. Exit 0. Verified: permission 500 (module 419) exists, and both objects contain `Lgx_Customer`. Next: local APIs (CashControl, Logistics, AnalyticsReader, offset 100), then the front and the browser check.
- 2026-10-07: P8 local run on this PC, all against Sabreen via `ConnectionStrings__DebugTenantConnection` (environment variable only):
  - Cash Control API on https://localhost:5109
  - Logistics API on https://localhost:5114
  - AnalyticsReader API on https://localhost:5155
  - Launcher: `scratchpad\run-api.ps1`, Debug build, Development environment.
  - `Authority` env var = `https://accesscontrol.localbeta.hadaf.website/`. The CashControl and AnalyticsReader Development settings point at `testaccflexcloud`, which gives 401s against the front's `localbeta` login.
  - Front on http://localhost:4300 (`.claude/launch.json` entry `cr94062-front`). The local `config.json` points cashcontrol, logistics and analyticsreader at those ports. **Never stage `config.json`**; `git restore` it when done.
- 2026-10-07: Cash Control `appsettings.Development.json` Authority changed locally to `https://accesscontrol.localbeta.hadaf.website/`, at the engineer's request. **Not committed**: `git restore` it with `config.json` when P8 is done. Cash Control restarted on 5109.
- 2026-10-07: front `config.json` (local only): every remote `apiUrls` entry switched from `localstable` to `localbeta` (GL, Payroll, Misc, Concrete, iShop, Construction, Dashboard, PropertyManager). Cash Control, Logistics and AnalyticsReader stay on localhost 5109/5114/5155. Restore with `git restore` after P8.
- 2026-10-07: P8 started on localhost:4200. Acceptance 1 and 2 pass at API level ([[p8-results]]).
- 2026-10-07: P8 progress: Acceptance 1, 2, 3, 4, 7, search and R7 pass. Increase passes. Report and print pending; decrease, extend and close not run. Two pre-existing findings (edit PUT `ExpenseTaxPercent` null; liquidation pays the original amount): see [[p8-results]].
- 2026-10-07: P8: report data verified via local AnalyticsReader (both test LGs, correct Logistics names). The report grid UI doesn't fire locally for any type, Accounts included (environment). Print, decrease, extend and close not run; re-check on Stage Beta. Desktop manual check is still with the engineer.
- 2026-10-07: P8 finished on this PC. Local APIs and front stopped; the front `config.json` and the Cash Control `appsettings.Development.json` were restored (all 4 trees clean). remove-redundant scan started. The engineer is doing the desktop check.
- 2026-10-08: remove-redundant:
  - The scan found 6 code candidates and 0 comment candidates.
  - The engineer approved 1: desktop `frmBankGuarantee` / `frmBankGuaranteeReport` now use `Program.HasExtraPermission` (the cached login permissions, as the other cash forms do). Commit `57968fb116`; serial build 0 errors.
  - The rest were left on purpose: the AnalyticsReader product-list duplicate (no project reference to CashControl.Logic), the test constant 12, a local variable used once, and the two similar desktop loaders.
- **Gates (step 9):** all green on the current heads:
  - DB `cda8b811b`: MSBuild exit 0.
  - Cloud_ERP `0db81200e5`: 3 solutions build; tests at baseline.
  - Front `718390d9d0`: `npm run testing` 0 errors.
  - ERP `57968fb116`: serial build 0 errors.
  - No local config is staged anywhere.
- **Not pushed yet:** ERP `57968fb116` (the cleanup commit). The other 3 repos are pushed.
- **Next:** the engineer's desktop check, then ONE approval: push ERP, re-check permission id 500 is free, then Merge Desk #94062 → Solved (opens the Stage_Beta and Master_Stable PRs).
- 2026-10-13: pushed Front `d9329f0684` and ERP `ecc8e616bb`:
  - Logistics customers are now loaded by the bank's sales organizations and branches, on web and desktop. This replaces Q1 "all active customers".
  - Web keeps the customer when a saved guarantee loads (`distinctUntilChanged` on ApplicationId).
  - Desktop opens web-created guarantees whose BenfitAmount / ExpenseAmount are null.
  - Desktop shows the Logistics type by permission 500 only (the HasLogistics check was removed, the engineer's choice).
- 2026-10-12: on a second PC, the main checkouts in `D:\Hadaf\` were switched to `cr94062` (no worktree set). Local clients published: `logistics.api.client@1.0.3898-local.1` and `cashcontrol.api.client@1.0.1018-local.1` (dev tag), pinned in the front `package.json`, uncommitted. Web test on **BETA-Alradaddi**: Acceptance 1, 2 and 3 pass; 4, 5 and 7 need a saved guarantee. See [[p8-beta-alradaddi]].
- 2026-10-08: pushed the remaining ERP commit `57968fb116` (the engineer's "push all"). All 4 repos match `origin/cr94062`. Computer use is not available in this session, so the desktop check stays with the engineer. The remaining work is listed in [[Remaining]].
