---
type: business-check
cr: 125488
round: 2
updated: 2026-10-18
---

# Business check round 2 — CR_125488   verdict: pass (3 should, 4 nit; no block)

**KG coverage:** `D:\Hadaf\Accflex_KG\` still does not exist; Property Manager has no KG entity notes (same gap as round 1, reported to the PO team, not a blocker). Sources used: the revised `spec.md`, `decisions.md` (Q1–Q14), the source note `bulk Units V2.md` (wins over `bulkUnits.md`), sibling decisions `importProjects\CR-125486\decisions.md` (Q2, Q8, Q11) and `importUnits\CR-125487\decisions.md` (Q12, Q13), and the code on `Master_Stable`.

CE = `D:\Hadaf\worktrees\cr125488\AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\PropertyManager`, DB = `D:\Hadaf\worktrees\cr125488\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Tables`, V2 = `..\bulkUnits\bulk Units V2.md`.

## Round-1 rows — new state

| # | round-1 rule (short) | state | evidence |
|---|---|---|---|
| 1 | Exists → skip must run before the garage check, or a rerun fails | **fixed** | spec.md:80-81: the tenant-wide exists check runs first, «كود الجراج موجود» only for rows still «جديد»; A3 and story 4 now hold |
| 2 | Project currency may be null; property currency is NOT NULL | **fixed** | spec.md:84 adds the request-level check «المشروع ليس له عملة» next to the leaf-project and sales-org checks |
| 3 | «أول نوع في المشروع» has no order | **fixed** | spec.md:60: lowest `InvestmentTypeId` among the project types. The optional "show the resolved type in the summary line" was not adopted; acceptable |
| 4 | Blank-model guard decided in one CR, "required" in the other | **closed by decision** | decisions.md Q9 and CR-125487 decisions Q12 both adopt the identical guard (`Property.cs:119` / `:220`); `PropertyModelId` is nullable in DB and entity (`Pm_Properties.sql:22`, `Property.cs:34`), so no invariant breaks |
| 5 | Inherited project cost center could be a leaf the Properties screen cannot show | **closed by decision** | CR-125486 decisions Q8: the auto cost center is non-leaf (`IsLastNode = false`); decisions.md Q12, V2 BR-4 |
| 6 | BR-6 rent clause / BR-7 garage rent have no cloud model | **closed by decision** | decisions.md Q1, V2 fields 13/25, BR-6/BR-7: rent deferred to the rent-prices CR; spec.md:63,128 |
| 7 | «متاح» status and history event BR-8 | **closed by decision** | decisions.md Q2, V2 BR-5/BR-8: status = project status, no history event; spec.md:59,64 |
| 8 | `{B}` building: text or parent property | **closed by decision** | decisions.md Q4, V2 field 2: text in the code only; spec.md:48 |
| 9 | Serial UQ clash mapped to the name-duplicate message | **fixed** | spec.md:93, decisions.md Q14, V2 BR-10: «تعارض في كود العقار – أعد المحاولة», batch rolled back |
| 10 | Dead rule «المشروع ليس له رقم» | **fixed** | spec.md:47: `ProjectNumber` NOT NULL, clause dropped |
| 11 | Tenant-wide exists check is best-effort, not DB-enforced | **fixed** | spec.md:86 states it. "Skip message names the owning project" not adopted; acceptable for a setup tool |
| 12 | `ValidateProperties` is `internal` | **fixed** | spec.md:82: verify calls `Property.Create` on the built poco without saving |

All 12 round-1 rows are resolved; none carried forward.

## New findings (V2 additions vs the Property aggregate and create path)

| # | rule | documented in | what the spec breaks | suggested spec change | severity |
|---|---|---|---|---|---|
| 13 | «اثبات الإيراد» is being removed from property and project: CR-125486 Q2/Q11 drops `Pm_Project.ProofOfIncomeAndExpenses`, CR-125487 Q13 drops `Pm_Properties.ProofOfIncomeAndExpensesId` + FK and removes it from `Property` / `PropertyPoco` / the create command. V2 BR-4 does **not** list it among the inherited fields | `importProjects\CR-125486\decisions.md:10-14,24-27`; `importUnits\CR-125487\decisions.md:18,22-25`; V2:62 (BR-4); CE `Property.cs:49,134` (NOT NULL int from `maybeProofOfIncomeAndExpenses.Value.Id`), `Project.cs:42` (plain int, not a FK), DB `Pm_Properties.sql:38,58` | spec.md:61 inherits `ProofOfIncomeAndExpensesId` from the project, a field the sibling CRs delete and the source note does not ask for. If CR-125487 merges first, this CR's handler references a removed poco member and fails to build; if this CR merges first, `Master_Stable` carries a line the next merge must delete. Either way the Acceptance list promises a value the product is retiring | Remove `ProofOfIncomeAndExpensesId` from the inherited list (spec.md:61) to match V2 BR-4. Add under Further Notes: "until CR-125487 drops the column, the poco gets `ProofOfIncomeAndExpenses.PropertyContraction` (id 1, the DB default of the project column) so `Property.Create` passes; the second merge removes that line" | should |
| 14 | Area must be > 0 and price ≥ 0 for every generated property (spec.md:54,56,78); the aggregate validates neither (`ValidateProperties` checks number, names, type, geography, currency, investment type only), so the row check is the only guard | CE `Property.cs:272-325`; DB `Pm_Properties.sql:26-27` (area NOT NULL default 0, price nullable); V2:34-35 (fields 16, 17 are «اختياري») | The garage is not a grid row: it is derived from the pattern inputs «مساحة الجراج» / «سعر الجراج», which V2 marks optional. A blank or 0 garage area, or a negative garage price, passes the row check (it runs on units only) and `Property.Create`, and lands as a 0-area garage; the spec's own invariant for units is silently relaxed for garages, and A5 tests only the happy path | Add to the request-level checks (spec.md:84): when the garage option is on, «مساحة الجراج» is required and > 0 and «سعر الجراج» ≥ 0 (same messages as the row check, named on the pattern field); the server enforces both since it receives the garage values. Add a negative test to Testing Decisions | should |
| 15 | The 500-row limit "including garages" (A8, BR-9, Q10) is enforced on the front (save disabled) and on the server (request rejected); both must count the same rows | V2:67 (BR-9), V2:90 (AC-8); spec.md:84,98; decisions.md Q10 | The spec does not say which rows count: all grid rows, or only rows that will be created («جديد» + their garages). If the front counts grid size and the server counts creatable rows (or the reverse), a 300-row grid with garages where 100 rows are «موجود» passes one side and fails the other; A8 cannot be tested without the definition | Define once in spec.md:84: "the count is every row with «إنشاء» ticked plus one per such row with the garage flag on, before the exists check (so the user sees the number the front shows); the server rejects > 500 with «الحد الأقصى 500 سطر»" and make the front summary use the same formula | should |
| 16 | BR-6: a non-بيع investment type forces the price to 0; spec.md:69 applies "the same investment type rule" to the garage | V2:64 (BR-6), V2:65 (BR-7 السعر = «سعر الجراج»), V2:87 (AC-5) | A5 «مساحة الجراج 20 وسعره 40,000 ← الجراجات بتتعمل بالقيم دي» holds only when the project has بيع; for an إيجار-only project the garage price becomes 0 by BR-6 and A5 as worded fails. No invariant breaks, but the ADO acceptance line is under-specified | Add to A5: "(project with بيع; for a non-بيع project the garage price is 0 like the unit, BR-6)" | nit |
| 17 | A6: blank «نشاط العقار» → the project's activity; `Pm_Project.ProjectActivityId` is nullable and so is `Pm_Properties.PropertyActivityId` | DB `Pm_Project.sql:13`, `Pm_Properties.sql:13`; CE `Property.cs:110`; CR-125486 decisions Q3 (activity is never derived from the investment type) | A6 reads as if a value always results; a project with no activity yields a null activity on every unit and garage, which is legal and matches the Properties screen, but the A6 test needs both cases | State in spec.md:53 and A6: "null stays null when the project has no activity; never derived from the investment type (CR-125486 Q3)" | nit |
| 18 | «نوع الجراج» defaults to the type named «جراج» / "Garage"; `Pm_ProjectType` has `IsActive` and a second-language name | CE `ProjectType.cs:12-15`; V2:33 (field 15) | A tenant may have an inactive «جراج» type or two types with that name; the default then points at a type the lookup does not list, and the pattern silently holds an id the user cannot see. Undefined whether the match is on `Name` or `NameSecondLanguage` | Spec.md:70: "the lookups show active types; the default is the first active type whose `Name` or `NameSecondLanguage` equals «جراج» / "Garage" (case-insensitive); none → empty and the user picks (required with the option on)" | nit |
| 19 | Currency FK mismatch, pre-existing: `Pm_Project.CurrencyId` → `Acc_Currency`, `Pm_Properties.CurrencyId` → `ACFX_Currency`, and `CreatePropertyCommand` validates against `_generalLedgerContext.Currencies` | DB `Pm_Project.sql:52` vs `Pm_Properties.sql:65`; CE `CreatePropertyCommand.cs:190-192` | Inheriting the project currency puts an `Acc_Currency` id into a column whose FK names `ACFX_Currency`. The Properties screen already does this (the user picks from the GL list), so no new risk; a tenant where the two tables diverge already fails on the screen | No spec change; note it for the engineer in Further Notes as a pre-existing schema inconsistency, out of scope | nit |

## Checked and kept (pass)

- Garage as a child with inherited fields (BR-7): `ParentPropertyId` self-FK (`Pm_Properties.sql:55`); `CreatePropertyCommand` has no same-project rule for a child, so "same project as the unit" is stricter than the screen; serial = `GetNextPropertyCode(main)` → main + `01` (`GetNextCodeService.cs:51-64`); the unit is saved before its garage so the parent Id and serial exist.
- Garage type as a separate tenant lookup (Q5): `PropertyTypeId` → `Pm_ProjectType` NOT NULL FK (`Pm_Properties.sql:11,59`); required when the option is on, so the NOT NULL is satisfied (default handling: row 18).
- Blank-model guard (Q9): `PropertyModelId` nullable in DB and entity; `maybePropertyModels ?? Maybe<PropertyModel>.None` at `CreatePropertyCommand.cs:206` already yields `None`, so the guard only stops the `.Value` throw; the Properties-screen change is now the same decision in both CRs.
- Tenant-wide exists (Q13, A7): single DB per tenant (`accflex-erp-core.md`), no branch column on `Pm_Properties`; a case-insensitive compare on `PropertyNumber` (`Pm_Properties.sql:5`) reaches no other tenant. Best-effort nature stated (spec.md:86).
- Status = project status (Q2): both nullable (`Pm_Project.sql:11`, `Pm_Properties.sql:12`), same `Pm_ProjectStatus` list.
- Investment type (BR-4/BR-6): one id from the project's list; lowest `InvestmentTypeId` is deterministic; price forced to 0 when not بيع is stricter than the screen.
- Required-field coverage (`Property.cs:276-318`): number (code), name / second name (type name + code; non-empty even when the type has no second-language name because the code is present), type, country / governorate / city (from the project, NOT NULL on `Pm_Project.sql:26-28`), currency (request-level check, row 2), ≥ 1 investment type.
- `DeliveryPeriodInDays` NOT NULL int with no DB default (`Pm_Properties.sql:39`): the poco default 0 is written by `Property.Create`; nothing to add.
- One transaction with `SaveChanges` per unit on the single `IPropertyManagerContext`: the serial MAX inside the same transaction sees the batch rows; a UQ clash rolls back everything (spec.md:93).
- Sales organisation per user: request-level on the project's sales org (`CreatePropertyCommand.cs:145-151`); a user not linked cannot generate for that project.
- 500-row limit, 400 ms debounce, module 936, import button on module 935 (Q10, Q11): product choices; no rule touched (definition of the count: row 15).

## Verdict

**pass** with three `should` rows (13, 14, 15) and four `nit` rows the planner can fold into the spec in one pass; no row blocks implementation. Round 3 is not needed unless the planner rejects row 13 or 14; a re-check of those two rows only would then suffice.
