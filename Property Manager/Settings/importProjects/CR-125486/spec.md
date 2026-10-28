---
type: spec
cr: 125486
updated: 2026-10-18
source: "[[importProjects]]"
---

# CR-125486 — Spec: Import projects from Excel

Path taken: the agent grilled itself against [[facts]] and the code (`grill-with-docs` process, no interactive session). It wrote this spec in the `to-spec` shape. The 5 calls marked **(D?)** are recommended answers that wait for the engineer at the plan gate (see [[open-questions]]).

## Problem Statement

A Property Manager customer going live (S4) has many main projects and sub-projects. Today they have to type each one into the Projects screen. They need a bulk add from a fixed Excel template. The import must apply the screen's own rules, show every error per row, and never change an existing project.

## Solution

Add a new screen **استيراد المشاريع / Import Projects** to the property-manager web app, under a new menu group **أدوات المشاريع والعقارات / Projects & Properties Tools**. Module id **934** (next free; the max in `Module.cs` is 933).

- **Front**:
  - Builds the template xlsx: 24 headers in the user's language, in fixed order.
  - Parses the uploaded xlsx with `xlsx`, by **column position**, so headers in either language work.
  - Sends the raw cell strings to the API for review.
  - Shows the summary bar, the row-review grid, the template-columns tab and the import-log tab.
  - Builds the error file: the original columns plus an "Errors" column.
- **Back end** (PropertyManager), one validator shared by two commands:
  - `VerifyProjectImport`: resolves and validates every row and returns per-row status and all of its errors. Nothing is saved.
  - `ImportProjects`: re-runs the same validation on the same rows. It then saves the valid rows in file order inside **one transaction**, creates the auto cost centers, writes one import-log row, and returns N new / K skipped.
  - `GetProjectImportLog`: paginated, newest first.
- **DB**:
  - new table `Pm_ProjectImportLog`
  - the module row 934 in `0002_Acc_Module_Data.sql` (reference data)

## User Stories

1. As a property admin, I want to download the template, so that my file has the right columns in the right order.
2. As a property admin, I want to upload a file and see every row marked "new – valid" or "error – skipped" with all of its errors, so that I can fix the file in one pass.
3. As a property admin, I want only the valid rows imported, in file order, so that a parent on an earlier line exists before its sub-projects.
4. As a property admin, I want an existing project number rejected, so that the import never overwrites data I edited on the screen.
5. As a property admin, I want a cost center created automatically for each leaf project, so that I don't have to create them by hand.
6. As a property admin, I want to download the error rows with an errors column, so that I can fix them and re-upload.
7. As a property admin, I want a log of every import (date, file, user, rows, new, errors), so that I can audit what was loaded.
8. As a property admin, I want an "Open projects" link in the result message.

## Implementation Decisions

### Columns

Template columns, by position (index → field). Required fields are marked *.

| # | Column | Resolves to | Rule |
|---|---|---|---|
| 1 | رقم المشروع* | `ProjectNumber` | not in DB (add-only); not repeated in the file (the error points to the first line) |
| 2 | اسم المشروع* | `ProjectName` | not in DB; not repeated in the file |
| 3 | الاسم بالغة الثانية* | `ProjectNameSecondLanguage` | same |
| 4 | رقم المشروع الرئيسي | `ParentProjectId` | an existing project number, or the number of a **valid** row on an **earlier** line; ≠ own number |
| 5 | ملكية المشروع* | `ProjectOwnership.List` | name ar/en |
| 6 | نوع المشروع* | `Pm_ProjectType` | name ar/en |
| 7 | نوع الإستثمار* | `InvestmentType.List` (static 1–4) | split on `،` / `,`; every part must match |
| 8 | حالة المشروع | `Pm_ProjectStatus` | name ar/en; blank → (D?) |
| 9 | توزيع التكاليف* | `CostDistribution.List` | name ar/en |
| 10 | ادارة المبيعات* | `Lgx_SalesOrganization` | name ar/en **or code**; must be in `UserSalesOrganization` for the current user (same rule as the screen) |
| 11–13 | الدولة* / المحافظة* / المدينة* | `ACFX_Country` / `ACFX_Governorate` / `ACFX_City` | name ar/en (or code if the table has one); governorate.CountryId = country; city.GovernorateId = governorate (**new check**: the screen relies on cascading dropdowns) |
| 14 | المركز | `ACFX_Center` | name ar/en; blank ok |
| 15–16 | الشارع، رقم قطعة الأرض | `Street`, `LandNumber` | free text |
| 17 | المساحة الكلية | `ProjectAreaInMeter` | decimal ≥ 0; blank → 0 (DB default) |
| 18–19 | عدد الطوابق، عدد العقارات | `NoOfFloor`, `NoOfProperties` | integer ≥ 0; blank → DB default 1 |
| 20 | السعر | `ProjectPrice` | decimal ≥ 0; blank → 0 |
| 21 | العملة* | `Acc_Currency` | name ar/en or code |
| 22 | الإطلالة | `Pm_ProjectView` | name ar/en |
| 23 | النشاط | `Pm_ProjectActivities` | name ar/en (D?) |
| 24 | إنشاء مركز تكلفة تلقائياً | bool | `نعم/لا/yes/no`, blank = yes; any other value is an error |

Not in the template: `ProofOfIncomeAndExpenses` (D?), boundaries, dimensions, geo-location, image, license fields, description. These are added later from the Projects screen (answers the second open question in the source note).

### Validation

- **One validator, one place**: `ProjectImportValidator` (Application). It loads every lookup **once** for the whole file, never per row. For each row it:
  - resolves the strings to ids
  - builds the same `ProjectPoco` the create handler builds
  - calls `Project.ValidateProject` through `Project.Create`, so the screen's domain rules apply unchanged
  - adds the import-only rules above
  
  It returns all of a row's errors. `Verify` and `Import` both call it, so the counts match (BR-11).
- **Messages**: new resx keys in `PropertyManager.Logic\Resources` (ar + en + Designer), each naming the column, e.g. «رقم المشروع موجود بالفعل – الاستيراد إضافة بس، والتعديل من الشاشة», «… مش من القيم المسموحة». Existing `ProjectsErrors` keys are reused where they exist (e.g. `ProjectNameSecondLanguageRequired`, `SalesOrganizationNotRelatedToUser`).

### Save

- `IApplicationTransaction` wraps the PropertyManager and GeneralLedger contexts.
- Rows are saved one at a time, in file order. Each project calls `GetNextCodeService.GetNextProjectCode(parent)` exactly as the screen does. `SaveChanges` runs per row, because the generator reads `MAX(ProjectSerial)` from the DB and a child in the file needs its parent's id.
- Any unexpected save failure rolls back the whole import and returns the error. Rows were already proven valid, so this is not a skip.

### Auto cost center

Auto cost center (D?) applies to valid rows with column 24 = yes that no other valid row in the file names as parent.

- It uses the Machine pattern (`CreateMachineCommand.cs:147-180`): the next child number under the parent, then a **parent-type** cost center with both names (Q8; see [[business-check-1]]).
- The new id is stored on `Project.CostCenterId`.
- The **parent cost center** is picked once on the import screen. It is required only when at least one row asks for a cost center.

### Import log

`Pm_ProjectImportLog`:

| Column | Type |
|---|---|
| `ProjectImportLogId` | int identity |
| `ImportDate` | datetime, `IDateTime.Now` |
| `FileName` | nvarchar(500) |
| `UserId` | int |
| `TotalRows` | int |
| `NewRows` | int |
| `ErrorRows` | int |
| `CreatedById` | audit |
| `CreatedOn` | audit |

### API

`api/ProjectImport` (new `ProjectImportController`):

| Action | Route | Policy |
|---|---|---|
| Verify | `POST Verify` | AddPolicy |
| Import | `POST` | AddPolicy |
| Log | `GET Log` (paginated) | ViewPolicy |

- `ModuleId = Module.PropertyManagerProjectImport.ModuleId` (934).
- Additive contract, so `property-manager.api.client` gets a new version.

### Menu

- `WebMenuItem` entry: group "Projects & Properties Tools / أدوات المشاريع والعقارات".
- Front route `project-import`, `data: { ModuleId: 934 }`.

### Limits

Max **1000 rows** and **5 MB** per file (BR-13 leaves this to the product). The front rejects bigger files before upload, and the API rejects more than 1000 rows.

## Testing Decisions

- Unit tests (new, in `PropertyManager.Application.Test`, which has no tests yet) on `ProjectImportValidator`, using an in-memory context/fakes per `test-doubles-and-baselines.md`. They cover:
  - AC-2: existing number
  - AC-3: missing second name
  - AC-4: sales org + governorate, both errors on one row
  - AC-5: «ربما»
  - a duplicate in the file pointing to the first line
  - a parent on a later line → error
  - multi-value split on `،` and `,`
- End to end on a tenant (local API, `local-api-run`), with a test workbook in the vault:
  - AC-1: NRJ + NRJ-A + NRJ-B. The children's serials start with NRJ's serial. Cost centers exist for A and B, not for NRJ.
  - AC-6: one log row with the right counts.
- Gates:
  - `dotnet build PropertyManager.sln` and `dotnet test` on the test project
  - DB MSBuild of the sqlproj
  - `front-verify-build`

## Out of Scope

- Updating existing projects (add-only, decision 12/10).
- Importing properties (العقارات) and boundaries, location, image or license data.
- Adding name/number uniqueness to the Projects screen itself. Today the screen has no such check, and the only unique constraint is `ProjectSerial`. See (D?) 4.
- The desktop (WinForms) app.
- A server-side Excel parser. Parsing stays on the front, like the other import screens.

## Further Notes

- The source says "the same rules as the projects screen", but three of its rules are not on the screen today: name/number uniqueness, the country→governorate→city chain, and activity derived from investment type. The import enforces the first two. Activity is decided in (D?) 3.
- Acceptance list for ADO: A1 = AC-1 … A6 = AC-6 from [[importProjects]], unchanged.
