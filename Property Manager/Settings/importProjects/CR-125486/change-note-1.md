---
type: change-note
cr: 125486
iteration: 1
source: ADO comment 10010529 (Sabreen Abubakr, 2026-10-20, retest on localbeta / Sabreen)
created: 2026-10-21
---

# CR-125486 — Iteration 1 (QA retest)

Merge Desk #12533 is InRelease, so this is an iterate on `cr125486`. There is no Bug id.

## Root causes
1. **BR-2 codes.** `ProjectImportValidator.LoadLookupsAsync` keys project type, status, view and activity by Name / NameSecondLanguage only. Their «الكود» is `Serial` (int, DEFAULT 0). `ACFX_Governorate`, `ACFX_City` and `ACFX_Center` have **no code column**, so they stay name-only. That answers the TBI open question («إدارة المبيعات والمدينة بالاسم أم بالكود؟»): sales organization accepts name or code, city accepts name only.
2. **«بالغة».** The typo is in `Resource.resx` `ProjectNameSecondLanguageRequired`, in `ProjectImportColumn.ProjectNameSecondLanguage`, and in `property-manager.json` `PROJECTIMPORT._ProjectNameSecondLanguage_`. Other copies are outside this CR's scope: `_PropertyNameSecondLanguage_` (property screen), construction.json and shared.json.
3. **⟦E…⟧ marker.** `origin/Stage_Beta` carries cr125183's `SharedKernel.Logic.Errors.ErrorMarker` (Ahmed Abdou). It is not on Master_Stable. It appends `⟦E<8 digits>⟧` to SmartEnum errors, and the middleware strips it only from HTTP error responses. Import row errors travel as DTO text, so the marker shows. The sibling `BulkPropertyRowChecker` on Stage_Beta strips it with a local regex.

## Change
- What: (1) also key the 4 PM lookups by `Serial` when it is > 0. Activity matches name or code, never the id. This refines Q3, because the TBI says name or code. (2) Fix the 3 strings. (3) Strip `⟦E\d+⟧` in `ProjectImportRowValidation.ToDto()`, using the same regex as the sibling, because `ErrorMarker` can't be referenced from a Master_Stable base.
- Where: ERP `ProjectImportValidator.cs`, `ProjectImportColumn.cs`, `PropertyManager.Logic\Resources\Resource.resx` + `Resource.Designer.cs` comment, tests `ProjectImportValidatorTests.cs` + `ProjectImportTestContexts.cs`; Front `assets\i18n\ar-EG\property-manager.json`.
- Test: new validator tests: type by code «1», activity by code, the id is not a code, serial 0 is not a code, and the marker is stripped. Then PM API build and the PM tests.
- Risk: a lookup whose name is a number equal to another row's serial becomes "ambiguous" instead of matching. That's acceptable, and the message names the column.
- Rollback: revert the iteration commit on `cr125486`.
