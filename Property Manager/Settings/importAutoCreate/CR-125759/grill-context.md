# CR-125759 grill context (explorer scout, origin/Master_Stable, 2026-10-22)

Paths relative to AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\. Line numbers from grep, may be off by 1-2.

- Property import reuses the project lookup tables for type / status / activity / view (`PropertyImportValidator.cs:160-164`). Only property model is its own table. 12 boxed fields = 9 tables.
- Pm_ lookups (ProjectType, ProjectStatus, ProjectView, ProjectActivity, PropertyModel): `X.Create(int code, name, nameSecond, isActive)`, no validation; `Serial` INT NOT NULL default 0 is the "code" and comes from the request; no server-side serial generator; duplicate name only via `SaveChangesWithValidation` Duplicate (no unique index found in the .sql files: verify).
- Screens: types/status/view/activity on Module.Project (111) AddPolicy; property model on Module.Property (112) AddPolicy. Import screens: 944 / 945 AddPolicy.
- Governorate: `Governorate.CreateGovernorate(name, nameSecond, Maybe<Country>)`, SharedKernel `ACFX_Governorate`, FK CountryId. No module policy on its controller.
- City: no Create factory; only `City.UpdateCityList(...)` (diffs and deletes siblings). Needs a new factory or careful use. FK GovernorateId. No POST, no policy.
- Center: `Center.CreateCenter(name, nameSecond, Maybe<City>)`, FK CityId. POST has no policy.
- No status id is special (no logic keyed on ids): creating a status is safe.
- Projects `Normalize` (ProjectImportValidator :334) folds Arabic forms; Properties `Normalize` (:383) is a different, simpler function. Shared tables, different match rules.
- Result DTOs have no place for created records: ImportProjectsResultDto {NewCount, SkippedCount, NewCostCenters}; PropertyImportResultDto {NewRows, SkippedRows, PropertyImportLogId}. Contract change -> NSwag regen + client bump.
- Front: project-import-shell `onFileChanged` -> verify, `importValidRows` -> import, toast `PROJECTIMPORT._ResultMessage_`; property-import-shell `onFileSelected` -> verify, `importValidRows` -> import, result in html :26-29.
- Verify must never write; creation only inside the Import transaction, in order governorate -> city -> center, once per distinct normalized value per file.
