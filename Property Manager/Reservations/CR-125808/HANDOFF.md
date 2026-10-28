# CR-125808 — HANDOFF (Rent Reservations)

- Kind cr, branch `cr125808` (origin, all three repos, off Master_Stable), stage Stage_Beta, Merge Desk #12622 Beta Acknowledge.
- Vault: this folder. Set: not cut yet.
- Size: **L** (new aggregate + DB tables + API + front screen, cross-module invoice/receipt/customer).

| Step | State | Notes |
|---|---|---|
| 0 Preflight | done 2026-10-25 | ADO CR 125808 created (In Development, Mohamed Saeed); Merge Desk #12622 (Beta, contract change, components Database / Property Manager / Web Container); `cr125808` on origin in API / WebContainer / Database |
| 1 Intake | done | `facts.md` (source note only, no attachments) |
| 2 Set | done | `D:\Hadaf-worktrees\cr125808` (db, erp, front), offset 200, all on `cr125808`; front node_modules not linked (package.json differs) → `npm install` with SKIP_INSTALL_SIMPLE_GIT_HOOKS=1 before phase 7 |
| 3 Grill | done | engineer answered Q1–Q4 (`decisions.md`); deferred items in `deffer.md` D1–D7 |
| 4 Spec | done | `spec.md` A1–A11 (agent-written); ADO acceptance comment not posted yet |
| 5 Business check | done, round 1 | `business-check-1.md`: 1 block + 2 should accepted into spec/plan (Q6); KG not cloned, PM has no KG notes |
| 6 Plan | approved 2026-10-25 | `plan.md`, 8 phases, waves A{1,2} B{3} C{4,5} D{6,7} E{8} |
| 7 Implement | done 2026-10-25 | phases 1-8 + fix 7a; all uncommitted (engineer rule); E2E on Sabreen in test-results.md |
| 8 Review | **GATE 6 waiting** | engineer runs `/review-code 125808` |

**Next:** `/review-code 125808`.

## Run log (phase-loop, uncommitted)
- 2026-10-25 ADO acceptance comment A1-A11 posted.
- Phase 2 done: PropertyStatus set copied byte-identical from origin/cr125720 (report + module 956 excluded), settings props added; PM API build 0 errors. PM test project already broken on Master_Stable (CS0535: PriceListTestContext / SalePriceTestContext miss PropertyLogs, QuotationCustomers, RealEstateSettings, SaleQuotations) -> fixed in phase 4. Set HEAD bc2e0aae49 is behind origin/Master_Stable; sync at ship.
- Phase 3 running.
- Phase 3 done: RentReservation aggregate (Create/Update/CanDelete/Confirm/Cancel/Validate/CalculateDeposit), status + payment-method entities, 16 errors ar/en, Property.Reserve/Release, log event types 2/3; build 0 errors.
- Phase 5 running (re-ordered before phase 4: it adds a DbSet the test contexts must also implement; phases 4+6 run together after it).
- Phase 1 done: PropertyStatus table/seed/remap copied byte-identical from cr125720; 2 settings columns; Pm_RentReservation (money DECIMAL(19,4) per db-rules, not 18,3); module row 959; sqlproj. MSBuild 0 errors. Event types: ids 2/3 taken -> 4/5 added into 0464 MERGE (plus id 2 verbatim), PropertyLogEventType.cs updated to 4/5 (open-questions Q1, resolved).
- Phase 5 done: EF config (decimal 19,4), Application RentReservations (5 commands, 5 queries), RentReservationController (10 endpoints, Confirm/Cancel under Edit), GetNextReservationCode, A11 guards, module 959 (Reservation, group 14, order 67), menu 7 Leasing (copied from cr125716) > 7_3 > 7_3_1. Cancel logs only when it was Confirmed. Build 0 errors.
- Wave D running: phases 4+6 (tests, incl. pre-existing test-context fix) and phase 7 (front).
- Phases 4+6 done: pre-existing test-context break fixed (SalePriceTestContext / PriceListTestContext stubs; RentReservations InMemory in PriceListTestContext); 24 RentReservation tests. Then brought cr125720's test updates (BulkScenario, CreateBulkPropertiesCommandHandlerTests, PropertyImportValidatorTests, PropertyStatusTests; GetSalePricesPreviewQueryTests left at HEAD - needs cr125720's own test context) + RentReservations mock in BulkScenario. PropertyManager.Application.Test: 701/701 pass.
- Phase 7 done: client synced via api:sync (25 clients, parity ok); module rent-reservations (shell, list with expired var(--warningColor), form with project->unit cascade and deposit recompute, Confirm/Cancel/Delete with prompts); quick-customer popup reused via its own module + QuickCustomerDataSource token (sale quotations unchanged in behaviour); route ModuleId 959; 38 i18n keys ar/en. npm run testing exit 0, prettier ok.
- Fix phase 7a running (Q2: SalesOrganizationId on the rent-project lookup, drop the Projects-policy call).
- Fix 7a done (Q2): RentProjectLookupDto with SalesOrganizationId, RentReservationDto.SalesOrganizationId; client re-synced; front drops the ProjectClient call. API build 0 errors, 701/701 tests, npm run testing exit 0.
- Phase 8a running: guarded cut-down DB script to db-all / Sabreen_Primary.
- Phase 8 done: DB applied to Sabreen (8a); browser E2E A1-A9 pass, A10 partial, A11 unit-tested only (test-results.md). Torn down: API stopped, config.json restored, no local config in git status.
- Implementation complete, all uncommitted. Next: engineer runs /review-code 125808.
- Review: round 1 (1 block, 7 should, 19 nit) applied; round 2 pass after main closed row 27 (temporary config.json) - [[review-2]]. Gates: DB MSBuild 0 errors, PM API 0 errors, 703/703 tests, npm run testing exit 0. Sabreen Note column narrowed to NVARCHAR(500).
- Next: engineer's continue -> remove-redundant + gates; then commit (engineer's say-so) and ship.

## Shipped 2026-10-25
- remove-redundant: nothing to remove in any repo (listed-only items accepted); moved popup html normalised to CRLF.
- Commits: DB 6d9a203c7, ERP 0a671472e3, Front fb279f636b; merged origin/Master_Stable (conflicts: 0464 event list -> 1,2,4,5; PropertyLogEventType adds SalePriceUpdate=2; sale-quotations.module providers + PriceListClient; duplicate test-context DbSets removed). Gates after merge: DB 0 errors, API 0 errors, 708/708 tests, client re-sync parity ok, npm run testing exit 0.
- Pushed tips: DB e1668dcad, ERP 9a119db7f4, Front 9b4b63cc2a.
- Merge Desk #12622 Solved; ADO 125808 Solved + PR comment. Stage_Beta PRs: API 68388, WebContainer 68389, Database 68390 - all Conflicts (expected add/add; cr125808_Stage_Beta branches only on the engineer's ask; see decisions Q10). Master_Stable PRs come from Merge Desk later.
- Next: explainer video (engineer asked), then set removal decision.
- Demo video recorded (engineer's ask): demo\demo_125808_rent-reservations.mp4, 1:12, Hanafi voice + captions, local set on Sabreen; take created RR-2026-0004 (confirmed then cancelled; unit 4 back to Available). Not attached to ADO yet - waits for the engineer to accept the video.
- Demo accepted by the engineer; attached to ADO 125808 (attachment 9dba5fe8-fc33-434f-82a4-5d87a41f082f, 2.6 MB) + Demo comment. Next: set removal (engineer's call) and the Stage_Beta PR conflicts (68388/89/90).
- 2026-10-25: engineer chose to KEEP the set D:\Hadaf-worktrees\cr125808 for now (offset 200). Open: Stage_Beta PR conflicts 68388/68389/68390 (cr125808_Stage_Beta only on the engineer's ask).
- Front Stage_Beta conflict solved (engineer: 'solve front conflict'): worktree D:\Hadaf-worktrees\cr125808\AccFlex_Cloud_Front_Stage_Beta, branch cr125808_Stage_Beta off origin/Stage_Beta 91774d11826 + merge of origin/cr125808 -> 04872d61a0, pushed. 10 conflicts resolved (popup module unified under shared/, sale-contracts repointed; routes union; i18n key-level union; clients union; property-main-form + real-estate-settings service = Stage_Beta). npm run testing exit 0. PR 68393 -> Stage_Beta (work item 125808); Merge Desk PR 68389 abandoned. API 68388 / DB 68390 still in conflict.
- If Stage_Beta moves: re-merge Stage_Beta into cr125808_Stage_Beta (never into cr125808).
- 2026-10-25: engineer said leave the API (68388) and DB (68390) Stage_Beta conflicts for now. When resumed: same pattern as the Front (cr125808_Stage_Beta per repo; DB 0464 list 1-5 + Stage_Beta's missing comma; ERP menu 7_3 under Stage_Beta's root '7').

## Iterate 1 (2026-10-26) - derived «منتهي» status (change-note-1.md, deffer D6 answer)
- ERP only, uncommitted: RentReservationStatus.Expired (id 5, display-only, not in List / EF / seed); StatusName «منتهي» for Confirmed + ExpiryDate < today in GetAll/GetById; filter 5 = expired, 2 = confirmed not expired; Defaults Statuses include it. Front unchanged (shows backend StatusName; actions key off StatusId 2). 5 new tests.
- Gates: PM API 0 errors, tests 713/713, npm run testing exit 0.
- Next: /review-code 125808 (one round), then commit + push cr125808 (updates the open API PR 68388), then re-merge into cr125808_Stage_Beta only if the Front changes (it did not).
- Iterate 1 review (round 3): pass, 0 block / 0 should; nit B2 fixed (Expired.Id in test), B1 (DisplayStatus pattern like sale quotations) accepted. Tests 713/713. Still uncommitted. Next: commit + push cr125808 on the engineer's say-so (updates API PR 68388; no front change, no re-merge of cr125808_Stage_Beta needed).
