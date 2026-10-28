# CR-125759 test results

## Unit tests (phases 1–4)
PropertyManager.Application.Test, filters ProjectImport / PropertyImport / ImportLookup / ImportText / CityCreate: 77/77 (project side) and 40/40 (property side), 0 failed. Front `npm run testing`: 0 errors (baseline 0).

## End to end, Sabreen (2026-10-22)
Local PM API from the set (https://localhost:2818, Debug, Application Name=cr125759-e2e) against db-all/Sabreen_Primary; this set's `npm run testing` dist served on localhost:4200 (the engineer's other ng serve on 4200 was stopped at their request). Files: e2e-projects.xlsx, e2e-projects-cc.xlsx, e2e-properties.xlsx (this folder).

| # | Result | Evidence |
|---|---|---|
| A1 | pass | Choosing the file imported at once: projects «3 جديد، 1 صف اتخطى», properties «2 جديد، 1 صف اتخطى»; 3 steps, no verify / confirm |
| A2 | pass (download not clicked) | Skipped row 4 T759-C shown with «الدولة: «Narnia» مش من القيم المسموحة»; properties row 4 T759-P3 with «رقم المشروع: «NOPE»…»; error-file button present |
| A3 | pass | T759-A city «حي 759 أ» created under RIYADH REGION (CityId 128) |
| A4 | pass | T759-B: governorate «منطقة 759» (id 18, country 193) → city «مدينة 759» (129) → center «مركز 759» (21) |
| A5 | pass | T759-C (country Narnia) not saved |
| A6 | pass | «تجربة 759» / «تجربه 759» → one type; «نموذج 759» / «نَموذج 759» → one model shared by P1 and P2 |
| A7 | pass | New project type Serial 3 (max 2 + 1), IsActive 1, both names = cell; property type Serial 4; model Serial 1 |
| A8 | pass | «نوع خطأ 759» and «نموذج خطأ» not created |
| A9 | pass | Property model created in Pm_PropertyModel; status / view / activity / type created in the shared Pm_Project* tables and used by T759-P1 |
| A10 | pass | «تم إنشاؤه» grouped by field with counts and names on both screens; absent after the failed cost-center import |
| A11 | not verified E2E | Unit tests only (no commit + dispose on a failed save); a forced DB failure was not staged |
| A12 | pass | e2e-projects-cc.xlsx: 400 from api/ProjectImport, toast «فيه 1 مشروع طالب مركز تكلفة – اختار مركز التكلفة الرئيسي…», T759-E not saved |
| A13 | pass | T759-D: city «RIYADH» created under MAKKAH REGION (CityId 130); RIYADH under RIYADH REGION untouched |

## Teardown: done 2026-10-22
Run by the agent on the engineer's explicit approval (after the permission check first refused it). Counts back to baseline: projects 17, govs 16, cities 127, centers 20, types 2, statuses 1, views 1, activities 1, models 0, project logs 6.

Originally: Script for the engineer: `teardown-sabreen-759.sql` (this folder; one transaction, prints row counts, ends with counts to compare with the baseline: projects 17, govs 16, cities 127, centers 20, types 2, statuses 1, views 1, activities 1, models 0, project logs 6).
Rows left on Sabreen: projects T759-A/B/D (+6 investment-type rows), properties T759-P1/P2 (+2), types «تجربة 759» «عقار 759», statuses / views / activities «…759» (2 each), model «نموذج 759», governorate «منطقة 759», cities «حي 759 أ» «مدينة 759» «RIYADH» (under MAKKAH REGION), center «مركز 759», 1 project and 1 property import log row.

## Retest after review and cleanup (2026-10-22, evening)
Same setup and files, rebuilt API and front from the current working trees.
- Projects: 3 new, 1 skipped; «تم إنشاؤه» identical to the first run (1 type, status, view, activity, governorate, 3 cities incl. RIYADH under MAKKAH, center); skipped grid has no status column (review rows 4/8). A1 A3 A4 A5 A6 A7 A8 A10 A13 pass.
- A2 now verified on both screens: the error-file button generates «أخطاء استيراد المشاريع.xlsx» (7,202 bytes) and «e2e-properties-أخطاء.xlsx» (6,942 bytes); captured in the page, not saved to disk.
- A12: cost-center file → toast «فيه 1 مشروع طالب مركز تكلفة…», nothing saved, and the previous file's skipped rows / «تم إنشاؤه» are cleared (review row 2 confirmed).
- Properties: 2 new, 1 skipped; created type, status, view, activity, one model (tashkeel variant merged); steps read «رفع الملف والاستيراد» / «مراجعة النتيجة». A6 A8 A9 pass.
- DB: 3 T759 projects, 2 properties, type Serials 3 and 4, 1 model, 1 governorate, 3 cities, 1 center, no «خطأ» type, no T759-E.
- Not covered E2E: A11 (rollback), Q10 digit-only cells (unit tests), properties failed-import clearing (code + review).
- Teardown of the retest data: done on the engineer's approval; counts back to baseline (17 / 16 / 127 / 20 / 2 / 1 / 1 / 1 / 0 / 6).
