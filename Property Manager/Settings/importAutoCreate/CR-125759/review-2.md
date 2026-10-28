# Review round 2 — CR_125759   base ERP 1c2d2313 / Front af569bec   head: uncommitted working trees on `cr125759`   verdict: pass

Re-check of review-1 rows only (working trees read directly; paths as in round 1). No new row: no fix introduced a block.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | ERP\...\ProjectImportValidator.cs:290; PropertyImportValidator.cs:430 | done | decisions Q10 | Both validators guard `whenMissing` / `createMissing` with `!value.All(char.IsDigit)`; digit-only cells fall through to the not-allowed error and pend nothing. Tests `Digits_matching_no_activity_code_are_not_allowed_and_create_nothing` ("5", "1", "0") and `DigitsMatchingNoCode_AreNotAllowedAndCreateNothing` assert both the error and the empty `PendingLookups`; AC13 pending test now uses a lettered name. Verified. | none |
| 2 | FE\...\project-import-shell.component.ts:100-162 | accepted (disagree holds) | spec A12 | `clearFile()` is the first statement of `onFileChanged`, and `fileName` / `parsedFile` / `skippedRows` are assigned only inside the `if (!result)`-guarded success branch. A12 path: file A imported (1 skipped) → file B with no parent cost center → clearFile() empties the three fields, 400 completes without a value, uploader reset, nothing re-set. No stale rows; round-1 finding was wrong. | none |
| 3 | FE\...\property-import-shell.component.ts:33; i18n PROPERTYIMPORT `_StepUpload_` / `_StepResult_` | done | spec Front (Q8) | ar "رفع الملف والاستيراد" / "مراجعة النتيجة", en "Upload and import the file" / "Review the result", identical wording to PROJECTIMPORT `_Step2_` / `_Step3_`. Verified. | none |
| 4 | FE\...\project-import-review.component.html | done | Karpathy 2 | `IsValid` status column removed; grid shows Line, project fields, cost center action, Errors. Verified. | none |
| 5 | ERP\...\ImportPropertiesCommand.cs:69-74 | done | Karpathy 2 | `if (createdLookups.Count > 0)` guards `SaveChangesWithValidation`, mirrors projects side. Verified. | none |
| 6 | ERP\...\Application.Test\Geography\CityCreateTests.cs | skipped, accepted | test placement | PM test project is the one this CR gates; reason holds. | none |
| 7 | vault test-results.md A2 | skipped, accepted | spec A2 | Pre-release manual click; reason holds. Still to be done once per screen before release. | none |
| 8 | FE\...\project-import-review.component.{ts,html,css} | done | AP: remove-redundant | `statusOptions`, `onRowPrepared`, the `(onRowPrepared)` binding and `::ng-deep .project-import-error-row` are gone (grep over property-manager project empty); css keeps only `.project-import-errors`. Verified. | none |
| 9 | i18n PROJECTIMPORT `_Status_` / `_StatusValid_` / `_StatusError_` | done | AP: i18n parity | Removed from ar-EG and en-US; the only remaining `_StatusError_` hits are `PmBulkGeneration`, a different section still in use. Verified. | none |
| 10 | FE api-clients `{project,property}-import.client.ts` verify() | skipped, accepted | spec Out of Scope | Kept by design. | mention on the PR |
| 11 | FE api-clients `index.ts` barrel | skipped, accepted | api-clients.md | Release-step action: sync with origin/Master_Stable, re-run api:sync, stage only this CR's client paths. | at release |
| 12 | FE\...\shared\services\components\import-created-lookups\import-created-lookups.component.ts:4-13 | done | core.md §UI (i18n) | `LABEL_KEYS: Record<ImportLookupField, string>` covers all 8 enum values; a new enum member becomes a compile error. Verified. | none |
| 13 | FE\...\project-import-shell.component.ts:108 | done | core.md §Follow the code | Both shells now `showErrorToast(COMMON._NoPermission_)`. Verified. | none |
| 14 | ERP\...\ImportLookupCreator.cs:40,73 | skipped, accepted | optional | Unreachable today. | none |
| 15 | ERP\...\ImportLookupCreator.cs:58 | skipped, accepted | house pattern | Note on the PR. | none |

Gates reported by the implementer (API build 0 errors, 105/105 filtered tests, `npm run testing` 0 errors, prettier clean) were not re-run here; the code read is consistent with them.

Verdict: pass — 0 block, 0 should, 0 nit open. Round 3 not needed. Remaining items are release-step actions (rows 7, 10, 11, 15).
