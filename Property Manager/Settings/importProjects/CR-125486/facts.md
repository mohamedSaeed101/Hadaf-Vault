---
type: facts
cr: 125486
updated: 2026-10-18
---

# CR-125486 — Facts: Import projects from Excel

Source of truth: [[importProjects]] (`Oct\Property Manager\Settings\importProjects\importProjects.md`, written by the engineer). The ADO work item was created from it on 2026-10-18 by the agent at the engineer's request, so it holds no extra facts and has no attachments.

| # | Fact | Source |
|---|---|---|
| F1 | New screen `set.importProjects`: Property settings › Projects & properties tools › Import projects. It is an addition to the module (S4). | importProjects.md §header |
| F2 | Flow: download the template, upload the xlsx, review every row, then import the valid rows only. | §الهدف |
| F3 | **Add only**: the import never updates an existing project. An existing number is an error. (Decision 12/10.) | BR-3 |
| F4 | The template has 24 columns in a fixed order, with the headers in row 1. The column list, required flags and values are in §الحقول rows 2–25. | §الحقول |
| F5 | Every row is validated on its own with the project screen's rules. All of a row's errors are shown at once. | BR-1 |
| F6 | Lookups are matched by name (Arabic or English) or by code. A multi-value cell is split on `،` or `,`. | BR-2 |
| F7 | Name and second-language name must be unique, both against the DB and within the file. | BR-4 |
| F8 | The parent project must be an existing project or one on an earlier line of the same file. It cannot be the project itself. | BR-5 |
| F9 | The sales department must be linked to the user. The governorate must belong to the country, and the city to the governorate. | BR-6 |
| F10 | Area, floors, property count and price must be ≥ 0. Floors and property count must be integers. | BR-7 |
| F11 | pcode is generated as on the screen. Activity comes from the investment type. "Revenue recognition" comes from the company policy in general settings and is not a template column (decision 11/10). | BR-8 |
| F12 | Auto cost center (blank = yes) is created after all rows are saved, for each imported project with no sub-projects. Any value other than yes/no is an error. | BR-9 |
| F13 | The import runs in file order and skips error rows. It then shows "N new, K skipped", writes an import-log row and clears the file. | BR-10 |
| F14 | Validation is computed once before save. The log's error count equals the file's error count. | BR-11 |
| F15 | The error file is the same file plus an "errors" column. | BR-12 |
| F16 | The import is one server operation using the screen's validation. Row and size limits are for the product to set. | BR-13 |
| F17 | Screen layout: notes, a 4-step bar, the last result message, a file group, a summary bar, 2 buttons, and 3 tabs (row review, template columns, import log). | §ترتيب الشاشة |
| F18 | Acceptance criteria AC-1 … AC-6. | §معايير القبول |
| F19 | Open questions: is sales department / city entered by name or by code? Are boundaries, dimensions, geo-location and image excluded from the template? | §أسئلة مفتوحة |

Implied repos: AccFlex_Cloud_ERP (PropertyManager), AccFlex_Cloud_Front (property-manager), AccFlex_Cloud_Database (import-log table + menu/permission seed).
