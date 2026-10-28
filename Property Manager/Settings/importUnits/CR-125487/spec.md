---
type: spec
cr: 125487
updated: 2026-10-18
source: "[[importUnits v2]]"
---

# CR-125487 — Spec: Import properties (units) from Excel

Path taken: the agent grilled itself against [[facts]] and the code (`grill-with-docs` process, no interactive session), using two code scouts on the `cr125487` set. It wrote this spec in the `to-spec` shape. The calls marked **(Q<n>)** are recommended answers that wait for the engineer at the plan gate (see [[open-questions]]). The plan already uses them.

## Problem Statement

A Property Manager customer going live (S5) has many properties (apartments, villas, shops, stores …) across their projects. Today each one is typed into the Properties screen. They need a bulk add from a fixed Excel template. The import must apply the screen's rules, show every error per row, and never change an existing property.

## Solution

A new screen **استيراد العقارات / Import Properties** in the property-manager web app. It sits in the menu group **أدوات المشاريع والعقارات / Projects & Properties Tools** that CR-125486 also uses. Module id **935** (Q9).

- **Front** (copies the CR-125486 screen shape):
  - builds the template xlsx: the headers in the user's language, in fixed order
  - parses the upload with `xlsx`, by **column position**
  - sends the raw cell strings to the API
  - shows the summary bar, the row-review grid, the template-columns tab and the import-log tab
  - builds the error file
- **Back end** (PropertyManager): one validator shared by two commands.
  - `VerifyPropertyImport`: validates every row and returns its status and all of its errors. Nothing is saved.
  - `ImportProperties`: re-runs the same validation, then saves the valid rows in file order inside **one transaction**. It writes one import-log row and returns N new / K skipped.
  - `GetPropertyImportLog`: paginated, newest first.
- **DB**:
  - new table `Pm_PropertyImportLog`
  - module row 935 in `0002_Acc_Module_Data.sql`

## User Stories

1. As a property admin, I want to download the template, so that my file has the right columns in the right order.
2. As a property admin, I want each row marked "new – valid" or "error – skipped" with all of its errors, so that I can fix the file in one pass.
3. As a property admin, I want only valid rows imported, in file order, so that a parent property on an earlier line exists before its children (AC-7).
4. As a property admin, I want an existing property number rejected, so that the import never overwrites a property edited on the screen (AC-2).
5. As a property admin, I want a property to take its ownership, sales department, cost center, geography and currency from its project, so that I don't repeat them in the file.
6. As a property admin, I want a project that has sub-projects rejected, so that properties land on the leaf project (AC-3).
7. As a property admin, I want to download the error rows with an errors column, so that I can fix them and re-upload.
8. As a property admin, I want a log of every import (date, file, user, rows, new, errors) (AC-1).
9. As a property admin, I want an "Open properties" link in the result message.

## Implementation Decisions

### What the code has today (from the scouts, verified on `cr125487`)

- **Create path:** `CreatePropertyCommand.cs` builds a `PropertyPoco` (l.195-247) and calls `Property.Create` (l.250).
  - The domain rules are in `Property.ValidateProperties` (`Property.cs:270-324`): number, name, second name, type, country, governorate, city, currency, at least one investment type, a closed polygon.
  - The handler checks: the project exists, the ownership is in the list, ProofOfIncome exists, the sales org exists **and is linked to the user**.
- **Inheritance from the project is front-only.** `property-main-form.component.ts:89-117` (`onProjectChanged`) patches these fields:
  - ownership, country, governorate, city, center
  - type, status, sales org, cost center
  - activity, view, ProofOfIncome, street, land number
  - investment types

  Currency is **not** copied; the user picks it. The backend copies nothing.
- **pcode:** `GetNextCodeService.GetNextPropertyCode(parent)` reads `MAX(PropertySerial)` from the DB on every call. Child = parent serial + a 2-digit counter. `UQ_Pm_Properties_PropertySerial` is the only unique constraint on the table.
- **No uniqueness** on number, name or second name, in code or DB (Q7).
- **Does not exist in the cloud:**
  - rent prices (Q1)
  - a property history / timeline (Q2)
  - an availability status «متاح» (Q3)
  - a "building" field (Q4)
- **Lookups:**
  - the property type uses `Pm_ProjectType`, the status `Pm_ProjectStatus`, the activity `Pm_ProjectActivities` and the view `Pm_ProjectView`; all four are shared with projects
  - the model uses `Pm_PropertyModel`
  - the investment type is the static `InvestmentType` list (1 بيع, 2 إيجار, 3 إدارة, 4 خارج الخدمة)
  - the project's investment types are in `Pm_ProjectInvestmentType`
- **Meter numbers are `INT` columns** (Q5).

### Columns

Template columns, by position. `*` = required. The numbering follows the source note's §الحقول rows 2–22, with Q1 and Q4 applied.

| # | Column | Resolves to | Rule |
|---|---|---|---|
| 1 | رقم العقار* | `PropertyNumber` | not in DB (add-only, AC-2); not repeated in the file (the error names the first line, AC-6) |
| 2 | اسم العقار* | `PropertyName` | not in DB; not repeated in the file (Q7) |
| 3 | الاسم باللغة الثانية* | `PropertyNameSecondLanguage` | same |
| 4 | رقم المشروع* | `ProjectId` | an existing project number; the project has **no sub-projects** (`Projects.Any(p => p.ParentProjectId == id)`) (AC-3) |
| 5 | رقم العقار الرئيسي | `ParentPropertyId` | an existing property **in the same project**, or a **valid** row on an **earlier** line with the same project; ≠ own number (AC-7) |
| 6 | نوع العقار* | `PropertyTypeId` (`Pm_ProjectType`) | name ar/en |
| 7 | نوع الإستثمار* | `PropertyInvestmentTypeIdList` = [one id] | name ar/en from `InvestmentType.List`; must be one of the project's `ProjectInvestmentTypeList` (AC-4) |
| 8 | نشاط العقار | `PropertyActivityId` | name ar/en; blank → the project's activity |
| 9 | حالة العقار | `PropertyStatusId` (`Pm_ProjectStatus`) | name ar/en; blank → the project's status (Q3) |
| 10 | الدور | `NoOfFloor` | integer; blank → 0 |
| 11 | عدد الغرف | `NoOfRoom` | integer ≥ 0; blank → 0 |
| 12 | نموذج العقار | `PropertyModelId` (`Pm_PropertyModel`) | name ar/en (Q6); blank → none, which needs the one-line guard in Q12 |
| 13 | المساحة الكلية للعقار* | `PropertyAreaInMeter` | decimal > 0 |
| 14 | مساحة المبنى | `BuildingAreaInMeter` | decimal ≥ 0; blank → 0 |
| 15 | المساحة الخارجية | `OutdoorAreaInMeter` | decimal ≥ 0; blank → 0 |
| 16 | سعر البيع | `PropertyPrice` | decimal; required and > 0 when the type is بيع (AC-5); otherwise ≥ 0, blank → 0 |
| 17 | اطلالة العقار | `PropertyViewId` (`Pm_ProjectView`) | name ar/en; blank → the project's view (the screen copies it) |
| 18 | رقم عداد الكهرباء | `ElectricityMeterNumber` | integer (Q5) |
| 19 | رقم عداد المياه | `WaterMeterNumber` | integer (Q5) |

Not in this CR ([[decisions]], v2): الإيجار السنوي (Q1, comes back with the rent-prices CR) and المبنى (Q4). The meter columns accept integers ≤ 2,147,483,647 only (AC-9).

Taken from the project, never from the file, on the server (Q8):

- `PropertyOwnershipId`, `SalesOrganizationId`, `CostCenterId`, `CurrencyId`
- `CountryId`, `GovernorateId`, `CityId`, `CenterId`, `Street`, `LandNumber`
- `Pm_Project.CurrencyId` is nullable, while a property's currency is NOT NULL. A project with no currency makes the row an error: «المشروع … مالوش عملة» (CR-125488 business check row 2).
- «اثبات الإيراد» is **not** copied: this CR removes it from the property (Q13, below).

### Remove «اثبات الإيراد» from the property (Q13, decision 18/10)

The removal is split between the two CRs:
- **This CR:** the property side.
- **CR-125486:** the project side (`Pm_Project.ProofOfIncomeAndExpenses`, `Project`, `ProjectDto`, `ProjectInfoDto`, the Projects form).

The `Pm_ProofOfIncomeAndExpenses` lookup table, its entity and its reference-data script stay.

- **DB (Q14):** `Pm_Properties.ProofOfIncomeAndExpensesId` becomes `INT NULL`, and `FK_Pm_Properties_Pm_ProofOfIncomeAndExpenses` is dropped, in the table file (SSDT, no DDL in scripts). The column itself is dropped in a later release with an approved data-loss deploy. Grep views, TVFs and procs for the column. It is a destructive change: values are lost on every tenant, which the engineer accepted in CR-125486 Q11. A dacpac publish with `BlockOnPossibleDataLoss` stops on it, so phase 1 checks how the stage profile applies it, as CR-125486 does.
- **Back end:** remove the field from `Property`, `PropertyPoco`, `CreatePropertyCommand` and the update command (including the l.128 existence check), `PropertyDto`, the property GetById / list queries and the EF mapping. Drop `PropertiesErrors.ProofOfIncomeAndExpensesNotFound` if it ends up unused.
- **Front:** remove the radio and the form control from the Properties form (`property-main-form` html:395, ts:106; `properties.service.ts:154`). `onProjectChanged` stops patching it.
- **Coordination (business check 2, row 11):**
  - CR-125486's plan rows 1, 2 and 9 must drop their property-side parts; its decisions.md records the split.
  - CR-125488 (bulk units) still inherits `ProofOfIncomeAndExpensesId` in its spec (`spec.md:61`). If 125487 lands first, 125488 must drop that line.
  - Whichever branch lands second resolves `ProjectInfoDto` / `onProjectChanged` by hand.

Other fields are fixed:

- `DeliveryPeriodInDays` = 0 and a new `GuidNumber`, the same as the screen
- no boundaries, location, image, gas meter or license fields

### Validation

- **One validator**, `PropertyImportValidator` (Application). Projects are loaded as a **projection** (`int? CurrencyId` and the other inherited fields), never as `Project` entities, because `Project.CurrencyId` is a non-nullable `int` over a NULL column and EF would throw on a project with no currency (business check 2, row 9). It loads every lookup **once** per file: projects with their investment types and a has-children flag, existing property numbers, names and parents, and the lookup tables. For each row it:
  - resolves the strings to ids
  - copies the project fields
  - builds the same `PropertyPoco` the create handler builds
  - calls `Property.Create`, so `ValidateProperties` applies unchanged
  - re-runs the handler's checks: ownership in the list, the project's sales org is linked to the current user (an error row if not)
  - adds the import-only rules in the Columns table

  It returns every error of the row. `Verify` and `Import` both call it, so the counts match (BR-10).
- **Number matching (business check rows 2–3):** `ProjectNumber` and `PropertyNumber` carry no unique constraint, so a project or parent number that matches more than one row is a row error («رقم المشروع … مكرر في النظام»). The import never picks one.
- **Cost center (business check row 4):** the project's `CostCenterId` is copied as it is. The Properties screen lists only parent-type cost centers, and CR-125486 Q8 already makes its auto cost centers parent-type, so the two agree.
- **Lookup matching:** trim, case-insensitive, Arabic-normalised (أ/إ/آ → ا, ة → ه, ى → ي), against the Arabic name, the English name, or the code where one exists. Two matches → «… قيمة غير محددة (أكثر من تطابق)». No match → «… مش من القيم المسموحة» (BR-2).
- **Messages:** new resx keys in `PropertyManager.Logic\Resources` (ar + en + Designer), each naming the column and the line. Existing keys are reused where they exist.

### Save

- One transaction. Rows are saved one at a time in file order. Each calls `GetNextCodeService.GetNextPropertyCode(parent)` as the screen does, then `SaveChanges`: the generator reads MAX from the DB, and a child in the file needs its parent's id and serial.
- An unexpected save failure rolls back the whole import and returns the error. Rows were already proven valid, so this is not a skip.
- **Blank model (business check row 1, Q12):** `Property.cs:119` (Create) and `:220` (Update) read `maybePropertyModel.Value` without a guard, so a property with no model throws. Today the screen hits the same throw. The fix is one line each, `HasValue ? Value.Id : null`, in the same way as the status, activity and view lines next to them. It is in scope because the import depends on it.
- **Checked in phase 5:** `Property.Create` stores investment types against the property, so the import is fine. The wrong line (`PropertyId = maybeProject.Value.Id`, ~l.200) is in `Property.Update`. A separate session checked it on EF Core 8.0.8: EF overwrites the value with the property's id before saving, so it is **harmless**. No ticket. Original note: `Property.cs:200` sets `PropertyInvestmentType.PropertyId = maybeProject.Value.Id` (project id, not property id). The screen works today, probably because EF fixes the FK on add. The import uses the same path, so phase 5 asserts the saved rows point at the property.

### Import log

`Pm_PropertyImportLog` is a separate table from CR-125486's `Pm_ProjectImportLog` (Q9), so neither branch depends on the other.

| Column | Type |
|---|---|
| `PropertyImportLogId` | int identity |
| `ImportDate` | datetime, `IDateTime.Now` |
| `FileName` | nvarchar(500) |
| `UserId` | int |
| `TotalRows` | int |
| `NewRows` | int |
| `ErrorRows` | int |
| audit columns | as the house pattern |

### API

`api/PropertyImport` (new `PropertyImportController`):

| Action | Route | Policy |
|---|---|---|
| Verify | `POST Verify` | AddPolicy |
| Import | `POST` | AddPolicy |
| Log | `GET Log` (paginated) | ViewPolicy |

- `ModuleId = Module.PropertyManagerPropertyImport.ModuleId` (935).
- The contract change is **breaking for properties** (Q13 removes `ProofOfIncomeAndExpensesId` from the Create/Update Property commands and `PropertyDto`) and additive for the import. Its only consumer is the Properties form, which phase 8 changes, so the client pin bump and the front ship together (Merge Desk ticket: contract change on; business check 2, row 10).

### Menu

- Module row 935: `"Property Manager Property Import", "Projects & Properties Tools", "استيراد العقارات", "أدوات المشاريع والعقارات", 14, 67`.
- `WebMenuItem` entry → route `property-import`.
- Front route `property-import`, `data: { ModuleId: 935 }`.
- «فتح العقارات» goes to `/apps/:companyID/property-manager/Properties` (module 851).

### Limits

Max **1000 rows** and **5 MB** per file (Q10), the same as CR-125486.

## Testing Decisions

- **Unit tests** on `PropertyImportValidator` in `PropertyManager.Application.Test`, with fakes per `test-doubles-and-baselines.md`:
  - AC-2: an existing number
  - AC-3: a project with sub-projects
  - AC-4: بيع on a rent-only project
  - AC-5: بيع with no price
  - AC-6: a duplicate in the file names the first line
  - AC-7: a parent on an earlier line is valid; on a later line, or in another project, it is an error
  - all of a row's errors returned together
  - blank activity / status / view → the project's values
  - Arabic-normalised lookup match and the ambiguous match
  - AC-9: a meter cell `30A15`, or one above the INT limit → «رقم عداد الكهرباء لازم يكون رقم صحيح»
  - AC-10: a blank model saves with no model; an unknown model → «… مش من القيم المسموحة»
  - a project with no currency → row error
- **End to end** on a tenant (`local-api-run`, PropertyManager on base port + 800):
  - test workbook `CR-125487 - Test Import.xlsx` in this folder
  - AC-1: 10 rows → 4 new, 6 skipped, and a log row 4 / 6
  - AC-7: the child's `ParentPropertyId` and serial prefix
  - AC-8: `PropertyStatusId` = the row's or the project's; the log row has the file, the user and the counts
  - the Properties screen still creates and edits a property with no «اثبات الإيراد» control (Q13)
  - SQL proof in `test-results.md`
- **Gates:**
  - `dotnet build PropertyManager.sln` and `dotnet test` on the test project
  - DB MSBuild of the sqlproj
  - `front-verify-build`

## Out of Scope

- Updating existing properties (add-only, decision 12/10).
- Rent prices, property history and availability status (Q1–Q3, [[decisions]]). Each comes with its own CR.
- The project side of the «اثبات الإيراد» removal (CR-125486).
- An owner per property for «لمالكين آخرين» projects, gas meter, license number / date, construction date (the note's open questions; added later from the screen).
- Adding uniqueness checks or project inheritance to the Properties screen itself (Q7, Q8).
- The desktop app. A server-side Excel parser.

## Further Notes

- AC-8 is as rewritten in [[importUnits v2]]. AC-9 and AC-10 are new in v2.
- The screen hard-codes country 65 / governorate 1 / city 1 on create (`properties.service.ts:361-364`, "removed when complete screen UI next sprint"). The import takes the project's values instead. That bug on the screen is out of scope; it is reported, not fixed here.
- Acceptance list for ADO: A1 = AC-1 … A10 = AC-10 from [[importUnits v2]].
