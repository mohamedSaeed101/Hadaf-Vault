---
type: review
cr: 125488
round: 2
date: 2026-10-19
reviewer: Fable 5.1 (fixes applied by Opus 5.5)
---

# Review round 2 — CR_125488   base = each repo's HEAD (uncommitted working tree; origin/Master_Stable moved, not diffed)  head = working tree   verdict: pass (0 block, 0 should, 0 nit new)

Reviewed by Fable 5.1; round-1 fixes applied by Opus 5.5. Re-check only: the rows of `review-1.md` marked done / disagree / deferred / no change. Diff = `git diff HEAD` + untracked files per repo: Database `9a1884a` (1 file), Cloud_ERP `ca9755d` (10 tracked + 3 new folders), Front `c070dfc` (6 tracked + 1 new folder). Status shows only CR files; repo `TSClient` untouched.

Verified locally this round: `dotnet test PropertyManager.Application.Test.csproj --filter FullyQualifiedName~PropertyBulkGeneration` → Passed 71 / Failed 0. Not re-checked in a browser: rows 2 and 3 (the markup is in place; a visual pass on Sabreen is QA's at stage).

| # (r1) | outcome | evidence |
|---|---|---|
| 1 | done, verified | `IPropertyManagerContext.cs:39` `DatabaseFacade Database { get; }`; `CreateBulkPropertiesCommand.cs:49` `_propertyManagerContext.Database.BeginTransactionAsync`; `BulkScenario.cs:158-160` mocks `DatabaseFacade` directly, `TransactionServices` / `infrastructure` gone; `PropertyManagerContext : DbContext` is the only implementer, so the interface member is satisfied with no code |
| 2 | done, code in place (no browser) | `bulk-pattern-form.component.html:62-63` `dir="ltr"` + `[rtlEnabled]="false"` on the code-pattern `dx-text-box` |
| 3 | done, code in place (no browser) | `property-bulk-generation-shell.component.html:30` `min-w-0` on the card; `:71` grid wrapped in `w-full max-w-full overflow-x-auto` |
| 4 | done, verified | `BulkPropertyDtos.cs:63-70` has Id, ProjectNumber, names, InvestmentTypeIds only; `GetLeafProjectsForBulkGenerationQuery.cs:25-32` projection matches; regenerated `node_modules/property-manager.api.client/dist/index.d.ts:744-749` has no `HasCurrency` / `ProjectActivityId` |
| 5 | done, verified | `PropertyBulkGenerationController.cs:47,65` AddPolicy on Verify and Create; front gated on Add per row 21 |
| 6 | done, verified | `Resource.resx` BulkGarageAreaRequired and `ar-EG/property-manager.json` `_GarageAreaRequired_` both «مساحة الجراج مطلوبة وأكبر من صفر» |
| 7 | no change (spec/decision), honest | PR wording only; the package is test-only |
| 8 | disagree accepted, row dropped | nit; verify marks the duplicate «متكرر في الجدول» and save is refused, so nothing wrong is saved |
| 9 | no change (spec/decision), honest | rollback proven on the mocked transaction; mid-batch failure is a QA note on the work item |
| 10 | done, verified | `BulkPropertyDtos.cs:11,15,17,21` `[Range(1,…)]` ProjectId, `[Range(0,…)]` GarageArea / GaragePrice, `[Required]` Rows; test `Verify_DataAnnotations_RejectNullRows` (`VerifyBulkPropertiesCommandHandlerTests.cs:405`) |
| 11 | done, verified | `BulkPropertyRowChecker.cs:66,74,99,111,118,136-142,160` `.AsNoTracking()` on every lookup (12 reads); `Property` stores ids only, no tracked navigation is needed |
| 12 | no change (spec/decision), honest | spec §Save: per-unit SaveChanges because the serial reads MAX |
| 13 | done, verified | `BulkPropertyRowChecker.cs:125-127` `ProjectOwnershipNotFound` guard mirrors `CreatePropertyCommand.cs:123`; test `Verify_WhenProjectOwnershipIsUnknown_FailsWithProjectOwnershipNotFound` (`:381`) |
| 14 | no change (spec/decision), honest | lookup, same as `api/Project/GetAll` |
| 15 | disagree accepted, row dropped | conditional nit; one `IN (...)` query per verify, no slow tenant observed |
| 16 | done, verified | `PropertyBulkGenerationController.cs:34,49,67` typed `ProducesResponseType` (List<LeafProjectForBulkGenerationDto>, BulkPropertyVerifyResultDto, int) |
| 17 | disagree accepted, row dropped | the request name is the generated client type the front imports (`VerifyBulkPropertiesCommand.fromJS`); PM sibling POST bodies are commands |
| 18 | no change (spec/decision), honest | `0002_Acc_Module_Data.sql:867` row 936 matches the 10-column source order and `Module.cs:797` |
| 19 | no change (spec/decision), honest | `ModuleNameForUI` = `PropertyBulkGeneration`, aligned with 935 |
| 20 | deferred: release-ticket, honest | not a code change: a merge-time check that 934→937, 935 and 936 all survive the MERGE … NOT MATCHED BY SOURCE DELETE; belongs to `release-ticket` |
| 21 | done, verified | shell `.ts:105` `hasAddPermission = permissions.userAllowAdd()`; `canSave` (`:92-101`) requires it; `.html:61-63` COMMON._YouDontHaveAddPermision_; verify skipped without Add (`:236`); `property-search.component.ts:29-31` button on `getPermissionsOfModule(936).AllowAdd` |
| 22 | no change (spec/decision), honest | Q11: «استيراد العقارات» gated on module 935; works once CR-125487 merges (merge-order note) |
| 23 | deferred: release-ticket, honest | `package.json:103` still `1.0.108`; the regenerated client lives only in the set's `node_modules` (local 0.0.59), repo `TSClient` clean; regen + pin bump is the release step |
| 24 | done, verified | `property-bulk-generation-data.service.ts:25-29` types / activities from `PropertyManagerStaticResourcesService.AllProjectsTypes$` / `AllProjectActivities$` (service `:62`, `:58`), filtered on `IsActive`; `ProjectTypeClient` / `ProjectActivityClient` no longer injected |
| 25 | done, verified | `user-can-view-module.ts` deleted (no reference left in `projects/` or `src/`); `permissions-handle.service.ts:44-59` `getPermissionsOfModule(moduleId): Partial<UserPermission>` reuses the `UserPermission` model and the admin short-cut; `properties` no longer imports from `property-bulk-generation` |
| 26 | no change (spec/decision), honest | V2 field-table defaults |
| 27 | no change (spec/decision), honest | Q5 + business-check round-2 row 18 |
| 28 | done, verified | shell `.ts:53-56` group validator `floorRange` (From ≤ To) with `_FloorRange_` message (`form.html:44-47`); `rebuild` (`:197-204`) counts `(To−From+1)×UnitsPerFloor` before building, > 500 builds nothing and sets `rowCount` so `_OverLimit_` shows with `{{count}}`/`{{max}}`; an invalid form clears the grid (`rows = []`) and `listenToVerify` skips while invalid (`:237`) |
| 29 | no change (spec/decision), honest | V2 §ترتيب الشاشة |
| 30 | done, verified | shell `.ts:165-167` `defaultIfEmpty([])` on each of the three lookups in the `forkJoin` |
| 31 | disagree accepted, row dropped | under `switchMap` an un-caught inner error would complete the outer `verify$` subscription for good; `catchError(() => EMPTY)` is the right guard |
| 32 | disagree accepted, row dropped | status text is rebuilt on every verify; the comma is a nit |
| 33 | done, verified | `shared/row-status-view.ts` holds `RowStatusView`; `bulk-rows-grid.component.ts:7` imports it from `../../shared/`, not from the container |
| 34 | done, verified | `_OverLimit_` takes `{{max}}` and `{{count}}` in ar-EG / en-US; shell passes `max: maxRows` (`.html:65`); module ids stay one `const` per file (935 in the shell, 936 in property-search) |
| 35 | no change (spec/decision), honest | wording from the source note |

**New rows:** none. No fix changed a shipped DTO, route, column or signature; the only shared-interface change (`IPropertyManagerContext.Database`) is additive and satisfied by `DbContext`. No secrets, ports or local paths in the diff.

**Noted, out of scope (pre-existing, not introduced here):** `PermissionsHandleService.getApplicationName` has no Property Manager branch, so for a non-admin user the `UserPermissions<app>` cache the new `getPermissionsOfModule` / `userAllowAdd()` read is never written; every PM screen's permission check already behaves this way. The new Add gating is correct for admins and will be correct for non-admins once that cache is written; it needs its own work item.

**Round 3 needed:** no. Remaining items are release-ticket steps (rows 20, 23: MERGE row check at merge, PM client regen + pin bump) and the PR wording for row 7.
