---
type: test-results
cr: 125488
date: 2026-10-19
phase: 8 (end to end)
---

# CR-125488 — Phase 8 end-to-end results

## Setup

- **Tenant:** `db-all` / `Sabreen_Primary`, company **Sabreen** (engineer's choice, Q16). Before the run: 13 projects (10 leaf), 7 properties from CR-125487's test, property types only «سكني» (1) and «تجاري» (2).
- **Schema:** one guarded insert of `Acc_Module` row 936 (scratchpad `cr125488-sabreen-module936.sql`, `IDENTITY_INSERT` on/off, skip if present). Nothing else. CR-125487's earlier changes (nullable «اثبات الإيراد», no FK) were already on the tenant.
- **API:** PropertyManager from the set (Debug, built to the scratchpad), `https://localhost:2318` (1418 + 900), `ASPNETCORE_ENVIRONMENT=Development`, `Authority` = accesscontrol.localbeta, `DebugTenantConnection` as a process variable only.
- **Front:** the set's front on `localhost:4200`, with local-only `config.json` edits (propertymanagerapi → localhost:2318; miscapi and dashboard → localbeta), restored afterwards.
- **Temporary patch (reverted):** the front did not compile because the regenerated client types amenity `Serves` as a number (Q17). With the engineer's OK, CR-125487's `amenity-main-grid.component.ts` was copied in for the run and restored afterwards (`git restore`).
- **Override proof:** `sys.dm_exec_sessions` on db-all: `Sabreen_Primary | cr125488-pm-local | DESKTOP-KPT7EFB | 2026-10-19 10:31`.
- **Sign-in:** the engineer signed in in the browser pane; the agent picked company Sabreen.

## Results

Project used: **NRJ-A** (leaf, sale + rent, activity 1). Sabreen has no RYH project, so A1's codes start `NRJ-A-C-0101`.

| AC | Case | Result | Evidence |
|---|---|---|---|
| A1 | building C, floors 1–4, 3 per floor, garage on | **pass** | Verify response `NewUnits 12, NewGarages 12, Skipped 0, Errors 0`; summary «هيتعمل: 12 عقار + 12 جراج · 0 مكرر · 0 خطأ»; first code `NRJ-A-C-0101` |
| A2 | 900,000 + 15,000 per floor | **pass** | Grid floor 4 at 945,000; saved `NRJ-A-C-0401..0403` `PropertyPrice` 945000 |
| A3 | rerun of the same pattern after a save with garages | **pass** | «هيتعمل: 1 عقار + 1 جراج · 11 مكرر · 0 خطأ»; existing rows «موجود – هيتخطى», 0 error rows (business check row 1) |
| A4 | garage is a child property | **pass** | `NRJ-A-C-0101-G`: floor −1, rooms 0, `ParentPropertyId` 8 (= NRJ-A-C-0101), serial `601` = parent serial `6` + `01`, `PropertyModelId` NULL |
| A5 | garage area 20, price 40,000 on a sale project | **pass** | all 11 garages area 20.00, price 40000, type 2 «تجاري» |
| A6 | blank activity → project activity | **pass** | units and garages `PropertyActivityId` 1 = NRJ-A's (the NULL-activity case not run here) |
| A7 | code existing in another project, lower case | **pass** | `t125487-03` (exists as `T125487-03` in project ZZZ) → «موجود – هيتخطى»; not created, no garage |
| A8 | > 500 rows | **pass** | to-floor 100 → «الحد الأقصى 500 سطر مع الجراجات – الدفعة فيها 600 سطر», save disabled |
| A9 | leaf projects only | **pass** | dropdown lists NRJ-A, NRJ-B, ZZZ, NOCC, QDS, ALF-A, ALF-B, HDQ, BRJ-A, BRJ-B; no NRJ / ALF / BRJ |
| A10 | edited row values | **pass** | `NRJ-A-C-0101` area 140.00, price 777000 |
| A11 | duplicate codes in the grid | **pass** | both rows «خطأ: متكرر في الجدول», summary «10 عقار + 10 جراج · 0 مكرر · 2 خطأ», save disabled |

**Also verified:**
- **BR-3:** a pattern change on a clean grid rebuilds it (to-floor 100 → 4); on an edited grid the rows stay and «النمط اتغير بعد تعديل الجدول – التعديلات لسه موجودة…» shows.
- **Q15:** blank «مساحة الجراج» → field invalid, save disabled.
- **Q5 default:** no type named «شقة» / «جراج» on Sabreen → both type fields start empty and must be picked.
- **Inheritance (SQL):** status 1, ownership 1, sales org 1, cost center 5, currency 1, country / governorate / city 193 / 2 / 2 = project NRJ-A; investment type [1]; «اثبات الإيراد» 1; names «سكني NRJ-A-C-0101» / «Residential NRJ-A-C-0101», garages «تجاري … -G» / «Commercial … -G».
- **Menu:** `GET api/MenuList` from the local API returns group "5" «أدوات المشاريع والعقارات» with item `5_3` «توليد العقارات», module 936, route `property-bulk-generation`.
- After save the screen navigated to the Properties list (22 created = 11 units + 11 garages).

## Findings for the review (not blocking)

- **Code-pattern input shows mirrored** (`{U}{F}-{B}-{P}`) in RTL: the input needs `dir="ltr"`.
- **Grid overflows sideways** once the rebuild warning line is shown; the delete column is clipped.
- The «تم إنشاء N عقار» message was not captured (the page navigated before it was read); the create returned 200 and the rows are in SQL.

## Not covered

- A project with NULL activity or NULL currency (all Sabreen leaf projects have currency 1).
- Rollback on a mid-batch failure against SQL (unit tests prove rollback is called; no fault injection here).
- Non-sale project (price forced to 0): Sabreen has no project without بيع.
- A non-admin user without module 936.
- The «توليد عقارات» button on the Properties list: opening Properties in this mixed local session bounces to localbeta (the same environment effect CR-125487 recorded).

## Data left on Sabreen_Primary

- `Acc_Module` row 936.
- Properties 8–29: `NRJ-A-C-0101`, `-0103`, `-0201` … `-0403` (11 units) and their `-G` garages (11), project NRJ-A.

They stay as test data; remove them only on the engineer's word.

## Explainer video (2026-10-19)

`demo_125488_bulk-units_Iapetus.mp4` (2:04, Arabic captions + Hanafi's voice), recorded on Sabreen with module **946**, project NRJ-B, building D: pattern, leaf-only project list, garage type/area/price, grid of 12 + 12, row edit (777,000 / 140) + rebuild warning, «متكرر في الجدول», «موجود – هيتخطى» (nrj-a-c-0101), save → «تم إنشاء 22 عقار». The two review fixes were visible and correct: the code pattern reads LTR and the grid no longer overflows.

**Finding (not fixed):** after a pattern change on an edited grid, the statuses and summary reset to blank / 0 and Save stays disabled until the next grid edit triggers a verify.

**Data added on Sabreen_Primary:** `Acc_Module` **946**; the old test row 936 renamed «… (old 936)» / `PropertyBulkGenerationOld936` (ModuleName is unique); 22 properties in NRJ-B (`NRJ-B-D-*` units + `-G` garages, row 3 skipped as `nrj-a-c-0101` exists).
