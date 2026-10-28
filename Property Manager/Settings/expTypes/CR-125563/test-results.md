---
type: test-results
cr: 125563
updated: 2026-10-19
---

# CR-125563 — Phase 9 end to end on db-all / Sabreen_Primary

## Setup

- **Tenant:** `db-all` / `Sabreen_Primary`, company Sabreen (the engineer approved the script, 2026-10-19).
- **Schema:** one guarded script (scratchpad `cr125563-sabreen.sql`, one transaction) creating `Pm_ProjectExpenseType` and `Pm_ProjectProjectExpenseType` and inserting `Acc_Module` **948**. Nothing else changed.
- **Test GL accounts** (new rows; type 7 under parent 10, copied from account 13's shape; scratchpad `cr125563-sabreen-testaccounts.sql`):

| Id | No | Purpose |
|---|---|---|
| 1501 | 1103901 | A: clean, cost-centre-linked (later given BeginningDebit 50 for A3 / A10) |
| 1502 | 1103902 | B: cost-centre-linked, BeginningDebit 100 ("carries value") |
| 1503 | 1103903 | C: clean, **not** cost-centre-linked |
| 1504 | 1103904 | D: clean, cost-centre-linked |

- **API:** PropertyManager from the set (Debug, built to the scratchpad), `https://localhost:2418` (1418 + 1000), `ASPNETCORE_ENVIRONMENT=Development`, `Authority` = accesscontrol.localbeta, `DebugTenantConnection` set as a process variable only.
- **Override proof:** `sys.dm_exec_sessions` on db-all showed `Sabreen_Primary | cr125563-pm-local | DESKTOP-KPT7EFB | 2026-10-19 22:07`.
- **Front:** `ng serve` ran out of memory (another set's node held about 6.6 GB), so the `npm run testing` dist was served on :4200 by a scratchpad static server, with the local-only `config.json` (PM API → localhost:2418; miscapi and dashboard → localbeta). The engineer signed in; the agent continued as Sabreen. The route guard needs `localStorage['UserPermissions']`, which the remote miscapi never filled for this user, so a local-only entry for module 948 was patched in for the screen check and removed afterwards.
- **Screen URL:** `/apps/Sabreen/property-manager/project-expense-types`.

## Results

| A | Check | Result |
|---|---|---|
| A1 | create «أعمال كهروميكانيك» (EMW) on account A → 200, id 1; listed by `GetActive` | pass |
| A2 | second type on asset account A → «حساب الأصل مستخدم في نوع تكلفة آخر» | pass |
| A3 | delete EMW after A got a beginning debit → «النوع عليه تكاليف مرحّلة – عطّله بدل الحذف» | pass |
| A4 | code « emw » (spaces, lower case) → «كود النوع مستخدم من قبل» | pass |
| A5 | delete LND while linked to project NRJ-A → «النوع مستخدم في مشروع» | pass |
| A6 | `Accounts` lists only A, B, D (C excluded) and expense types 2/4/5; C → «…يجب أن يكون مرتبطاً بمراكز التكلفة»; an asset account as the expense → «حساب المصروف يجب أن يكون حساباً فرعياً نشطاً من نوع مصروفات» | pass |
| A7 | LND linked to NRJ-A (cost centre 5): ProjectsCount 1, CapitalisedAmount 0.00 | partial: the real GL query runs on the real schema, but Sabreen has no journal lines on any project cost centre, so a non-zero sum isn't shown here (unit tests cover it) |
| A8 | deactivate EMW (allowed although its account carries value) → absent from `GetActive`, still in `GetAll` | pass |
| A9 | empty create → 4 required messages; LND created without `IsActive` → active = true, land as sent | pass |
| A10 | change EMW's asset account while A carries value → «لا يمكن تغيير حساب الأصل لأن عليه حركات» (plus the in-use message for B) | pass |
| A11 | create on B (carries value) → «حساب الأصل المختار عليه أرصدة أو حركات» | pass |
| — | clean delete: LND after its link was removed → 200, row gone | pass |
| UI | grid shows 7 columns + edit/delete at 1366 px; amount 0.00; active check; accounts as "number - name"; popup has code*, Arabic name*, English name, 2 account lookups*, land (off), active (on) | pass |

## Findings for the review

- **Q8 on real data:** Sabreen had no cost-centre-linked asset accounts at all (only 3 linked leaf accounts, all income or expense), so the asset lookup would be empty there until an accountant flags an account. Worth saying in the release note, or reconsidering Q8 (warning instead of refusal).
- **Grid at narrow width:** at about 800 px the grid clips its left columns («المُرسمل…», «فعال») instead of scrolling horizontally.
- **Popup title** truncates to «أنواع تكالي…» at narrow width.

## Data left on Sabreen_Primary

- Tables `Pm_ProjectExpenseType`, `Pm_ProjectProjectExpenseType`, and `Acc_Module` 948.
- `Acc_Account` 1501–1504 (`1103901`–`1103904`, description «CR-125563 test»); 1501 has BeginningDebit 50, 1502 has 100.
- `Pm_ProjectExpenseType` row 1 (EMW, inactive, «أعمال كهروميكانيك (معطل)»). Row 2 was deleted, and the link table is empty.

## Bug found while recording (2026-10-19, after review)

- **GetAll / GetById threw `SqlNullValueException`** ("Data is Null") once any type had no English name. The aggregate stores an empty NameEn as NULL, but `ProjectExpenseType.NameEn` was `string` in a `<Nullable>enable</Nullable>` project, so EF read it as required. Fixed: `string? NameEn` (PropertyManager.Logic/ProjectExpenseTypeAggregate/ProjectExpenseType.cs:10). Verified on Sabreen: GetAll returns 200 with a NULL-NameEn row. The mock-based unit tests can't see this (test-doubles-and-baselines.md). Phase 9 missed it because both test types had English names.
- **Edit popup opened half empty** (found in the video take): `open()` patched the form and then called `validationGroup.instance.reset()`, which in DevExtreme also clears the validated editors. Code, NameAr and both accounts came up empty when editing; NameEn and the checkboxes survived. Fixed by resetting validation first, then filling the form (project-expense-type-form-popup.component.ts `open()`). Phase 9 had tested edit through the API only.
