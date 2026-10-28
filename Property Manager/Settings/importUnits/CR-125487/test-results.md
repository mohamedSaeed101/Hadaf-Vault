---
type: test-results
cr: 125487
date: 2026-10-18
phase: 9 (end to end)
---

# CR-125487 — Phase 9 end-to-end results

## Setup

- **Tenant:** `db-all` / `Sabreen_Primary`, company **Sabreen** (the engineer's choice). It is the only `db-all` tenant with Property Manager data: 13 projects, 0 properties before the run.
- **Schema:** applied as a cut-down script, not a full dacpac. The full `publish-db.ps1 -Script` would have dropped dozens of other branches' columns on the shared tenant. The script (scratchpad `cr125487-sabreen-schema.sql`) did four things:
  - drop `FK_Pm_Properties_Pm_ProofOfIncomeAndExpenses`
  - make `ProofOfIncomeAndExpensesId` `INT NULL`
  - create `Pm_PropertyImportLog`
  - insert `Acc_Module` row 935
- **API:** PropertyManager from the set (Debug), on `https://localhost:2218` (base + 800). It ran in Development with `Authority` = `accesscontrol.localbeta` and the tenant override (`DebugTenantConnection`) set as a process variable only.
- **Front:** the set's front on `localhost:4200`, with local-only `config.json` edits (Property Manager → local API; miscapi and dashboard → localbeta). The edits were restored afterwards.
- **Override proof:** `sys.dm_exec_sessions` on db-all showed `Sabreen_Primary | cr125487-pm-local | DESKTOP-KPT7EFB | 2026-10-18 23:23:06`.
- **Workbooks** (in this folder, built with the front's own `xlsx` package):
  - `CR-125487 - Test Import.xlsx`: 10 rows
  - `CR-125487 - Test Import 2 (AC-2).xlsx`: 2 rows
- **Loading the file:** the real `.xlsx` bytes were set on the screen's file input (DataTransfer + change event), so the screen's own parse → Verify → Import path ran.

## Results

| AC | Case | Result | Evidence |
|---|---|---|---|
| AC-1 | 10 rows: 4 valid, 6 errors | **pass** | Summary «صفوف الملف: 10 · جديد – صالح: 4 · أخطاء – هتتخطى: 6»; «استيراد الصفوف الصالحة (4)». After import: «تم الاستيراد: 4 جديد، 6 صف اتخطى». `Pm_PropertyImportLog` row 1: file `CR-125487 - Test Import.xlsx`, user 24, 10 / 4 / 6. The import-log tab shows the same (user Marey). |
| AC-2 | number already exists | **pass** | File 2, line 2: «رقم العقار «T125487-01» موجود بالفعل – الاستيراد إضافة بس، والتعديل من الشاشة». The valid line 3 was not imported. |
| AC-3 | project with sub-projects (NRJ) | **pass** | «المشروع «NRJ» له مشاريع فرعية – العقار يتسجل على المشروع الفرعي» |
| AC-4 | investment type not in the project's types | **pass** | Sabreen has no rent-only project, so the same rule was tested with إدارة on NRJ-B (sale + rent): «نوع الإستثمار «إدارة» مش من أنواع المشروع (بيع، إيجار)» |
| AC-5 | sale without price | **pass** | «سعر البيع إلزامي لعقار بيع وأكبر من صفر» |
| AC-6 | number repeated in the file | **pass** | Line 9: «رقم العقار «T125487-01» مكرر في الملف – أول ظهور في سطر 2» |
| AC-7 | parent on an earlier line | **pass** | `T125487-02.ParentPropertyId` = `T125487-01`; serial `101` = parent serial `1` + `01` |
| AC-8 | status from the row or the project; the log names the file | **pass** | Line 2 status blank → 1 (NRJ-A's); line 3 explicit 1; ZZZ / QDS blank → NULL (project NULL). The log row has the file and the user. |
| AC-9 | meter `30A15` | **pass** | «رقم عداد الكهرباء لازم يكون رقم صحيح». Valid meters saved: 12345 / 678. |
| AC-10 | blank model / unknown model | **pass** | Blank → `PropertyModelId` NULL on all 4 saved rows. «A2» → «نموذج العقار: «A2» مش من القيم المسموحة». |

**Also verified (SQL on Sabreen):**
- **Inherited from the project:** ownership 1, sales org 1, cost center (NRJ-A → 5, ZZZ → NULL), currency 1, country / governorate / city 193 / 2 / 2.
- **Activity and view:** a blank cell takes the project's value; «حديقة» → view 1.
- **Q13:** `ProofOfIncomeAndExpensesId` is NULL on every new row.
- **Investment types:** `Pm_PropertyInvestmentType` rows point at their own property (1@1, 2@2, 1@3, 2@4).
- **Lookup matching:** the English name «Commercial» matched type 2; the Arabic-normalised «ايجار» matched إيجار.
- **Screen:**
  - RTL layout, step bar, summary, badges, highlighted error rows with messages
  - after the import, the review grid and «تحميل ملف الأخطاء» stay (review row 1), and the import button drops to (0)
  - the route guard passes for module 935

## Not covered

- **A project with a NULL `CurrencyId`.** Every Sabreen project has currency 1. The EF scalar-subquery projection (business check 2 row 9; review row 4 / backend #5) is still unproven against SQL. Proving it means setting one test project's currency to NULL on db-all for a minute and then restoring it, which needs the engineer's OK.
- **Rollback on an unexpected save failure** (no fault injection).
- **Template and error-file downloads.** The browser pane has no download check. Both are built with exceljs; `npm run testing` compiles them.
- **The 1000-row / 5 MB guards in the UI** (Q16 is proven separately by the Node check), and **a 403 for a user without module 935**.

## Environment note (not a defect)

«فتح العقارات» routes to `/apps/Sabreen/property-manager/Properties`: the Properties screen's own API calls (`Project/GetAll`, `Property/GetAll`, the lookups) hit the local API with 200. The tab then left for `https://localbeta.hadaf.website`. Opening Properties **directly** on localhost does the same, so the cause is the existing Properties screen in this mixed local session (other module APIs still pointed at localstable), not the import screen.

## Data left on Sabreen_Primary

- Properties `T125487-01` … `T125487-04` (PropertyId 1–4), from the test
- `T125487-21` … `-23`, from the demo video's import
- `Pm_PropertyImportLog` rows 1 (test, 10 / 4 / 6) and 2 (video, 6 / 3 / 3)
- The CR's schema: log table, nullable column, no FK, module 935

They stay as test data; remove them only on the engineer's word.

## Explainer video

`demo_125487_import-units_Iapetus.mp4` (1:46, Hanafi's voice + captions), recorded on Sabreen with the demo workbook (6 rows: 3 valid, 3 errors). Its 8 segments: the screen, the template columns, the upload summary, the error rows, the error file, the import result, the import log, the summary.
