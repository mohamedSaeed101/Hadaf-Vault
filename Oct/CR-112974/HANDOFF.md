# HANDOFF — CR 112974 (cr112974 set, branch fx112974)

- Kind: Change Request; Merge Desk ticket Solved (owner mohamed.saed), version Beta, branch `fx112974` in API / Database / Desktop / WebContainer.
- Set: `D:\Hadaf-worktrees\cr112974` (Cloud_ERP only), port offset 200, tracking `origin/fx112974`.
- Path: Iterate (QA comment 10015919, Basma, 2026-10-22). RCA: `rca-comment-10015919.md`.

## Iteration 1 — issue 2 only (2026-10-25)
- `change-note-1.md`: `DescribeBlockers` shows each distinct blocker message once.
- Edited, **uncommitted** (user: no commit until told). Construction.API build: 0 errors.
- Not verified in the app yet (needs Construction API run against BETA-dbriyadhbn).

## Rebase (2026-10-25)
- Cloud_ERP `fx112974` rebased locally onto `origin/Master_Stable` (was 646 behind): 14 commits replayed clean, the merge commit "Merged PR 65891" dropped (its commits replayed; range-diff identical). Build 0 errors.
- **Not pushed.** Origin still has the old history; pushing needs `--force-with-lease` and rewrites the branch under the open Merge Desk PRs. Other repos (Database, Desktop, WebContainer) not rebased.

## Iteration 2 — issue 3 (2026-10-25, user: fix it, local only, no commit)
- `change-note-2.md`. Front main checkout (`fx112974`): `job-items.form.service.ts` (+`isIntegratedWithLogistics` from the existing system-config subscription; `UnitId = 0` only when logistics is on; unit required unless raw material with logistics on) and `job-items-pop-up.component.html` (unit field shown for raw material when logistics is off).
- **Uncommitted, not pushed.** `config.json` in the same checkout is a local change — never stage it.
- Front gate `npm run testing`: EXIT 0 (133 s), no error in touched files; prettier content clean (warning is CRLF working copy only). Not checked in the app (db-all unreachable).

## Tests (2026-10-25)
- Issue 2, offline: throwaway console app (scratchpad `blockertest`, references Construction.Application on fx112974) calling `DescribeBlockers`, culture ar-EG — 7 closed-period blockers → message once; 7 closed + 2 revised → each message once. RESULT PASS. Output: `NoModelError&لا يمكن نقل القيود القديمة لأن الفترة المحاسبية للقيد مغلقة`.
- Issue 3, in app (2026-10-25 15:23, local Construction API :5009 → db-all/BETA-dbriyadhbn, override proven by this machine's sessions; front localhost:4200 = main checkout): created raw-material item 67532 (12990, parent 2450, warehouse item 513/514) → POST 200 with UnitId 6; opened it (unit field shown «متر مكعب») and saved → PUT 200; control: same PUT with UnitId 0 → 400 «وحدة البند غير موجودة». PASS. Item 1001 (67526) itself can't be saved: no warehouse item + duplicate number 1001 (test data). **Test item 67532 left on the tenant — user to delete.**
- Issue 2, in app (15:26, user's OK): closed sub-periods 14–17 (AccountingClosed only; covers item 2004's 7 owner-bill journals), opened item 2004 (193), income 411→4202, Save → «نعم» → PATCH UpdateExpenseAndIncomeAccount 400; response carries «لا يمكن نقل القيود القديمة لأن الفترة المحاسبية للقيد مغلقة» **once** (QA saw 7). PASS. Sub-periods reopened; snapshot after == before (flags, LastModified, item 193 accounts 33/681, 9 actions still on 411).
- Issue 1 with ApproximateNo = 4 (user, 16:4x): set `Acc_SystemConfiguration.ApproximateNo` 5 → 4 on BETA-dbriyadhbn (**left at 4**). Item 2004, income 411 → 4202, «نعم» → PATCH 200. 5 journals migrated (6429, 6437, 7045, 7138, 12584; 12801/16815 have a 0 share, untouched): each 4202 line = the item's share rounded to 4 dp, cost center 25 kept, Dr/Cr totals identical to before, 6437 keeps its -0.0001. **Item 2004 now sits on 4202 with its old entries moved** (tenant data changed by the test; user 2026-10-25: leave item 2004 on 4202 and ApproximateNo at 4). Works because tolerance 10^-4 now equals the stored residue; tenants with ApproximateNo 5 still hit issue 1 — code fix still open.
- Correction: the 15:28 teardown did not stop the first API (my check missed the 127.0.0.1 listener); it ran until 16:46, now stopped (no Construction.API process, 5009 free).
- Desktop (user: code check is enough): frmNewJobItem calls the same PATCH UpdateExpenseAndIncomeAccount; HandleErrors joins NoModelError entries one per line → one line now (was 7). Issue 3 is web-only. Not run in the desktop UI.
- Teardown: local Construction API stopped; Chrome tab closed; the :4200 dev server was not started by this session and was left running. `appsettings.Development.json` (Construction.API) shows a change made at 14:21 (web-test → db-all), not by this session — left as is.
- (earlier) In-app tests for 2 and 3 blocked: `db-all` and `localbeta.hadaf.website` do not resolve from this machine (VPN/network). Retry once connected: local Construction API against BETA-dbriyadhbn + local front.

## Ship (2026-10-25, user: "push and create pr")
- Front: committed `edfdc5da0a fx112974: keep the unit of raw-material job items when the tenant does not integrate with logistics` (2 files; config.json left local) and pushed (843404d25a..edfdc5da0a). ERP already pushed at fcbcac697a.
- Merge Desk's Stage_Beta PRs 67855 (API) / 67858 (Web) were already merged, so new PRs were opened by the agent (user asked): **API !68373** fx112974 → Stage_Beta, **Web !68374** fx112974 → Stage_Beta; each carries exactly one commit, merge status clean, linked to 112974, awaiting "PR Approval Develop". No Master_Stable PRs exist yet (Merge Desk MergeLive).
- Master_Stable not merged into fx112974 (would pull ~450–650 trunk commits into the stage PRs).
- ADO 112974 → Solved; comment 10021297 (Arabic) with both PRs, issue 1 status and the item-1001 data note.

## Open
- Issue 1 (legacy 0.0001 residue blocks the journal rebuild): decision pending — move lines in place / absorb residue / block.
- Issue 3: fixed locally in iteration 2 (front), uncommitted. `review-2.md`: pass (0 block, 0 should, 2 nits: optional `?.`; flag false until config loads — benign).

## Review (2026-10-25)
- `review-1.md`: pass (0 block, 0 should, 1 nit: no Construction test project, record the manual QA result). Backend reviewer: no findings.

## Commit (2026-10-25)
- `25e34821ab fx112974: show each account-migration blocker message once` (local, not pushed). Local fx112974 vs origin: 15 behind / 661 ahead because of the rebase; push needs `--force-with-lease`.

## Main-checkout mode (requested 2026-10-25)
- Front and Database main checkouts: on `fx112974`, tracking origin, level with it (Front 441 / DB 155 behind Master_Stable, not rebased).
- Set `cr112974` removed (`remove-cr.ps1 -Force -KeepBranch`, user's OK; tree was clean, branch kept). Cloud_ERP main checkout now on `fx112974` at 25e34821ab (rebased: 0 behind Master_Stable; vs origin 661 ahead / 15 behind — do NOT `git pull`, push needs `--force-with-lease`). Foreign untracked `PropertyManager/.github/` left alone.
- Later the same day local `fx112974` was re-created from `origin/fx112974` outside the session (rebase and 25e34821ab dropped). The issue 2 fix was cherry-picked back as **`fcbcac697a`** on top of origin's tip 162695ab4b: 1 ahead / 0 behind origin, NOT rebased (646+ behind Master_Stable again). **Pushed 2026-10-25** (fast-forward 162695ab4b..fcbcac697a); updates the open Merge Desk PRs. Build 0 errors. The rebased tip 25e34821ab is still reachable by hash if wanted.
- Desktop (AccFlex_ERP) main checkout: on `cr94062` with 6 modified files not from this ticket — waiting on the user.

## Next
(done) Commit `fx112974: show each account-migration blocker message once`, then push (updates the open Merge Desk PRs).
