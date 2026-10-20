---
type: decision-log
cr: 120883
title: CR-120883 — Design Grilling Session
created: 2026-09-23
status: awaiting-confirmation
open_questions: 0
tags: [cr, cr-120883, decisions, grilling]
---

# CR-120883 — Design Grilling Session (Decision Log)

> [!info] Related notes
> CR: [[CR-120883 - Source]] · First plan draft: [[CR-120883 - Plan]]

> [!success] Plan rewritten on 2026-09-24
> [[CR-120883 - Plan]] now implements every decision in this log (Rounds 1–7). The superseded first draft is kept as [[CR-120883 - Plan (draft v1)]]. The plan adds its own decisions P1–P7, such as the type-id blocks and the filter semantics; they are listed there for the PO to confirm.

---

## 1. Headline Decisions

| Area | Decision |
|---|---|
| **Screen** | A **new report screen in the Logistics app**. The existing "User Transactions" report stays exactly as it is |
| **Scope** | **Transactions only, never master data** (Q34). **Logistics:** only the **20 existing types** in `Lgx_TransactionsType` (ids 1–20); no new Logistics rows (Q32). **HR:** 8 `IAuditedEntityBase` documents (Q33). **Cash:** 14 audited documents. **Construction:** 15 audited documents. **57 types in total**. **No new audit logging** anywhere (Q27–Q29) |
| **Row shape** | One row per **document or record**, plus a "Change Details" tab showing before and after values |
| **How rows are built** | A **generated view** (from a settings table) in the DB project |
| **Filters** | An **Application** picker (default Logistics, can be cleared to show all modules). It controls the type list and which module's filters are shown |
| **Filter lookups** | Served from the **Misc API** |
| **Audit table** | **No schema change and no index** on `ACFX_Audit` for now |
| **Permission** | Reuses **720**. The menu caption is the same as the old report for now |
| **Tests** | Added to **`Logistics.Application.Test`**, with a project reference to `AnalyticsReader.Api` |

---

## 2. Facts Found in the Code (Research, Not Decisions)

> [!success] Old and new values already exist
> `ChangeTrackerExtensions.SetShadowProperties` → `AuditEntry.ToAudit()` writes to **`ACFX_Audit`** (`TableName`, `DateTime` UTC, `KeyValues`, `OldValues`/`NewValues` JSON, `UserName`) from **every** context: Cash, Construction, Payroll and all six Logistics contexts. There is a precedent for reading it: `dbo/Views/Vw_Pr_AnnualIncreaseDetail.sql`.

> [!warning] Limits of the audit log
> - Only entities in the **Added or Modified** state are audited. **Deletes are never audited**, whether soft or hard.
> - It has **no action column**, so Add, Edit and Cancel must be inferred.
> - It stores `UserName`, not a user id. Times are UTC.
> - Child `List<T>` collections are nested as JSON inside the parent row.
> - For class hierarchies that share one table, all subtypes log under the **shared table's name**. The subtype only appears in the JSON.
> - HR table names are always `PR_<ClassName>` (a rename loop in `PayrollContext`).

> [!warning] Not every entity is audited (found in Round 5)
> - An entity is logged **only** if it is `IAuditedEntityBase` **and** is Added or Modified (`ChangeTrackerExtensions.cs:42`).
> - `Entity` does not implement it. Only 12 abstract bases do, all in Logistics. In Cash, Construction and HR, every audited entity declares it directly.
> - **Editing only the child lines records nothing.** Unchanged entries are skipped (`EntryExtension.cs:13`), so the parent is not logged. Child entities aren't `IAuditedEntityBase` either.
> - **Saves through a read-side copy are not logged.** Logistics has copies in other contexts, e.g. `SalesOrder` in Inventory and Production, and `GoodIssue` in Maintenance and Sales. A save through a copy writes no audit row.
>
> > These documents **will not appear** in the report (Q29). Tell the customer and product owner, because it hits HR hardest (the CR's happy path, §4.5.1).
>
> | Module | Aggregate roots audited / not | Transactional documents not audited (candidates, to verify) |
> |---|---|---|
> | HR | 8 / 37 | PayingSalary, AttendanceSheet, Advance, Penalty, EmployeeBonus, LeavePermission, Incident, InningsVacation, Purchase, Correspondence, EmployeePerformanceAppraisal, EmployeeVacationAndEndWorkAllowance, EmployeeProjects. Not roots: EmployeeEndWork, ErrandBusiness, WorkOrder, MobileInvoice, DailyAllowanceEmployee, PenaltyNotification, ProjectAttendance. Salary and SalaryDetail are logged only inside `SalaryMain` |
> | Construction | 15 / 14 | ConstractorContract (has an approval workflow), TransferSettlement |
> | Cash | 15 / 2 | BankCheckBookDocument. Not roots: ReceiptBookDocument, TreasuryBill, BankGuaranteeTransaction, WalletDetail |
> | Logistics | 129 / 44 | Out of scope (Q27) |
>
> This comes from an automated inheritance scan, with about 10 classes checked by hand. Before seeding, confirm that each candidate is a real document with its own screen and not just a child row.

### Audited tables by module

| Module | Documents | Master / config | Distinct tables |
|---|---|---|---|
| Logistics | 45 | 46 | **91** (93 classes; every class hierarchy stores its subtypes in one shared table) |
| Cash | 15 | 2 | 17 |
| Construction | 15 | 4 | 19 |
| HR | 7 | 3 | 10 |
| **Total** | **82** | **55** | **≈137** |

- **No header date:**
  - goods receipt, goods issue, inventory movement, physical inventory count, revaluation
  - all master data
- **No number/code:**
  - CRM tables, pricing/discount condition tables
  - salary sheet (year and month instead), employee transactions

### Other facts

- **AnalyticsReader** has no existing "settings → dynamic UNION" pattern. It *does* have OData over raw SQL, where `$filter` and `$orderby` are applied in the database (`CashControlODataController.FinancialCustodyTransactionReport`).
- **Filter components:**
  - Reusable multi-select filters exist only for **construction project** (`log-project-check-list`) and **payroll department/project** (`pay-department-check-list`).
  - Treasury, bank and branch have none.
  - The existing ones call their own module's API and would bring heavy shared modules into Logistics.
- **Tests in `Logistics.Application.Test`:** this works, with these conditions:
  - Add a `ProjectReference` to `AnalyticsReader.Api`.
  - Keep AnalyticsReader tests in their own files, because both projects define a `Startup` class.
  - The test build will need the DevExpress feed and a libman restore.
  - `azure-pipelines.yml` is only a template and runs **no tests**.
- **Misc API** exists (`Miscellaneous/Misc.API`), and the front end already has `apiUrls.miscapi`.
- **Found in passing (security):** a Discord webhook key in `azure-pipelines.yml` and the DevExpress feed key in `nuget.config`, both committed in plain text. A separate task has been suggested.

---

## 3. Decision Log (All Rounds)

### Round 1

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q1 | One row per document or per action? | **One row per document**, with a Change Details tab | |
| Q2 | Which types? | **Every entity that implements `IAuditedEntityBase`** | Expanded further by Q9 and Q10 |
| Q3 | What does "Transaction Date" mean? | **Document date** (for now) | Refined by Q23 |
| Q4 | How should the org filters work? | **A filter set per module**, plus an **Application** selector that hides the other modules' filters | Detailed in Q12, Q13 and Q21 |
| Q5 | Is the desktop AccFlex_ERP used? | **Cloud only** | Desktop audit tables are not needed |
| Q6 | Where does the report live? | **A new report in Logistics** | Detailed in Q6a–Q6d |
| Q7 | Change to the `ACFX_Audit` schema? | **No** (option b) | Confirmed by Q11 = no index |
| Q8 | New test project? | **Put tests in `Logistics.Application.Test`** for now | Verified as workable (see facts) |

### Round 2

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q6a | What does "a new one in Logistics" mean? | **A new report screen** next to the existing one | Differs from CR §4.1-1 ("don't build a new report"). The product owner should agree |
| Q6b | What happens to the old report? | **Keep both** | The old one stays Logistics-only and unchanged |
| Q6c | Which permission? | **Reuse 720** | |
| Q6d | Menu name? | **Same caption for now** | The **internal** report name must differ, e.g. `"User Transactions All Modules Report"`, because print/export and saved layouts look reports up by that name. *Stated; not objected to* |
| Q9 | Master data too? | ~~**Yes: documents and master data**~~ **Replaced by Q34:** no master data | |
| Q10 | Logistics scope? | ~~**All** audited Logistics entities~~ **Replaced by Q32:** only the 20 existing types | ~~91 tables~~ |
| Q11 | Index on `ACFX_Audit`? | **No, for now** | Leads to Q25 (load history on demand) |
| Q12 | How does the Application picker behave? | **Single select, default = Logistics.** The type list is filtered by the selected application | |
| Q13 | Filters per module | **Logistics:** sales org, purchase org, inventory management · **Cash:** treasury, bank · **Construction:** project · **HR:** department, branch | Master-data rows pass through these filters |
| Q14 | Approvals | **Shown as edits of the status field** | No separate "approve" action in v1 |
| Q15 | Ids or names in before/after values | **Resolve names for a short list of key fields** | The list is in Q20 |
| Q16 | Field captions | **A caption reference table**, falling back to the raw property name | |
| Q17 | Main grid columns | **The old columns + Module + one merged "Organization / Project / Department" column** | |
| Q18 | Where the filter lists come from | **Misc API** | One generic checklist component in the new report |

### Round 3

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q19 | Type granularity in Logistics | **One type per table.** The subtype is shown in the row's type name | About 60–80 picker entries instead of about 150 |
| Q20 | Fields whose names are resolved | **The list of 13:** project, employee, bank, treasury, supplier, customer, material, inventory management, sales org, purchase org, department, branch, currency | Resolved by field name across all tables, through a small reference table |
| Q21 | Can the Application picker be cleared? | **Yes.** Cleared shows every licensed module, with only the common filters | |
| Q22 | How rows are built for ≈137 tables | **Generated view:** settings table → generator → one committed SSDT view, with a literal type id per branch | Mistakes caught at build time; SQL Server skips types that aren't selected |
| Q23 | Missing date | **Document date, or the creation date when the table has none** | *Stated; not objected to* |
| Q23b | Missing number | **Leave it empty** (not the id) | |
| Q24 | Who runs the generator | **A SQL script** in `Scripts/Tools/`. A developer runs it against a dev DB and commits the output view | |

---

### Round 4

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q25 | When "Change Details" loads | **Only when the user expands a row** (on demand) | The new screen uses its own expand-on-demand detail, not the shared report grid's `$expand` |
| Q26 | What the lookup lists return | **The Application lookup shows only the applications the company is licensed for** | *Interpretation to confirm:* the treasury, bank, project, department and branch lists are **not** narrowed to the current user; they appear only when their application is licensed and selected |

### Round 5

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q27 | Add audit logging to Logistics entities that aren't audited? | **No, change nothing in Logistics** | The Logistics scope stays "already `IAuditedEntityBase`". Known gaps stay as they are: read-side copies, StockReevaluation, ProductionOrderProduct, Logistics master data |
| Q28 | Which Cash, Construction and HR types does the report show? | **All transactional documents that are already audited** | Refined by Q29 |
| Q29 | Add audit logging to Cash, Construction and HR documents that aren't audited today? | **No. Show only the ones already audited** | Same rule as Logistics (Q27). `ChangeTrackerExtensions` stays unchanged. Unaudited documents (§2 list) are a known gap |
| Q30 | Should a parent be logged when only its child lines change? | **Moot**: no logging changes (Q29) | *Known gap:* an edit that changes only the lines, with the header unchanged, has no history |
| Q31 | Where do created by / modified by come from for tables without those columns? | **Moot**: every type in scope is `IAuditedEntityBase`, so it has `CreatedById` and `LastModifiedById` | |

### Round 6

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q32 | Logistics types in `Lgx_TransactionsType`? | **Add no new Logistics rows.** Logistics keeps its 20 existing types (ids 1–20) | **Reverses Q10** ("all 91 audited Logistics tables"). New rows are for Cash, Construction and HR only. ~~*Implied:* `Lgx_TransactionsType` is the type catalog that drives the generated view (Q22).~~ Replaced by Q35 and Q36. Each of the 20 still has to be checked as audited before Change Details can show history |
| Q33 | HR scope? | **Every HR entity that implements `IAuditedEntityBase`, except master data** | 8 entities. `Employee` and `SickLeavePolicy` are excluded |
| Q34 | Master data in any module? | **No. Master data is excluded everywhere** | **Reverses Q9.** Q23 falls back to the creation date only when a document has no date of its own |

### Round 7

| Q | Question | Answer | Notes |
|---|---|---|---|
| Q35 | Change `Lgx_TransactionsType`? | **No. Leave it exactly as it is** | Replaces the "implied" note in Q32. The old report and its enum (1–20) stay untouched |
| Q36 | Where does the new report's type catalog live? | **A new `ACFX_` table**, e.g. `ACFX_UserTransactionType` | This is the Q22 settings table the generated view is built from. Defined in `dbo/Tables`, seeded by an idempotent `MERGE` in `Scripts/ReferenceDataScripts/`, registered in the sqlproj. *Interpretation:* it holds **all 57** types, with the 20 Logistics types copied in, so the new report reads a single catalog |
| Q37 | Link each type to its module? | **Add `ApplicationId`**, FK to `Acc_Applications` | Drives the Application picker (Q12, Q21) and license filtering (Q26) |

**`ApplicationId` values (from `Acc_Applications`, seeded in `0001_GL_ReferenceDate.sql`):**

| Module | ApplicationId | Name in `Acc_Applications` | Types |
|---|---|---|---|
| Logistics | **12** | Logistics / الخدمات اللوجستية | 20 |
| HR | **4** | HR Managment / اداره الموارد البشريه | 8 |
| Cash | **7** | AccountingSafe / خزينة | 14 |
| Construction | **9** | Construction / إنشاءات | 15 |

**Proposed columns** (from Q22, Q23 and Q13):
- `TransactionTypeId`, `Name`, `NameSecondLanguage`, `ApplicationId`
- `SourceTable`, `IdColumn`, `CodeColumn` (nullable, Q23b), `DateColumn` (nullable → falls back to `CreatedOn`, Q23)
- `AuditTableName` (the `ACFX_Audit.TableName` spelling)
- the filter column for each module (org, treasury/bank, project, department/branch)

**HR entities in scope (Q33),** all under `Payroll/Payroll.Logic/`:

| Entity | Kind |
|---|---|
| `SalaryMain` | document |
| `Vacations` | document (approval) |
| `ResignationRequest` | document |
| `EmployeeTransactions` | document (no number; see Q23b) |
| `EffectiveDateNotice` | document |
| `EmployeeIncome` | document |
| `EmployeeAllowance` | document (not a root) |
| `DailyAllowance` | document (not a root) |
| ~~`Employee`~~ | master data, excluded |
| ~~`SickLeavePolicy`~~ | master data (configuration), excluded |

(`VacationForListDto` also implements the interface, but it is a DTO, not a table.)

**Cash entities in scope:** 14 of the 17 `IAuditedEntityBase` entities under `CashControl/CashControll.Logic/`.

| Entity | Table | Kind |
|---|---|---|
| `CashReceipt` | `Saf_StoreDailyReceive` | document |
| `CashPayment` | `Saf_StoreDailyPayment` | document |
| `MoneyTransfer` | `Saf_MoneyTransfer` | document. *The old plan said it has no `CreatedById` column; check that the audit columns exist* |
| `ReceivableNote` | `Saf_ReceivableNote` | document |
| `PayableNote` | `Saf_PayableNote` | document |
| `ReceivableBankTransfer` | `Saf_RecievableBankTransfer` | document |
| `PayableBankTransfer` | `Saf_PayableBankTransfer` | document |
| `BankGuarantee` | `Saf_BankGuarantee` | document |
| `FinancialCustody` | `Saf_TemporarySave` | document (approval) |
| `FinancialCustodySettlement` | `Saf_TemporaryAdvanceSettelment` | document (not a root) |
| `FinancialCustodySettlementRequest` | `Saf_FinancialCustodySettlementRequest` | document (not a root) |
| `PaymentRequest` | `Saf_PaymentRequest` | document (approval) |
| `ReceivementRequest` | `Saf_ReceivementRequest` | document (approval) |
| `TreasuryDaily` | `Saf_StoreDaily` | daily treasury open/close (opening and closing amounts). *Counted as a transaction; confirm* |
| ~~`Bank`~~ | `Saf_Bank` | master data, excluded |
| ~~`Treasury`~~ | `Saf_Store` | master data, excluded |
| ~~`Wallet`~~ | `Saf_Wallet` | master data, excluded |

Approval status changes show as edits (Q14).

**Construction entities in scope:** 15 of the 19 `IAuditedEntityBase` entities under `Construction/Construction.Logic/`.

| Entity | Table | Kind |
|---|---|---|
| `PreOwnerStatement` | `Cnt_PreOwnerProgressInvoice` | document (approval) |
| `OwnerStatement` | `Cnt_OwnerProgressInvoice` | document |
| `OwnerInvoice` | `Cnt_OwnerInvoice` | document |
| `OwnerMemo` | `Cnt_OwnerMemo` | document |
| `PreContractorStatement` | `Cnt_PreConstractorProgressBill` | document (approval) |
| `ContractorStatement` | `Cnt_ConstractorProgressBill` | document. *The old plan said it has no `ModifiedBy`; check that `LastModifiedById` exists* |
| `ContractorMemo` | `Cnt_ContractorMemo` | document |
| `ContractorMemoRequest` | `Cnt_ContractorMemoRequest` | document (approval) |
| `ContractorAdvance` | `Cnt_ContractorAdvance` | document (approval) |
| `ProjectPriceOffer` | `Cnt_ProjectPriceOffer` | document (approval) |
| `ProjectManagementScheduling` | `Cnt_ProjectManagementScheduling` | project schedule. *Counted as a transaction; confirm* |
| `CostDistribution` | `Cnt_CostDistribution` | document |
| `WorkerCostDistribution` | `Cnt_WorkerCostDistribution` | document |
| `WorkerUsage` | `Cnt_WorkerUsage` | document |
| `MachineUsage` | **`Lgx_MachineUsage`** | document. *Construction entity with an `Lgx_` table name; it belongs under Construction, not Logistics (Q32)* |
| ~~`Project`~~ | `Cnt_Project` | master data, excluded |
| ~~`Contractor`~~ | `Cnt_Constractor` | master data, excluded |
| ~~`Owner`~~ | `Cnt_Owner` | master data, excluded |
| ~~`Units`~~ | `Lgx_UnitOfMeasure` | master data, excluded |

Not audited, so not shown (Q29): `ConstractorContract` (`Cnt_ConstractorProjectPrice`) and `TransferSettlement` (`Inv_TransferSettlement`).

## 4. Still Open

> [!success] No open questions. The full decision list is waiting for final confirmation before the plan is rewritten.

---

## 5. What Changes in the Plan

- [ ] **New report instead of extending the old one:**
  - new route, component, module and internal report name in Logistics
  - reuses permission 720
  - the old report and `Vw_Lgx_UserTransactions` are untouched
- [ ] **Settings table: new `ACFX_UserTransactionType`** (Q36), one row per type:
  - table, id, number and date columns; created-by and modified-by columns
  - filter columns, audit table name
  - **`ApplicationId`**, FK to `Acc_Applications` (Q37): Logistics 12, HR 4, Cash 7, Construction 9
  - seeded with 20 Logistics, 8 HR, 14 Cash and 15 Construction types: **57 rows**, with no master data
  - `Lgx_TransactionsType` stays **untouched** (Q35)
- [ ] **Generator SQL script** (`Scripts/Tools/`) → a committed generated view with a literal type id per branch.
- [ ] **Change Details view** over `ACFX_Audit`:
  - Add, Edit and Cancel inferred from the JSON
  - caption table, plus name resolution for the 13 key fields
  - **no index**, loaded per row on demand (Q25)
- [ ] **Misc API** lookup endpoints for the licensed applications, plus treasury, bank, project, department and branch (not user-scoped, per Q26).
- [ ] **Generic checklist component** plus the **Application picker** (default Logistics, can be cleared). The type list and filter sets follow the selected application.
- [ ] **License filtering** on the server for types, rows and lookups.
- [ ] **Tests** in `Logistics.Application.Test`, with a reference to `AnalyticsReader.Api` and in separate files.
- [ ] **Known gaps to write down for the customer and product owner:**
  - Cash, Construction and HR documents that aren't audited (§2 list: most of HR, and ConstractorContract)
  - edits that change only a document's lines
  - saves through Logistics read-side copies
  - deletes
- [ ] **Estimate:** 11 SP no longer holds. The scope went from 13 new types on the old report to ≈137 tables on a new report. It must be re-estimated after the plan is rewritten.
- [ ] **Flag to the product owner:** a new report goes against CR §4.1-1 ("use the same report").
