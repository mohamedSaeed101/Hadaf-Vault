# CR 126303 – test results

## Automated (2026-10-28)
- PropertyManager.Application.Test full run: **1117 / 1117** passed (after phase 7); waiver handler tests 14/14 again after the 968 → 969 module change.
- Front `npm run testing` exit 0 (phase 7).

## Phase 8 E2E — Sabreen_Primary on db-all (2026-10-28, engineer OK "Yes, use Sabreen")

**Schema on Sabreen:** NOT a full dacpac publish — the preview showed 43 data-loss drops of other branches' columns (Payroll PR_Job, Logistics reorder, audit retention …). Applied a guarded, re-runnable cut-down script instead (this CR's objects only): 4 nullable columns + FK on Pm_ContractActionDocument, Pm_RealEstateSettings.WaiverFeePercent DF 1, doc type 2 «تنازل», Pm_PropertyLogEventType 15 «تنازل», Acc_Module 969. Sabreen already had CR 126223's tables/columns/status 3.

**Module id moved 968 → 969:** Sabreen's Acc_Module has 968 «Property Manager Contracts Status Report» (on no remote branch) and 970. 969 free on all 738 ERP and all DB remote branches and on Sabreen. Commits: DB 22f4d63fa, ERP cbbd7f5409, Front 2f8db0d9e3.

**Run:** PM API from the set (Debug) on https://localhost:52138, `DebugTenantConnection` → Sabreen_Primary, `Authority` → accesscontrol.localbeta (front authority); Hangfire storage (`PropertyManagerConnection`, missing locally) on a throwaway LocalDB `Hangfire_cr126303` so nothing was created in Sabreen. Front `npm run dev` on 4200 with a local config.json (propertymanagerapi → localhost:52138, miscapi/dashboard → localbeta). Signed in as the .env.local test user, company Sabreen.

**Override proof:** API log 200s for GET ContractWaiver/GetAll + MenuList; `sys.dm_exec_sessions` on Sabreen_Primary showed SqlClient sessions from host DEV5 at the request time.

| Check | Result | Evidence |
|---|---|---|
| R7 popup: date today, warning, «تنفيذ وترحيل» disabled without contract | pass | `e2e\1-popup-empty-execute-disabled.png` |
| R1 eligible list = Active/Delivered (SC-2026-0005/6/7) | pass | list before; after the waiver 0005 is gone |
| A2 default fee 1% × net: 0005 net 33,066 → 330.66; 0006 net 715,500 → 7,155.00 | pass | `e2e\2-…`, `e2e\4-…` (0006 not executed) |
| R2/R3 summary: paid 0.00, remaining 34,950.80 = DB sum(Amount+Tax) of 14 Active non-RETT lines, refund −330.66 | pass | `e2e\2-…` + SQL |
| A1/A4 execute on SC-2026-0005 | pass | `e2e\3-list-after-DOC-2026-0004.png` |
| Document DOC-2026-0004: type 2, Posted, Amount 330.66, Paid 0, Remaining 34,950.80, Refund −330.66, PreviousContractStatusId 2, CustomerId 7 | pass | SQL |
| A6 shared code sequence: follows reschedule DOC-2026-0003 on the same contract | pass | SQL |
| Contract → Assigned 5 «متنازل عنه» | pass | SQL |
| A5 unit 31 → Available 1, SaleContractId NULL (MarkSold precondition for a new contract) | pass (DB) | SQL; a new reservation/contract on the unit not exercised in the browser |
| 14 Active lines → Cancelled 3, CancelledByContractActionDocumentId = 5 (36 earlier lines already cancelled by the reschedule) | pass | SQL |
| PropertyLog: event 15, SourceTypeId 969, SourceId 5, Note DOC-2026-0004 | pass | SQL |
| Preview re-fetch on contract switch (126223's stale-preview finding) | pass | `e2e\4-…` |
| Browser console | only SignalR notification-hub handshake errors (local setup noise), none from the waiver module | console log |

**Not covered:** A2 with the setting changed to 2% (handler tests only — not changed on the shared tenant); A7 sales-org refusal (handler tests only); the Real Estate Settings fee field in the browser; A5 by creating a new contract on the unit.

**Findings**
- F1 (nit): description «تنازل للشركة، رد -330.66» shows a negative refund while paid is 0 everywhere (Q10) — wording for the reviewer / PO.
- F2: `PropertyManagerConnection` (Hangfire) has no local default; a local PM run needs it set — environment, not this CR.
- F3: `publish-db.ps1` builds with `MSBuild\Current\Bin\MSBuild.exe`, which fails MSB4062 on this machine; amd64 MSBuild works (`-Dacpac … -NoBuild`).
- F4: `app-login.ps1` timed out on the localbeta login; the browser profile was already signed in and needed only the company picker.

**Left on Sabreen:** the waiver schema (additive) and the executed waiver on SC-2026-0005 (contract Assigned, unit 31 Available). Teardown: API and dev server stopped, config.json restored, LocalDB dropped, all three repos clean.
