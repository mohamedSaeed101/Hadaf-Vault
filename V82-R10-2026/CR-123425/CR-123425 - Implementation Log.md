---
type: implementation-log
cr: 123425
created: 2026-09-29
tags: [cr, cr-123425, implementation]
---

> [!info] Execution ledger from the subagent-driven implementation. Plan: [[CR-123425 - Plan]] · Decisions: [[CR-123425 - Grilling Decisions]]


Spec: D:/Hadaf/Hadaf Vault/V82-R10-2026/CR-123425/CR-123425 - Grilling Decisions.md (Round 6 overrides earlier rounds) + CR-123425 - Source.md

## Worktrees (branch feature/CR-123425-permission-groups, from origin/Master_Stable 2026-09-29)
- DB:    D:/Hadaf/worktrees/CR-123425/AccFlex_Cloud_Database   base 6350369ef
- ERP:   D:/Hadaf/worktrees/CR-123425/AccFlex_Cloud_ERP        base 6b96072e1a
- FE:    D:/Hadaf/worktrees/CR-123425/AccFlex_Cloud_Front      base 528d3417ee
- SP:    not created yet (repo has only `main`, no Master_Stable) — needed at Task 6
- Upstream unset on all branches (no accidental push to Master_Stable).

## Baseline
- ERP Misc.Logic.Test: 14/14 passing.
- DB build: Git Bash mangles /p: switches — must prefix MSYS_NO_PATHCONV=1.

## Pre-flight scan
| Pair / task | Produces vs consumes | Finding |
|---|---|---|
| T1 ↔ T3 | table/column names (PermissionGroupId, NameSecondLanguage, ModuleId, AllowX, UserId) vs EF configs | consistent |
| T2 ↔ T4 | ModuleFlags, GroupSnapshot, GroupPermissionSync.ApplyGroupChange, PermissionGroup.Snapshot, CompanyUser.ApplyGroupChange | consistent |
| T2 ↔ T5 | CompanyUser.SetPermissionGroups(groupIdsOfApplication, newGroupIds) | consistent |
| T3 ↔ T4/T5 | ISharedKernelContext.PermissionGroups / UserPermissionGroups | consistent |
| T4 ↔ T6 | INotificationService.RefreshUserPermission(IEnumerable<string>) — T4 stubs, T6 implements | consistent (ordering noted in plan) |
| T5 ↔ T7/T8/T9 | regenerated misc-client.ts types (PermissionGroupDto, PermissionGroupClient, PermissionGroupIds) | consistent |
| T7 ↔ T9 | grid applyGroups/selectedGroups/showPermissionSources | consistent |
| T8 ↔ T9 | selector/popup inputs/outputs | consistent |
| T1 self | SQL + sqlproj + 0003 row | consistent |
| T2 self | `new UserModule { … }` object initializer assumes an accessible parameterless ctor; UserModule ctor is internal (exact shape unknown) | Ruling below |
| T2 self | CloneForTest needs InternalsVisibleTo | plan covers it |
| T4 self | Step 8 Swagger smoke test needs a running API + tenant DB | Ruling below |
| T5 self | Step 6 smoke test needs running API | Ruling below |
| T7–T9 | FE worktree has no node_modules | Ruling below |
| T10 | manual QA on dev tenant | Ruling below |

- Ruling: T2 — if UserModule has no accessible parameterless ctor, the implementer uses the existing internal ctor (same assembly) instead of the object initializer — behaviour identical — cost if wrong: none (compile error surfaces it).
- Ruling: T4 Step 8 / T5 Step 6 runtime smoke tests (Swagger against a tenant DB) are deferred to the user's manual QA (Task 10); implementers cover the logic with the unit tests + a Release build — the sync rule lives in CompanyUser/GroupPermissionSync which is unit-tested — cost if wrong: an EF-mapping/runtime bug found at QA instead of now.
- Ruling: T7–T9 type-check uses a directory junction from the FE worktree's accflex-erp/node_modules to the main checkout's node_modules (no network install) — cost if wrong: version drift between checkouts could mask/raise type errors; package.json is identical on both branches if checked.
- Ruling: T10 QA is a manual checklist for the user on a dev tenant; not executed by a subagent — cost if wrong: none, it was always manual.

## Progress
Task 1: dispatched (implementer haiku, BASE DB 6350369ef)
Task 1: review 1 — spec ✅; Critical commit msg attribution/trailer, Important new files ASCII/LF vs BOM+CRLF; ⚠️ test-filter item N/A (brief header text, DB-only task) → fix round 1 sent
Task 1: fix round 1/5 (2 addressed, 0 open; amended to 9bd36007a)
Task 1: complete (DB commits 6350369ef..9bd36007a, review clean)
Task 1: minor (deferred): implementer self-review overconfident
Task 2: dispatched (implementer sonnet, BASE ERP 6b96072e1a)
Task 2: implementer DONE dd825b6211 (26/26 tests); review dispatched (sonnet). Implementer concern: child FKs set by EF relationship at save (Task 3 config must wire HasForeignKey)
Task 2: complete (ERP commits 6b96072e1a..dd825b6211, review clean)
Task 2: minor (deferred): GroupSnapshot.Union has no direct unit test (covered indirectly by Task 4 member sync)
Task 2: minor (deferred): child entities do not set PermissionGroupId pre-persistence (EF relationship wires it; mirrors UserModule precedent)
Task 2: ⚠️ module 627 not referenced — resolved: wired in Task 4 controller ModuleId
Task 3: dispatched (implementer sonnet, BASE ERP dd825b6211)
Task 3: implementer DONE 55daf074b0 (26/26; Misc.Reports MSB3822/3823 resx errors pre-existing); note: implementer used git stash (shared stack) — verified no leftover
Task 3: complete (ERP commits dd825b6211..55daf074b0, review clean)
Task 3: minor (deferred): commit 55daf074b0 lacks Co-Authored-By trailer — fix in final wave (reword) before push
Task 4: dispatched (implementer sonnet, BASE ERP 55daf074b0)
Task 4: implementer DONE ed82c9fe85 (28/28); adaptations: errors localized via Misc.Application/Resources/CommonResource.resx + Localize helper; controller extends BaseController
Task 4: review 1 — spec ✅; Critical: SaveChangesWithValidation Result ignored in Save/Delete handlers
Ruling: plan pseudocode showed an unchecked save — fix it anyway (check Result, return failure, notify only after success) — the plan text was a snippet omission, repo convention and correctness win — cost if wrong: none
Task 4: minor (deferred): policy strings literal "Edit"/"View" (matches sibling controllers)
Task 4: fix round 1/5 (1 addressed, 0 open; commits ed82c9fe85..b2aa9de0de)
Task 4: parked — re-reviewer claimed trailer should name Haiku — Ruling: reviewer wrong; required trailer is Claude Opus 5.5 per session attribution rule and the prompt given
Task 4: complete (ERP commits 55daf074b0..b2aa9de0de, review clean)
Task 5: dispatched (implementer sonnet, BASE ERP b2aa9de0de)
Task 5: implementer DONE ERP 9bf901595e, Front 730b87bde9 (hand-added client types; full NSwag regen reorders classes → 11k-line noise)
Ruling: SP worktree branched from origin/main (b0c2b70) — repo has no Master_Stable; main is its default — cost if wrong: rebase onto the right base before PR
Ruling: T6 — publishing AccessControl.API.Client NuGet is outward-facing → not done. SP gets TargetUserGuids + local client regen (committed, not published). ERP RefreshUserPermission(guids) sends via the CURRENT package's tenant broadcast (no TargetUserGuids yet) — each client re-fetches only its own permissions, so behaviour is correct, just broader fan-out. User follow-up: publish SP client, bump Misc.API package, set TargetUserGuids (one line). — cost if wrong: extra refresh calls tenant-wide until the bump
Task 5: review 1 — Important: PermissionGroupClient missing deletePermissionGroup → fix round 1 sent
Task 5: fix round 1/5 (1 addressed, 0 open; Front 730b87bde9..623ae4c009)
Task 5: complete (ERP b2aa9de0de..9bf901595e, Front 528d3417ee..623ae4c009, review clean)
Task 5: minor (deferred): nswag.json runtime "Net8.0" unparseable by local NSwag; full regen reorders classes — hand-added client code must be regenerated/verified by team NSwag pipeline
FE node_modules: junction worktree/accflex-erp/node_modules -> D:/Hadaf/AccFlex_Cloud_Front/accflex-erp/node_modules (only diff: payroll.api.client 1.0.1677 vs 1.0.1678). NEVER npm install in worktree (writes into main checkout).
Task 6: dispatched (implementer sonnet; BASE SP b0c2b70, ERP 9bf901595e, FE 623ae4c009)
Task 6: implementer DONE SP 85393f1, ERP 4d43b50e81, FE 5cd76189b1; SP not buildable locally (private feed 401); eslint config broken repo-wide
Task 6: complete (SP b0c2b70..85393f1, ERP 9bf901595e..4d43b50e81, FE 623ae4c009..5cd76189b1, review clean)
Task 6: minor (deferred): SP change not compiled locally (private feed 401) — user must build SP + publish client
Task 6: minor (deferred): live refresh active only in Logistics app (other micro-frontends do not inject AccflexPermissionsService)
Task 6: minor (deferred): repo eslint config broken (missing eslint-plugin-import) — lint not runnable
Task 7: dispatched (implementer sonnet, BASE FE 5cd76189b1)
Task 7: implementer DONE 2edd806a1a
Task 7: review 1 — Critical: unconditional .perm-cell wrapper changes layout in other apps; Important: unscoped ::ng-deep in extra list; Important: child grid no repaint on selectedGroups input change
Ruling: plan snippet wrapped every checkbox in span.perm-cell unconditionally — override: wrapper/layout only when showPermissionSources is true — the "other apps unchanged" constraint outranks the snippet — cost if wrong: none
Task 7: fix round 1/5 (4 addressed, 0 open; FE 2edd806a1a..f8fe516605)
Task 7: complete (FE 5cd76189b1..f8fe516605, review clean)
Task 8: dispatched (implementer sonnet, BASE FE f8fe516605)
Task 8: implementer DONE bd19051c91
Task 8: complete (FE f8fe516605..bd19051c91, review clean)
Task 8: minor (deferred): delete toast uses COMMON._DeleteDone_ (not in brief, repo convention)
Task 9: dispatched (implementer sonnet, BASE FE bd19051c91)
Task 9: implementer DONE c07ed0665a; fetchExtraPermissionById(491) uses current module (627 on this route) — correct
Task 9: complete (FE bd19051c91..c07ed0665a, review clean)
Task 9: minor (deferred): selectedGroups getter reallocates per CD cycle — memoize
Task 9: minor (deferred): onGroupsEdited reloads groups and user unordered (self-corrects)
Task 10: Ruling: manual QA checklist handed to the user (not run by a subagent)
Task 3: parked — commit 55daf074b0 lacks trailer — Ruling: not rewriting history non-interactively; user can reword before push (git rebase -i) — cost: one commit without attribution
Final review: Critical 491 collides with Stage_Stable (491/492 = Payroll WI 121335); Important I1 View-dependency not enforced by groups/sync/preview; Important I2 selectedGroups getter → repaint every CD; Minors M1–M6; T5 NSwag check + T6 SP CI build = must-fix-before-merge (user/pipeline actions)
Ruling: new permission id 494 (max used on all 150+ remote branches of 0003 is 493), English label "Manage Permission Groups" — cost if wrong: another in-flight branch may also claim 494; re-check at merge
Ruling: I1 — PermissionGroup.Update rejects a module with any action but no View; CompanyUser.ApplyGroupChange and FE applyGroupSelection clear Add/Edit/Delete/Print when the result has no View (reviewer's suggestion; mirrors UserBuilder's rule) — cost if wrong: PO may prefer "keep View" instead; one-line change either way
Ruling: fix wave includes M1 (plain delete keeps permissions), M3 (group modules/extras must belong to ApplicationId), M4 (skip memberships for admins); parked M2 (empty [] vs null is harmless — no groups in other apps), M5 (reload after popup save discards unsaved edits — spec silent, UX follow-up), M6 (popup grid toolbar buttons inert / plain confirm lacks text — cosmetic follow-up)
Final fix wave: dispatched (sonnet; BASE DB 9bd36007a, ERP 4d43b50e81, FE c07ed0665a)
Final fix wave: DONE DB 22f394c49, ERP beebb296ab, FE e7e4acf8ac (31/31); resumed once after API limit
Final fix wave: complete (DB 9bd36007a..22f394c49, ERP 4d43b50e81..beebb296ab, FE c07ed0665a..e7e4acf8ac, re-review clean)
