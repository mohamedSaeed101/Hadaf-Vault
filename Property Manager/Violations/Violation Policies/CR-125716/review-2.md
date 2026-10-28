# Review round 2 — CR_125716   base 730bd73ae (DB) / 3ace72ad51 (ERP) / 6bac4b144f (Front)  head = base, all changes uncommitted   verdict: pass

Re-check only, per the round-2 rule: the `done` rows of [[review-1]] (1, 2, 3, 6, 9, 10, 13, 14), the module-id change (row 18) and the no-code rows' notes (5, 7, 11). No new rows: no fix introduced a block. Read `git diff HEAD` plus untracked files in the three repos (bin/obj/.angular/node_modules ignored). Reviewed by Fable 5.1.

| # (review-1 row) | status | evidence (file:line) | note |
|---|---|---|---|
| 1 | verified | `violation-policy-form-popup.component.html:4` `[maxHeight]="'90vh'"`; `:20` `<dx-scroll-view width="100%" height="100%">` wraps the form and the Save/Cancel row (`:192-200`) and closes at `:201` | Save is inside the scroll view, so it is reachable at any viewport height |
| 2 | verified | `violation-policy-form-popup.component.ts:50-56` `open()` fills the form before `visible = true`; `:62-66` `onShown()` only applies `status: 'valid'` to each validator's adapter, no `reset()` on the group; `:72-77` `onSaveClick()` runs `validationGroup.instance.validate()` and returns on `!isValid` | Save on an empty New form still raises the required (Code, Name, Type, Mode) and `isPositive` (`:48`, FirstAmount 0) messages because `validate()` re-evaluates the current values; nothing shows before Save. `dx-validation-group` still encloses all editors (`.html:21-190`) |
| 3 | verified | `shared/violation-policies.constants.ts:8` `export const KsaCountryId = 193`; `violation-policies-data.service.ts:12,41` imports and compares it; no `projects/logistics` import remains under `modules/violation-policies/` | Cross-sub-app import removed |
| 6 | verified | `0467_Pm_ViolationLookups.sql:13` `N'Lease Terms Breach'`, `:44` `N'After Confirmation'` = `ViolationType.cs:14`, `ViolationApplyMode.cs:11` | Seed and static lists now agree on casing |
| 9 | verified | `src/assets/i18n/en-US/property-manager.json:99` `"_FinePolicy_": "Violation Policy"` | Matches the CONTRACTCLAUSE block's title case |
| 10 | verified | `contract-clause-shell.component.ts:35` `private violationPoliciesSub: Subscription;` `:59` unsubscribes before re-subscribing; `:48` unsubscribes in `ngOnDestroy` | Edit (`:88`) and New (`:105`) both route through `loadViolationPolicies`; the stale-response race is closed |
| 13 | verified | `GetAllViolationPoliciesQuery.cs:23-40` `.AsNoTracking().OrderBy(Code).Select(x => new ViolationPolicyListDto{...}).ToListAsync`; `:42-51` fills the 4 lookup-name fields from the static lists in memory | Projection in SQL, no entity materialisation |
| 14 | verified | `violation-policy-form-popup.component.ts:83-90` `fb.group({ Id, Code, ViolationPolicyName, ViolationPolicyNameSecondLanguage, ApplyModeId: null, ...ViolationPolicyDefaults })` | Defaults have one source (`constants.ts:31-38`); `open()` resets to the same object plus the country-driven `ApplyModeId` |
| 18 | verified | `Module.cs:878` `new Module(938, ...)`; `0002_Acc_Module_Data.sql:875` `(938, N'Property Manager Violation Policies', ...)`; `routes.ts:102` `data: { ModuleId: 938 }`; `ViolationPolicyController.cs:20` and `WebMenuItem.cs:38` take the id from `Module.PropertyManagerViolationPolicies` | A `\b954\b` grep over every modified and untracked file in the three repos (generated outputs excluded) returns nothing |
| 5 (no-code) | verified | `spec.md:59` A6 now lists "… Apply mode and Active (user story 3, [[review-1]] row 5)" | Spec and screen agree |
| 7 (no-code) | verified | `decisions.md:34` D8 records the `Id` PK bend of `accflex-erp-data.md` with the sibling precedent, to be cited in the PR | |
| 11 (no-code) | verified | `decisions.md:33` D7 records the unpaginated `GetAll` bend of `accflex-erp-api.md` with the reason, to be cited in the PR | |
| 18 note | verified | `decisions.md:16` Q4 shows ~~954~~ **938** (D6); `:32` D6 states the reason (938 free on all 661 origin refs; 954 taken by Payroll "Work Teams" on Sabreen) | |

Rows 4, 8, 12, 15, 16, 17 were "no change" by design in round 1 and are not re-opened. Row 17 (one-line `0002_Acc_Module_Data.sql` merge conflict against origin/Master_Stable) still applies at release.

New rows: none.
