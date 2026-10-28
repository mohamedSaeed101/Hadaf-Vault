---
type: session-summary
cr: 103744
date: 2026-10-07
tags: [cr, cr-103744, session, handoff]
---

# CR-103744 — Session summary (2026-10-07)

> Paste this file into a new session to continue. The other notes in this folder hold the detail: [[CR-103744 - Source]] (ticket), [[CR-103744 - Plan]] (phase table with every commit), [[CR-103744 - Open Questions]] (all decisions), [[CR-103744 - Docs Proposal]] and [[HANDOFF]].

## 1. The work item

- **ADO 103744**, a Change Request in `AccFlex_ERP\3- Customer Issues`, state New, program ESS App, customer internal, work type API+Desktop, environment "Beta", parent 18226.
- **Title:** فى حالة إصدار مكافأة للموظف أو اضافة رصيد اجازات مستحق يتم ارسال للموظف notifications
- **Ask:** send the employee a push notification on the ESS mobile app when:
  1. a **bonus** is added for them;
  2. an **earned leave balance** is added for them;
  3. they are **credited for working an official holiday**.
- Read through the **ADO MCP** because `az boards` stops at an interactive prompt (extension install). Fix: `az extension add --name azure-devops`.

## 2. Final scope, after every decision

| What | Notifies? | Where in code (Cloud_ERP, `Payroll/`) |
|---|---|---|
| Bonus added: bonus screen | yes | `EmployeeBonusController.PostEmployeeBonus`, after the save |
| Bonus added: bonus import | yes | `BonusImportCreateCommand` handler, after the save |
| Bonus added: Logistics driver bonus (Hangfire) | yes | `DriverBonusPayrollEmployeeBonusService.Execute`, after `Commit()`; the job's **ConnectionString** is enough (no TenantId) |
| Bonus edited or deleted | **no** (D4') | — |
| Leave balance added: *Vacation balance transfer* screen + its Excel import | yes (D10) | `AnnualVacationSystemController.TransferVacationBalanceList`, after the save |
| Holiday work: leave-days credit | yes | `CalculateAttendanceSheetForListCommand`, `UpdateAttendanceSheetForListCommand` |
| Holiday work: **cash** allowance | yes (D2'), one per currency | same handlers |
| Holiday work, recalculated with no change | **no** (before/after comparison, D13) | `HolidayWorkNotificationItemsBuilder.SnapshotCredits` / `ExcludeUnchanged` |
| Desktop direct-SQL writes | **no** (D6, desktop out of scope) | — |
| Deep link from the push to a screen | **no**, follow-up CR (D1) | needs Identity + the Flutter app |
| UI for the 3 switches | **no** (D12) | the API supports them; on by default |

- **Recipients:** only employees with an app account (`Employee.UserGuidNumber` not empty). Only the employee; never their manager or substitute.
- **Language:** the sender's request culture (D7).
- **Company switches** on `PR_SystemConfiguration`, default **on** (D8): `NotifyEmployeeOnBonus`, `NotifyEmployeeOnLeaveBalance`, `NotifyEmployeeOnHolidayWork`.

## 3. Decisions (full table in Open Questions)

| D | Decision |
|---|---|
| D1 | Deep link → follow-up CR (Identity `IFireBaseInterface`/`ToPushNotification` plus the mobile app) |
| D2' | Holiday work with the **cash** policy also notifies (the user confirmed twice) |
| D3 | Logistics driver bonuses notify |
| D4' | **Add only**: no notification on edit or delete (replaced D4, "edit and delete") |
| D5 / D10 | Leave balance notifies from the `vacation-balance-transfer` screen (`POST api/AnnualVacationSystem/TransferVacationBalance`, including its import). The web has no other manual-add path; Cloud has no automatic year-end carry-forward |
| D6 | Desktop (AccFlex_ERP) out of scope; no change |
| D7 | Text in the sender's culture |
| D8 | All switches default on |
| D9 | Base `Master_Stable` |
| D11' | **No TenantId** on the driver-bonus job: the ConnectionString is enough (reverted D11) |
| D12 | No UI for the switches in this CR |
| D13 | **No `PR_EmployeeNotificationLog` table.** Repeat sends are prevented by comparing holiday credits before and after recalculation |

## 4. Architecture as shipped

- **Sending path (existing, unchanged).** `IAccFlexNotificationPublisher.PublishAsync` writes `ACFX_Notifications`, then AccessControl's Hangfire queue → `NotificationDistributer` → `PushNotificationNotifier` (FCM, `ACFX_UserMobileDevice`) and SignalR. That also gives a bell entry (`GET api/UserNotification/GetNotifications`).
- **New `Payroll.Service/EmployeeEventNotifications/`:**
  - `IEmployeeEventNotificationService` with `NotifyBonusAddedAsync(ids)`, `NotifyLeaveBalanceAddedAsync(ids)` and `NotifyHolidayWorkAsync(items)`. It checks the company switch, batch-loads data (by-id reads use `IgnoreQueryFilters()` so the EmployeeSecurityLevel filter can't hide employees in Hangfire), skips an empty GUID and publishes one push per event. It **saves nothing and never throws**; each publish has its own try/catch with logging.
  - `IEmployeeEventNotificationStore` / `EmployeeEventNotificationStore` hold the EF queries; this seam makes the service unit-testable.
  - `HolidayWorkNotificationItemsBuilder` (pure) has `Build`, `SnapshotCredits` and `ExcludeUnchanged`, and the `HolidayWorkCreditKey(EmployeeId, Day, IsCash, CurrencyId)` record. Values are compared rounded to 2 decimals.
  - Registered scoped in `Payroll.API/Startup.cs`.
- **Messages:** `Payroll.Logic/NotificationInfo/NotificationMessages.cs` + `Resource.resx`/`Resource.en.resx`/`Resource.Designer.cs` have 4 title/body pairs: BonusAdded, LeaveBalanceAdded, HolidayWorkLeaveCredit, HolidayWorkCashAllowance. The enum `EmployeeNotificationType` is in `Payroll.Logic/NotificationInfo/`.
- **Settings API (additive):** `UpdateCompanySettingsDto` gets 3 `bool?` (null keeps the current value); `CompanySettingsDetailsDto` gets 3 `bool`. Endpoints: `GET/PUT api/SystemConfiguration/CompanySettings`. `SystemConfiguration.UpdateCompanySettings` has 3 trailing bool parameters.
- **Before/after snapshot:**
  - Calculate handler: in memory from the already-included accrued list and the policy calculations.
  - Update handler: **one** batched `EmployeeAccruedvacation.AsNoTracking()` query, because that list isn't included there.
- **`TransferVacationBalanceList`** now returns `Result<List<EmployeeAccruedVacation>>`. The HTTP contract is unchanged.

## 5. Repos, branches, commits (nothing on Master_Stable yet)

- **Worktree set:** `D:\Hadaf_Work\worktrees\cr103744\` (db, erp, front; the front is untouched). Branch `cr103744`, cut from `origin/Master_Stable`.

| Repo | `cr103744` commits (in order) |
|---|---|
| AccFlex_Cloud_Database | `641261959` switches + log table · `fe14b2bd0` drop the FK · `418af662a` **remove the log table** → net change vs Master_Stable: only `PR_SystemConfiguration.sql` (+3 columns) |
| AccFlex_Cloud_ERP | `73987356d4` domain · `fcdeb2e80b` service · `9b9beeeab8` bonus hooks · `2fc8a0388e` leave hook · `4fca243db1` holiday hooks · `285eba95da` settings API · `0d7a93961b` review fixes · `297d18748d` TenantId · `498be286c2` **revert TenantId** · `7cc5afea16` **remove the log, before/after dedupe** |

- **Stage Beta branch:** `cr103744_Stage_Beta` = `origin/Stage_Beta` + merges of `cr103744`. Worktrees in `D:\Hadaf_Work\worktrees\cr103744_Stage_Beta\`. DB tip `566ca03be`, ERP tip `da4232c761`. (Rule: Stage_Beta is never merged into cr103744.)
- **All pushed:** `origin/cr103744` and `origin/cr103744_Stage_Beta`, in both repos.

## 6. Pipelines and PRs

- **Client SDK 221 (Payroll)**, run **183072** on `cr103744` @ `297d18748d`: **succeeded**. It was built before the log removal; the settings contract it exposes hasn't changed since, so no re-run is needed.
- **PRs into Stage_Beta** (linked to WI 103744; the merge preview shows no conflicts; waiting on the required reviewer groups):
  - DB **!66595** https://hadafsolutions.visualstudio.com/AccFlex_ERP/_git/AccFlex_Cloud_Database/pullrequest/66595
  - ERP **!66596** https://hadafsolutions.visualstudio.com/AccFlex_ERP/_git/AccFlex_Cloud_ERP/pullrequest/66596
- **No deploy has run.** Stage Beta order: **341** (DB dacpac), then **337** (Payroll API). Logistics (335) is no longer needed for this CR.

## 7. Verification done

- DB: VS 2022 **Community** MSBuild on the sqlproj, exit 0 (both branches).
- ERP on `cr103744`: `Payroll.sln` Release, 0 errors. `Logistics.sln`, 0 errors (before the revert brought Logistics back to Master_Stable).
- Tests:
  - `Payroll.Application.Test`: 33/33 on the notification filter.
  - Full `Payroll.Logic.Test`: 128/130. The 2 failures (`UpdateValidVacation`, `CreateBeneficiaryWithNotValidDateOfBirth`) **also fail on a clean Master_Stable**.
- On `cr103744_Stage_Beta`: DB builds; `Payroll.API` builds.
- **Not verified:** a real push on a device; Stage Beta behaviour; the bonus-import hook has no unit test (concrete GL context, no async EF mock helper).

## 8. Review findings and what happened to them

- **SQL review:** BLOCK, the FK on the log table broke employee hard-delete. Fixed (`fe14b2bd0`); now moot, because the table is gone.
- **Backend review (all fixed in `0d7a93961b`, part later superseded by D13):**
  - cash key collision across currencies;
  - N+1 queries and a save per row;
  - the GL context left on a committed transaction in the driver job;
  - the security filter hiding employees in Hangfire.

## 9. Problems found, not fixed (outside this CR)

- **Stage_Beta itself is broken:**
  - `Logistics.Application/Shared/MenuList/WebMenuGroup.cs:79` uses the missing `WebMenuItem.UserTransactionAuditReport` (last change PR 66586, fx121674).
  - `Payroll.Application.IntegrationTest` doesn't compile (`ExecuteInScopeAsync`, `_scopeFactory`).
- `EmployeeBonus.UpdateEmployeeBonus` is missing a `return` before `Result.Success(this)`.
- `UpdateAttendanceSheetForListCommand` loads `AttendanceEmployee` without `.Include(EmployeeAccruedVacationList)`, so recalculation through update can leave a duplicate holiday accrued row.
- FCM sender sets Android options only (no APNs); the push carries title and body only (no data, so no deep link).
- Workspace: `core.hooksPath` not set (run `scripts\install-hooks.ps1`); `az` devops extension prompt.

## 10. Side actions in the main checkouts

- `D:\Hadaf_Work\AccFlex_Cloud_Database` was switched from `Stage_Beta` to **`Master_Stable`** (fast-forwarded) at the user's request.
- `D:\Hadaf_Work\AccFlex_Cloud_ERP` is on `Stage_Beta` with pre-existing dirty AnalyticsReader bundle files. Not ours; left alone.

## 11. What remains

1. The two PRs into Stage_Beta: approval and merge (the reviewer groups).
2. **With the user's OK:** run Stage Beta pipelines **341**, then **337**.
3. Prove it shipped:
   - `SELECT` the 3 columns on the tenant;
   - `GET api/SystemConfiguration/CompanySettings` returns the switches;
   - trigger a bonus, a balance transfer, and a holiday-work sheet (days and cash); recalculate to confirm no resend;
   - check the bell / push.
4. Evidence on WI 103744 (`Custom.ClosingEvidence`, comment with PR and pipeline links, Arabic retest note); the item stays Active.
5. After the tester approves: PRs **cr103744 → Master_Stable** (DB + ERP); the final merge is held until then.
6. Clean-up: apply [[CR-103744 - Docs Proposal]] to `accflex-docs` (it already matches what shipped); remove both worktree sets; close HANDOFF.
7. Follow-up CRs to propose: the deep link (Identity + mobile); a web UI for the switches if customers ask; desktop parity if wanted.

## 12. How to resume in a new session

```
Read D:\Hadaf_Work\Hadaf Vault\V82-R10-2026\CR-103744\CR-103744 - Session Summary 2026-10-07.md and HANDOFF.md,
then run scripts\cr-status.ps1 and continue CR 103744 from "What remains".
```
