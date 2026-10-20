---
type: spec
cr: 125563
updated: 2026-10-19
status: draft — recommended answers to [[open-questions]] Q1–Q7 are written in; changes if the engineer answers otherwise
source: "[[facts]]"
---

# CR-125563 — Spec: Project Expense Types (أنواع تكاليف المشاريع)

Path taken: grilled and written by the agent (`grill-with-docs` + `to-spec` process) against [[facts]] and [[expTypes]]. The KG has no Property Manager entity notes (D46), so the check runs on the source note and the GL glossary.

## Problem Statement

Property Manager has no catalog of project cost types. The desktop keeps one (`Rst_ExpenseDetails`) so a project's cost can be split by type (land, construction, finishing …), each on its own asset account, and charged to an expense account per property on handover. The cloud project «التكاليف» tab and the handover cost entry both need this catalog first.

## Solution

A new settings screen with a list and a form for expense types, backed by a new `Pm_ProjectExpenseType` table and a CRUD API in PropertyManager. The list also shows, per type, how many projects use it and the amount capitalised on its asset account over those projects' cost centres. A project ↔ type link table is created now (no UI here) so the count, the capitalised amount and the delete check are real; the project «التكاليف» tab that fills it is a later CR.

## User Stories

1. As a PM admin I add a type with code, Arabic / English name, asset account, expense account, land flag and active flag.
2. As a PM admin I edit a type, and deactivate it instead of deleting it when it carries cost.
3. As a PM admin I see per type: projects count and capitalised amount.
4. As a PM admin I cannot delete a type that carries posted cost or is used by a project.
5. As an accountant I can only pick a leaf, active asset account for the asset side and a leaf, active expense account for the expense side.

## Implementation Decisions

- **Table** `dbo.Pm_ProjectExpenseType` (Q2: new table; legacy `Rst_ExpenseDetails` untouched, no migration):
  `ProjectExpenseTypeId INT IDENTITY PK`, `Code NVARCHAR(50) NOT NULL` (UQ), `NameAr NVARCHAR(250) NOT NULL`, `NameEn NVARCHAR(250) NULL`, `AssetAccountId INT NOT NULL` (FK `Acc_Account`, UQ), `ExpenseAccountId INT NOT NULL` (FK `Acc_Account`), `IsLand BIT NOT NULL DEFAULT 0`, `IsActive BIT NOT NULL DEFAULT 1`; no audit columns (same as `Pm_PaymentTerm`).
- **Link table** `dbo.Pm_ProjectProjectExpenseType` (Q1): `ProjectId` FK `Pm_Project`, `ProjectExpenseTypeId` FK, PK on both. No UI or command writes it in this CR.
- **Account rules** (Q3):
  - asset account: `IsLastNode = 1`, `IsActive = 1`, `AccountTypeId IN (6, 7, 16)` (18 prepaid dropped, business-check-1 row 9), `CostCenterLinked = 1` (Q8, row 2)
  - expense account: `IsLastNode = 1`, `IsActive = 1`, `AccountTypeId IN AccountType.GetExpenseAccountTypes()` (2, 4, 5)
  - asset ≠ expense account (implied by the types, checked anyway)
- **Uniqueness:** code (trimmed, case-insensitive) and asset account, checked in the command before save and backed by unique indexes; DB duplicate errors map to the same messages.
- **Capitalised amount** (BR-5, Q4, Q9) = gross `SUM(ja.DebitLocal)` over `Acc_JournalAction ja JOIN Acc_Journal j` where `ja.AccountId = AssetAccountId`, `ja.Void = 0`, `j.Void = 0`, `ja.Revised = 1`, and `ja.CostCenterId IN` (each linked project's cost centre **plus its descendants**, `dbo.Acc_GetCostCenterChildTree` / recursive CTE — business-check-1 row 1). Company currency, all branches (row 8); the column header says «(عملة الشركة)». Projects without a cost centre add nothing.
- **"Carries value" guard** (row 5) = `Acc_Account.HasTransactions = 1` or a non-zero opening / beginning debit or any non-void journal line on the account (revised or not — conservative).
- **Delete** (BR-3): refused when the asset account carries value → «النوع عليه تكاليف مرحّلة – عطّله بدل الحذف»; refused when a link row exists → «النوع مستخدم في مشروع».
- **Update** (Q7): changing the asset account is refused while the current one carries value. Every other field is editable; deactivating is always allowed.
- **New asset account already in use elsewhere** (Q10, row 6): on create and on asset change, refused when the chosen account already carries value.
- **Link table scope** (Q11, row 7): only leaf projects (no sub-projects) may be linked; enforced by the later «التكاليف» tab, recorded here.
- **Inactive** (BR-4): the active-types list for future project pickers is a query filter `IsActive`; nothing else changes for linked projects.
- **API** `api/ProjectExpenseType`: `GET GetAll` (list incl. counts / amounts), `GET {id}`, `GET Accounts` (both account lists in one DTO), `GET GetActive` (for the later project tab), `POST`, `PUT`, `DELETE {id}`. Module **948** (Q5), view / add / edit / delete policies.
- **Menu** (Q5): root "5" «إعدادات العقارات» › "5_1" «البيانات الأساسية للعقارات» › item **5_1_5** «أنواع تكاليف المشاريع» "Project Expense Types", route `project-expense-types` — same group shape as Stage_Beta.
- **Front:** NgModule `project-expense-types` with a grid (7 columns, amount formatted, active as check) and a popup form; account fields are `dx-lookup` with search, fed by `GET Accounts`; i18n ar-EG + en-US; route `data: { ModuleId: 948 }`.

## Acceptance (A1..An)

- **A1** Adding «أعمال كهروميكانيك» with a new asset account saves it; it is returned by `GetActive` (the feed of the project «التكاليف» tab). (AC-1, adapted: the tab itself is a later CR)
- **A2** Saving a type with an asset account already used by another type is refused. (AC-2)
- **A3** Deleting a type whose asset account has a non-void debit line is refused with «النوع عليه تكاليف مرحّلة – عطّله بدل الحذف». (AC-3)
- **A4** Saving with a duplicate code is refused. (BR-1)
- **A5** Deleting a type linked to a project is refused. (BR-3)
- **A6** The asset lookup lists only leaf active cost-centre-linked accounts of types 6/7/16; the expense lookup only leaf active accounts of types 2/4/5; the API refuses others. (§الحقول 4–5)
- **A7** List shows projects count and capitalised amount = sum of revised non-void debits (company currency) on the asset account over linked projects' cost centres and their child centres. (BR-5)
- **A11** Creating a type on an asset account that already carries value is refused. (Q10)
- **A8** A deactivated type disappears from `GetActive` and stays on the list. (BR-4)
- **A9** Code, Arabic name, asset and expense accounts are required; land defaults to no, active to yes.
- **A10** Changing the asset account of a type with posted debits is refused. (Q7)

## Testing Decisions

- Unit tests (`PropertyManager.Application.Test\ProjectExpenseTypes\`): create / update / delete commands for A2–A6, A9, A10, both delete messages, the account-type filters, the capitalised sum (void lines and other cost centres excluded).
- End to end on a tenant (Sabreen) via `local-api-run`: A1–A10 with SQL proof.

## Out of Scope

- The project «التكاليف» tab (picking types, cost per type, distribution) and the link table's writer.
- The handover REM_COGS entry and asset-card land handling (uses `IsLand` later).
- Migrating desktop `Rst_ExpenseDetails` rows.
- Carried, not owned: the Amenity grid's `Serves` string → int change (`amenity-main-grid.component.ts`) is a byte-identical copy of CR-125487's shipped fix. The regenerated PM client types `Serves` as `int`, so the front would not build without it. Say so in the PR description (review-1 row 1).

## Further Notes

- GL can still turn an unused leaf account into a parent or deactivate it; GL knows nothing of PM usage. A6 holds at save time only (business-check-1 row 10) — known gap, cross-module.

- Three open PM CRs (125486/87/88) touch the same `Module.cs` and `WebMenuGroup.cs` lines; merge conflicts are expected and trivial.
- Stage_Beta's `WebMenuGroup.cs` declares `PropertyBasicData` twice (lines 31 and 51) — a pre-existing merge leftover, not ours to fix; it will surface as a conflict on the Stage_Beta PR.
