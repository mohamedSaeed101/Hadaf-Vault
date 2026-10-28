# Review round 2 — CR_125487   base DB 9a1884a6c / ERP 7915bf7b27 / Front 96166bfbad (= HEAD, change = working tree)   verdict: pass (0 block; 1 should restated, row 18; row 9 stays a release-gate item for `release-ticket`)

Round-2 protocol: only the 24 rows of `review-1.md` were re-read. Each `done` row was checked in the working tree of `D:\Hadaf\worktrees\cr125487\` (`git status` + file reads, no edits). No fix introduced a `block`, so no new rows.

## Round-1 rows

| # | status | evidence |
|---|---|---|
| 1 | verified | `property-import-shell.component.ts:167-173`: on import success only `rows = []`, `currentStep = 4`; `summary` / `reviewRows` / `fileName` stay, so the review grid and «تحميل ملف الأخطاء» remain. `validRowsCount` is 0 once `rows` is empty (`:86-88`), so a second import of the same rows is blocked. `downloadErrors` still works (`fileName` kept). |
| 2 | verified | `PropertyManager.API.Client/TSClient/src/index.ts` is now modified in the ERP tree (+1867 / −1099): it carries `export class PropertyImportClient` and `AmenityDto.Serves?: number`. `plan.md` phase 7 records it. |
| 3 | accepted disagree | `PropertyManagerContext.OnConfiguring` (`:164-193`) calls `UseSqlServer` on every path with no `IsConfigured` guard, and `PropertyManager.Application.Test.csproj` has no `Microsoft.EntityFrameworkCore.InMemory` (only Logistics' test project does). `plan.md` phase 5 names phase 9 as the only proof for the handler (file order, parent wiring, per-row serial, rollback, log counts). Row dropped. |
| 4 | n/a, stays | Phase 9 item (NULL `Pm_Project.CurrencyId` through the scalar subquery, `PropertyImportValidator.cs:109-111`). |
| 5 | verified | `PropertyImportLog.Create` keeps only `FileNameRequired`; `InvalidRowCounts` is gone from `PropertyImportErrors.cs` and the resx diff (18 message keys + 19 column keys only). |
| 6 | verified | `WebMenuItem.cs:22` comment `// 5_1 is reserved for the project import (CR-125486).` |
| 7 | n/a, stays | Name the Amenity `Serves` fix in the PR and the work item (Q15). |
| 8 | n/a, stays | Phase 9: non-admin without module 935 gets 403 on `POST api/PropertyImport/Verify`. |
| 9 | release gate, recorded | `package.json` pin still `1.0.108`; `plan.md` phase 7 ("the pin bump … happens at release") records it. Handled by `release-ticket`: push, Client SDK pipeline 684 on `cr125487`, bump the pin in this CR's front, restore `node_modules`. Not a code block. |
| 10 | verified | Captions moved to `PropertyManager.Logic\PropertyImportAggregate\PropertyImportColumns.cs` (SmartEnum over `Resource.PropertyImportColumn*`, 19 keys in `Resource.resx` / `Resource.en.resx` / `Resource.Designer.cs`); the validator reads `PropertyImportColumns.<X>`. The only remaining `IsDefaultRequestCulture` use (`:276`) picks the list separator «،» vs «,», which is fine. |
| 11 | accepted disagree | `GetNextCodeService.GetNextPropertyCode` (`Shared/GetNextCodeService.cs:49-74`) has non-trivial child-serial arithmetic (strip parent prefix, 2-digit zero-padded counter); a handler-side cache would duplicate it. One `MAX` per row inside the transaction, bounded at 1000 rows, is acceptable for a setup tool. Row dropped. |
| 12 | verified | `PropertyManagerContext.BeginTransactionAsync` (`:85-90`) sets `Transaction = transaction.GetDbTransaction()`; the handler clears it in `finally` (`ImportPropertiesCommand.cs:112-115`), so `SaveChangesWithValidation` (`:143-147`) defers post-domain events until commit. `IPropertyManagerContext` exposes `Transaction { get; set; }` (`:22`) and the new `BeginTransactionAsync`. |
| 13 | verified | `PropertyImportController.GetLog:69`: `[Range(0, int.MaxValue)] skip`, `[Range(1, 10000)] take`. |
| 14 | n/a, stays | Scaling note only. |
| 15 | verified | `Pm_PropertyImportLog.sql`: `ImportDate`, `CreatedOn`, `LastModifiedOn` are `DATETIME2 (3)`. |
| 16 | verified | sqlproj `Build Include` now sits between `Pm_PropertiesBoundaries.sql` and `Pm_PropertyInvestmentType.sql` (alphabetical). |
| 17 | n/a, stays | `UserId` kept per spec §Import log. |
| 18 | restated (should) | `property-import-excel.service.ts:18-33`: the loop still runs `r = 1 … decode_range(sheet['!ref']).e.r`; the `rows.length > MAX_IMPORT_ROWS` break (`:30-32`) only fires on non-blank rows. A sheet whose used range is formatted to row 1,048,576 with 3 data rows still does ~1M × 19 `encode_cell` + lookups on the main thread before the shell's check. See the row below. |
| 19 | verified | `onReviewRowPrepared = (e: RowPreparedEvent<ReviewRow>)`, import from `devextreme/ui/data_grid` (`:6`, `:192`). |
| 20 | verified | `clearFile()` is gone; `fileName` / `rows` / `summary` / `reviewRows` are set only inside the verify `subscribe` success (`:145-152`), so a failed verify leaves the previous screen intact. |
| 21 | verified | `property-import-shell.component.html:199` `trackBy: trackByField`; `trackByField` returns `column.field` (`.ts:198`). |
| 22 | n/a, stays | Pre-existing theme bug (`--invalidFadedBorderColor`), report separately. |
| 23 | n/a, stays | Arabic register: PO's call. |
| 24 | n/a, stays | `xlsx` CVEs: separate work item. |

## Findings carried into this round

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 18 | AccFlex_Cloud_Front/…/property-import/shared/property-import-excel.service.ts:18-33 | should | AP: performance (unbounded loop); spec "Max 1000 rows" (Q10) | The loop is bounded by the sheet's used range, not by the row cap: blank-but-formatted rows are `continue`d (`:24-26`) and never count toward the `rows.length > MAX_IMPORT_ROWS` break, so a 1,048,576-row used range with 3 data rows still iterates the whole range (~20M cell lookups) and blocks the tab before the shell's too-many-rows check. | Bound the loop by the Excel row index as well: `for (let r = 1; r <= Math.min(lastRow, MAX_IMPORT_ROWS + 1); r++)` and, after the loop, if `lastRow > MAX_IMPORT_ROWS + 1` and any later row is non-blank, return `MAX_IMPORT_ROWS + 1` rows (or push one sentinel row) so the shell shows «_TooManyRows_» instead of silently truncating. The spec cap is "1000 rows per file", so data below Excel row 1002 is already over the cap; a file with 3 data rows and a huge formatted range then returns in milliseconds. Acceptance: a sheet with `!ref` `A1:S1048576` and 3 data rows verifies at once; a sheet with data on rows 2–1002 still shows «_TooManyRows_». |

## Checked while verifying the fixes (no regressions found)

- Row 1 + row 20 together: `hasErrors` and the error download read `summary` / `reviewRows`, which now survive a successful import; the import button hides through `validRowsCount` (`rows.length` is 0), not through `summary`. No path reaches `downloadErrors` with `fileName === null`, because `fileName` is set with `reviewRows` on verify success and never cleared.
- Row 12: `Transaction = null!` in `finally` runs after `await using var transaction` disposes on every exit; the house contexts (`SharedKernelContext:46`) use the same `DbTransaction Transaction` shape.
- Row 10: `PropertyImportColumns` is a SmartEnum in `PropertyManager.Logic`, same pattern as `PropertyImportErrors`; `ToString()` gives the caption, so the `string.Format(...)` call sites did not change meaning.
- Row 13: `[Range]` on query parameters is validated by `[ApiController]` model binding; `GetPropertyImportLogQuery` itself is unchanged and still reads `request.Skip` / `request.Take`.
- Row 15/16: new table only, no migration script needed; `Pm_Properties.sql` NULL-widening and FK drop unchanged from round 1.

## Unchanged from round 1

Spec conformance table, backward-compatibility notes, and the "What only phase 9 can verify" list in `review-1.md` still hold; nothing in the round-2 diff touched those areas.
