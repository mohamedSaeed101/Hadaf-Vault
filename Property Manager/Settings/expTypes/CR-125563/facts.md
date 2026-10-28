---
type: facts
cr: 125563
updated: 2026-10-19
source: "[[expTypes]]"
---

# CR-125563 — Facts: Project Expense Types (أنواع تكاليف المشاريع `set.expTypes`)

- **ADO:** Change Request 125563, created by the agent at the engineer's explicit request (2026-10-19). Fields copied from sibling CR 125488 (area `3- Customer Issues`, Program Property Manager, customer نواصى العقارية, version 7.0.82.x, due 2026-11-01). An ADO rule assigned it to Hassan Eldarwany on create; reassigned to Mohamed Saeed. State In Development.
  https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125563
- **Merge Desk:** ticket #12553, Beta, Acknowledge, owner Mohamed Saeed, repos API / WebContainer / Database, contract change on, components Database / Property Manager / Web Container (added manually on the engineer's ask "add ticket deployment"). Branch `cr125563` on origin in all three.
- **Source:** [[expTypes]] (the only source). No attachments. Siblings in [[Settings]]: `set.projects` BR-1 / BR-5 (the project «التكاليف» tab that consumes this catalog).
- **Surface:** Property Manager cloud: DB `Pm_*`, `AccFlex_Cloud_ERP\...\PropertyManager\`, front project `property-manager`. Desktop not touched.
- **Environment:** Stage Beta (first PR → `Stage_Beta`, second → `Master_Stable`).

## Scope (source: [[expTypes]])

1. New screen «أنواع تكاليف المشاريع» under إعدادات العقارات › البيانات الأساسية للعقارات. (§الوصول)
2. Fields: code (req), name ar (req), name en, asset account (req, non-main asset account), expense account (req, expense account), land flag (default no), active (default yes). (§الحقول 1–7)
3. List columns: code, type name, asset account, expense account, projects count, capitalised on all projects (amount), active. (§أعمدة)
4. BR-1 code unique; BR-2 asset account unique; BR-3 delete blocked if posted debit on the asset account or the type is used by a project; BR-4 inactive types hidden from new project choices, kept on old projects; BR-5 capitalised = sum of debit on the asset account over the cost centres of the projects using the type. (§قواعد)
5. Save / delete buttons. (§الأزرار)
6. Journal entries listed in the note (cost registration, REM_COGS on handover) are produced by GL / purchases and the handover screen, **not by this screen**. (§القيود، §التكامل D30)
7. AC-1..AC-3. (§معايير القبول)
8. Open question in the note: real chart of accounts (property inventory vs separate WIP accounts). (§أسئلة)

## Code facts (explorer scans, 2026-10-19)

- No cloud table for expense types or project expenses. Legacy `dbo.Rst_ExpenseDetails` (Id, Name, AssetAccountId, ExpenseAccountId; no code / name en / flags / unique keys) and `Rst_ProjectExpenseDetails` (per project, **name-based**, not FK) exist for the desktop.
- Desktop `frmBasicData.cs`: lookups are the full active account list (no type filter); delete has **no** usage check.
- `Pm_Project.CostCenterId INT NULL`; no project ↔ expense-type relation anywhere.
- GL account class = `Acc_Account.AccountTypeId` (`GeneralLedger.Logic\AccountAggregate\AccountType.cs`): assets 6 Long-term, 7 Current, 16 Projects under construction, 18 Prepaid; expenses via `AccountType.GetExpenseAccountTypes()` = 2, 4, 5. Leaf = `IsLastNode`.
- Journal lines `Acc_JournalAction` (AccountId, Debit, DebitLocal, CostCenterId, Void, Revised) + header `Acc_Journal.Void`. Ledger reports filter `ja.Void = 0 AND j.Void = 0` and optional `Revised`.
- PM already injects `IGeneralLedgerContext` (`CreateProjectCommand.cs:69`).
- No account query in PM; the front account lookup exists only in cash-control (`cash-account-lookup`).
- Module ids: max used 946 (CR-125488). Menu on Master_Stable has groups 2 / 3 / 4 only; Stage_Beta has root "5" «إعدادات العقارات» › "5_1" «البيانات الأساسية للعقارات» (item 5_1_1 Installment Plans, module 934) and "5_2" tools.
