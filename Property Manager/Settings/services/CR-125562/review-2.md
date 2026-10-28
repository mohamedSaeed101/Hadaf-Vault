---
type: review
cr: 125562
round: 2
date: 2026-10-19
reviewer: Fable 5.1 (reviewing Opus 5.5's implementation)
---

# Review round 2 — CR_125562   base Master_Stable (db 0fe9f7a / erp dff0955 / front c0721b7)  head: uncommitted working trees on `cr125562` (same HEADs)   verdict: changes required

Fable 5.1 reviewing Opus 5.5. Re-read only the 18 rows of [[review-1]] against the current working trees (`git diff` + untracked files, nothing committed). The implementer's own gates (front `npm run testing` exit 0, prettier clean, API build 0 errors, 32/32 ServiceItem tests) are consistent with what I see; the one new row below is a runtime behaviour the unit tests cannot catch and no post-fix E2E of OpenItem was recorded in [[test-results]].

## Round-1 rows

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | Front service-item-form.component.ts:51-64 | **block** (fix introduced a regression) | row 1 fix; Front `feature-without-search.md` (clearDxValidators only after `resetForm`) | The fix is right for `resetItem()` (clearState / OnCreate no longer show red: `form.reset(defaults)` then the 200 ms validator reset on an already-blank form). But `patchItem()` also calls `clearDxValidators()`, and in DevExtreme 24.2 `Validator.reset()` → `DefaultAdapter.reset()` → `editor.clear()` → `option("value", "")` (`__internal/ui/m_validator.js:239`, `validation/m_default_adapter.js:38-40`, `editor/editor.js:376-379`, text box default `value: ""`), which fires `valueChange` → the Angular wrapper's `change()` writes `""` into the form control. Concrete input: OpenItem on `{Code:"SVC1", NameAr:"خدمة"}` → the two boxes show the values, then 200 ms later both are blank and `form.value.Code === ""`; Save → `_DataRequired_` toast; an Update is impossible without retyping. The ContractClause template calls no validator reset after `patchClause`, and the rule calls it only after `resetForm`. 200 ms timing is otherwise safe: patch-then-cancel within 200 ms ends blank either way. | Remove the `this.clearDxValidators()` call from `patchItem()` (keep it in `resetItem()`); OpenItem lands with the dx-validators in their untouched state, so nothing shows red. Re-run E2E A1 (open → edit → save) once and note it in test-results.md. |
| 5 | ERP PropertyManager.Data/EFConfigurations/ServiceItemConfigurations.cs | — | done | Verified: the `HasIndex(...).IsUnique()` line is gone; `UQ_Pm_ServiceItem_Code` stays in the sqlproj table. | none |
| 8 | Front service-item-shell.component.ts:92 | — | done | Verified: `OnSubmit` returns early when `formState$.value === NormalFirstoaded`; Ctrl+S on the blank view-only form no longer validates or toasts. | none |
| 9 | Front service-item-shell.component.ts:25,92,109,117,127 + .html:5 | — | done | Verified: `isSaving` set before `request$`, cleared in `next` and `error`, bound to `accflex-floating-icons [isSaving]` (the input exists on the shared component), and `OnSubmit` returns while it is true. | none |
| 11 | Front service-item-shell.component.ts:35-39 + .html:28 | — | done | Verified: `userAllowEdit()` read once in `ngOnInit`; `isEditable` is a field driven by `formState$`, false in `NormalFirstoaded` and in `Editing` without Edit; the form binds `[readOnly]="!isEditable"`. No getter in the template (template-bound-getters.md). | none |
| 12 | Front shared/service-item.constants.ts:9-28 | — | done | Verified: `ServiceItemFormValue` lives in constants, `ServiceItemDefaults: ServiceItemFormValue`; the form imports both and `getRawValue()` is typed through it. | none |
| 13 | Front service-item-form.component.ts:44,69 + .html:50 | — | disagree accepted | Spec A8 names a front message for a negative price; `[min]` guards typing, `Validators.min(0)` + `_AnnualPriceNegative_` guard the value. Row dropped. | none |
| 14 | Front shared/service-item-data.service.ts:12 | — | disagree accepted | `ALL_ITEMS_TAKE = 10000` is named with a comment; the round-1 row was stale. Row dropped. | none |
| 2, 3, 10, 18 | spec A7 evidence; Stage_Beta merge (WebMenuGroup / Module.cs / 0002 row 947); client regen + pin 1.0.108 | — | skipped, confirmed release / test items | None is an implementer change; all are already in HANDOFF under release. | none |
| 4, 6 | DB Pm_ServiceItem.sql:7 + EF `decimal(18,4)`; `AnnualPriceFormat` 2 dp | — | skipped, confirmed engineer call | `DECIMAL(19,4)` (db-rules.md) vs D5 18,4 stays an open engineer decision, not a block; the display precision follows it. Code still 18,4 / `'#,##0.##'`. | engineer decides before PR; cite the rule bent in the PR either way |
| 7, 15, 16, 17 | command annotations; PK `Id`; PUT defaults; `DF_…_AnnualPrice` | — | skipped, confirmed no-change / optional | Template parity or spec-backed; nothing to do in code. | none |

## Verdict

**changes required**: 1 block (row 1, introduced by the round-1 fix: validator reset after `patchItem` wipes the opened item's Code / NameAr), 0 should, 0 nit. Rows 5, 8, 9, 11, 12 are done and did not break a neighbour; 13 and 14 are accepted; the skipped rows are genuinely release / engineer / no-change items. Round 3 is needed only to confirm the one-line removal and the E2E note.
