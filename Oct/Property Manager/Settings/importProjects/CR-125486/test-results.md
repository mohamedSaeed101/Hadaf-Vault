---
type: test-results
cr: 125486
date: 2026-10-18
tenant: db-all / Sabreen_Primary
---

# CR-125486 — End-to-end test results (phase 11)

## Setup

| Item | Value |
|---|---|
| API | PropertyManager.API from `worktrees\cr125486`, Debug, https://localhost:2118. The `DebugTenantConnection` env var points at db-all / Sabreen_Primary. Authority = localbeta |
| Front | `worktrees\cr125486` front on http://localhost:4200, signed in by the engineer, company **Sabreen** (user id 24) |
| Proof that the override took | `sys.dm_exec_sessions` on Sabreen_Primary shows a `Core Microsoft SqlClient Data Provider` session from DESKTOP-KPT7EFB at 20:57:44, the second of the import. The log row and the projects are in db-all / Sabreen_Primary |
| DB changes on the tenant | [[cr125486-sabreen.sql]] adds `Pm_ProjectImportLog` + module 934. The column drop is **not** applied on the shared tenant. A full publish would drop about 40 columns of other branches' work |
| Test reference data | [[cr125486-sabreen-testdata.sql]] adds project types سكني and تجاري, status تحت الإنشاء, activity سكني (id 1), view حديقة, and parent cost center **5 · مراكز تكلفة مشاريع المنطقة الغربية** (id 4, non-leaf). Sabreen had none of these |
| Workbooks | `e2e-1-main.xlsx` (10 rows), `e2e-2-existing.xlsx` (2 rows), `e2e-3-allno.xlsx` (1 row), in this folder |

## Results

| AC | Result | Evidence |
|---|---|---|
| AC-1 NRJ + NRJ-A + NRJ-B | **pass** | All 3 are «جديد – صالح». Serials: NRJ = 1, NRJ-A = **101**, NRJ-B = **102** (built on NRJ's serial). Both children have ParentProjectId = NRJ. NRJ-A and NRJ-B got cost centers 51 and 52; NRJ got none (review column: «لا – رئيسي له فرعية») |
| AC-2 existing number | **pass** | e2e-2 line 2 NRJ gives «رقم المشروع موجود بالفعل – الاستيراد إضافة بس، والتعديل من الشاشة». NRJ is unchanged in the DB |
| AC-3 missing second name | **pass with a wording gap** | Line 6 is rejected with the screen's existing domain message «اسم المشروغ باللغة الانجليزية مطلوب» (`ProjectNameSecondLanguageRequired`, a pre-existing resource with a typo). AC-3 wording is «الاسم بالغة الثانية إلزامي». See Q17 |
| AC-4 sales org not linked + governorate not in the country | **partly verified** | The governorate chain works: line 7 gives «المحافظة «MAKKAH REGION» مش من محافظات الدولة» on the same row as a second error. The sales-org half **cannot be exercised on Sabreen**: user 24 is linked to both sales organizations. It is covered by a unit test (phase 6) |
| AC-5 «ربما» | **pass** | Line 8 gives «إنشاء مركز تكلفة تلقائياً: «ربما» مش من القيم المسموحة» |
| AC-6 cost center requested, no parent | **pass** | The warning «فيه 2 مشروع طالب مركز تكلفة – اختار «مركز التكلفة الأب» علشان تقدر تستورد» shows and the import button is disabled |
| AC-7 parent 5, NRJ + children | **pass** | Two new cost centers under «5»: **51 نرجس A / Narjis A** and **52 نرجس B / Narjis B**. Both are non-leaf (IsLastNode = 0), level 1, linked to NRJ-A and NRJ-B. The log shows «2 – 5 · مراكز تكلفة مشاريع المنطقة الغربية» |
| AC-8 all «لا», no parent | **pass** | e2e-3 imports with no parent chosen: «تم الاستيراد: 1 جديد، 0 صف اتخطى · مراكز تكلفة جديدة: 0» |
| AC-9 no «اثبات الإيراد» | **pass (code)** | No template column. The Projects form has no radio, and the API contract has no field. On Sabreen the column still exists (not dropped there) and holds its default |
| AC-10 parent list has no leaf / no-transactions cost centers | **not verified in the UI (environment)** | The list comes from the **remote** Stage Beta GL (`glapi.localbeta…/ActiveCostCenter`), which returns **400 "unexpected error"** for Sabreen, so the dropdown was empty. The parent was set via the component. The API's server-side parent check ran and passed |
| AC-11 NRJ-A cost center selected on the Projects screen | **verified in the DB only** | NRJ-A.CostCenterId = 5 (non-leaf «51»). The Projects screen's cost center dropdown uses the same broken remote GL list, so the selected value could not be shown |
| AC-12 status | **pass** | NRJ-A status = تحت الإنشاء (id 1). NRJ-B blank → NULL. Line 9 «مجهول» gives «حالة المشروع: «مجهول» مش من القيم المسموحة» |
| AC-13 activity by id | **pass** | NRJ and NRJ-A activity = 1. NRJ-B blank → NULL, even with بيع,إيجار. Line 9 id 99 gives «النشاط: «99» مش من القيم المسموحة» |
| AC-14 log | **pass** | DB row: file, user 24, rows 10, new 4, errors 6, new cost centers 2, parent 4. Log tab: newest first, user name "Marey", both imports |
| BR-3 duplicate in file | **pass** | Line 5 gives «رقم المشروع «NRJ-A» مكرر في الملف – أول ظهور في السطر 3» |
| BR-4 name uniqueness | **pass** | e2e-2 line 3 shows both «اسم المشروع موجود بالفعل» and «اسم المشروع باللغة الثانية موجود بالفعل» |
| BR-5 parent on a later line | **pass** | Line 10 (parent ZZZ on line 11) is rejected; line 11 itself is valid |
| BR-2 `،` and `,` split | **pass** | NRJ (`بيع، إيجار`) and NRJ-B (`بيع,إيجار`) both have investment types 1 and 2 |
| BR-10 file order, result message, file cleared | **pass** | «تم الاستيراد: 4 جديد، 6 صف اتخطى · مراكز تكلفة جديدة: 2» with «فتح المشاريع». The file and the review grid are cleared |

## Findings

1. **Q16: المركز (Center) is text in v3 but a lookup in the model.** v3 lists المركز as optional free text, but `Pm_Project` has only `CenterId` (FK `ACFX_Center`), and the import resolves it by name. A free-text center such as «حي النرجس» is rejected unless it exists in `ACFX_Center`.
2. **Q17: AC-3 wording.** Line 6 shows the screen's existing domain message (with its typo) instead of v3's «الاسم بالغة الثانية إلزامي».
3. **Environment, not this CR:** the Stage Beta GL `ActiveCostCenter` returns 400 for Sabreen, so the parent cost center dropdown (and the Projects screen's cost center list) is empty locally. Re-check AC-10 and AC-11 on Stage Beta after deploy.
4. **Test data, not code:** the first import attempt failed with `SqlNullValueException` because the hand-inserted cost center «5» had `CreatedDate` NULL. App-created cost centers always set it. The row was fixed and the import passed.
5. Cosmetic, probably pre-existing: the top header draws «Sabreen» over the page title «استيراد المشاريع». Not checked against other screens.
