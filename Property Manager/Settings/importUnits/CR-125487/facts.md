---
type: facts
cr: 125487
updated: 2026-10-18
---

# CR-125487 — Facts: Import properties (units) from Excel

Source of truth: [[importUnits]] (`Oct\Property Manager\Settings\importUnits\importUnits.md`, written by the engineer). The ADO work item was created from it on 2026-10-18 by the agent at the engineer's request, so it holds no extra facts and has no attachments. Sibling: CR-125486 import projects (`..\..\importProjects\CR-125486\`).

| # | Fact | Source |
|---|---|---|
| F1 | New screen `set.importUnits`: Property settings › Projects & properties tools › Import properties. It is an addition to the module (S5). | importUnits.md §header, §الوصول |
| F2 | Flow: download the template, upload the xlsx, review every row, then import the valid rows only. After the import, an «فتح العقارات» button in the result message. | §الهدف, §الوصول |
| F3 | **Add only**: an existing property number is an error; existing properties are never changed by the import (decision 12/10). A number repeated in the file is an error that points to the first line. | BR-3 |
| F4 | The template has 21 columns in a fixed order, headers in row 1 (the note's §الحقول rows 2–22; row 1 is the file itself). | §الحقول |
| F5 | Required: number, name, second-language name, project number, property type, investment type, total area (> 0). Sale price is required (> 0) when the investment type is sale; annual rent is required (> 0) when it is rent. | §الحقول, BR-6 |
| F6 | Every row is validated on its own with the property screen's rules; all of a row's errors are shown at once. | BR-1 |
| F7 | Lookups are matched by name (Arabic or English) or by code; a value not found → «… مش من القيم المسموحة». A multi-value cell is split on `،` or `,`. | BR-2 |
| F8 | Name and second-language name must be unique, against the DB and within the file (same rule as the screen). | BR-4 |
| F9 | The project must exist and have no sub-projects («… له مشاريع فرعية – العقار يتسجل على المشروع الفرعي»). The property inherits from the project, as on the screen: ownership, sales department, cost center, geography, currency; and activity and status when their cells are blank. | BR-5 |
| F10 | The investment type must be one of the project's investment types («… مش من أنواع المشروع (…)»). Rent → the annual rent is saved in the rent prices: annual, and monthly = annual ÷ 12 × 1.05. | BR-6 |
| F11 | The parent property must be an existing property in the same project, or one on an earlier line of the file for the same project. | BR-7 |
| F12 | pcode is generated as on the screen; status «متاح»; an event in the property's history: «تم إنشاء العقار بالاستيراد من Excel – <file name>». | BR-8 |
| F13 | The import runs in file order (so a parent on an earlier line is created first) and skips error rows. It then shows «تم الاستيراد: N جديد، K صف اتخطى», writes an import-log row and clears the file. | BR-9 |
| F14 | Validation is computed once before save; the log's error count equals the file's error count. | BR-10 |
| F15 | The error file is the same file plus an "errors" column for the skipped rows. | BR-11 |
| F16 | The import is one server operation using the screen's validation. Row and size limits are for the product to set. | BR-12 |
| F17 | Screen layout: "addition" note, 4-step bar, last-result message, file group (add-only line + file area), summary bar (file rows, new – valid, errors – skipped), buttons «استيراد الصفوف الصالحة (N)» (disabled when N = 0) and «تحميل ملف الأخطاء» (shown when there are errors), 3 tabs (row review, template columns, import log). «تحميل القالب (Excel)» at the top. | §ترتيب الشاشة, §الأزرار |
| F18 | Row-review grid: line (header = line 1), status (filterable; error rows highlighted), the main file columns, all errors as a list. Import log: date, file, user, rows, new, errors; newest first. | §أعمدة القائمة |
| F19 | Acceptance criteria AC-1 … AC-8. | §معايير القبول |
| F20 | Open questions: the owner of properties in a project «لمالكين آخرين» is not a template column; gas meter, license number and construction date are not in the template. | §أسئلة مفتوحة |

Implied repos: AccFlex_Cloud_ERP (PropertyManager), AccFlex_Cloud_Front (property-manager), AccFlex_Cloud_Database (import-log table + menu/permission seed). Same three as CR-125486.
