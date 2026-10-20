---
type: open-questions
cr: 125488
updated: 2026-10-18
---

# CR-125488 — Open questions (all answered in [[bulk Units V2]], see [[decisions]])

Each question has a recommended answer that [[spec]] and [[plan]] already use, so "yes" means no change. Q1, Q2 and Q4 are the same gaps as CR-125487 Q1–Q4; answer them the same way for both CRs unless you want the two tools to differ.

- [x] **Q1 Rent (الإيجار السنوي, BR-6, BR-7 garage rent).** The cloud has no rent-price table, entity or screen.
  - **Recommended:** no rent column in the grid, nothing stored; rent arrives with its own CR.
  - Alternative: the `Pm_PropertyRentPrice` table CR-125487 Q1 describes (annual, monthly = annual ÷ 12 × 1.05), shared by both CRs, so whichever lands first adds it.
- [x] **Q2 History event (BR-8) and the «متاح» status (BR-5).** No property history entity exists; the only status is `PropertyStatusId` → `Pm_ProjectStatus`, a tenant list shared with projects.
  - **Recommended:** no history event; status = the project's status.
- [x] **Q3 `{P}` = which project field?** AC-1's «RYH» is alphanumeric, so it is `ProjectNumber` (user text), not `ProjectSerial` (numeric). **Recommended:** `ProjectNumber` (NOT NULL, so it is always there).
- [x] **Q4 Building (`{B}`).** `Pm_Properties` has no building field. **Recommended:** the building is text in the code only, not stored. Alternative: generate a parent property per building, which would make the garage a grandchild; not recommended.
- [x] **Q5 Type list.** The note lists fixed types (شقة … مخزن); the cloud type is the tenant lookup `Pm_ProjectType`. **Recommended:** the pattern's «النوع» and the grid's type use the tenant lookup; the garage type is its own pattern lookup «نوع الجراج», defaulted to the type named «جراج» / "Garage" and required when the garage option is on.
- [x] **Q6 Usage (سكني / تجاري / إداري).** **Recommended:** map to «نشاط العقار» (`PropertyActivityId`, tenant lookup `Pm_ProjectActivities`); optional; blank → the project's activity. Garages take the unit's activity.
- [x] **Q7 Garage values (the note's own question).** Area 15 and price 35,000 are tenant- and currency-specific. **Recommended:** two pattern inputs «مساحة الجراج» (default 15) and «سعر الجراج» (default 35,000), shown with the option; floor −1 and rooms 0 stay fixed.
- [x] **Q8 «عقارات مركبة» tab (BR-7, AC-4).** There is no such tab or entity; the cloud link is `ParentPropertyId`. **Recommended:** the garage is a child property of its unit; AC-4 is verified on the child's «العقار الرئيسي» field and in SQL. No new tab.
- [x] **Q9 Layout G1 and the blank model.** The cloud has `PropertyModelId` (lookup), and a blank model throws today at `Property.cs:119` / `:220` (CR-125487 Q12). **Recommended:** no model on generated units or garages; add the same one-line guard as CR-125487 (`HasValue ? Value.Id : null`), identical text so the second merge is clean.
  - Note (business check row 4): the guard also makes a model-less save legal on the Properties screen (today it is a 500). Decide once for both CRs; the alternative is a required «نموذج العقار» pattern input here.
- [x] **Q10 Batch limit (BR-9).** **Recommended:** 500 rows per save, counting garages (250 units with garages).
- [x] **Q11 «استيراد العقارات» button.** Its screen is CR-125487 (module 935), not merged yet. **Recommended:** the button routes to `property-import` and shows only when the user has module 935, so it stays hidden until that CR lands.
- [x] **Q12 Cost center (the note's D32 question).** **Recommended:** inherit the project's cost center; no cost center per unit.
  - Note (business check row 5): the Properties screen offers only parent (non-leaf) cost centers; if CR-125486 gives projects leaf centers, the generated units carry a center the screen cannot show. Confirm with the PO.
- [x] **Q14 Serial collision (business check row 9).** Root serial = MAX(root) + 1; a child serial = parent serial + `01`. Garage `1201` (parent 12) equals the serial the 1201st root unit would get, and bulk generation reaches that range sooner. **Recommended:** keep the existing scheme (changing it is out of scope); a clash fails the batch with «تعارض في كود العقار – أعد المحاولة» and creates nothing. Raise the scheme as its own CR.
- [x] **Q13 "Already exists" scope (AC-3).** `PropertyNumber` is not unique in the DB. **Recommended:** a code exists when any property in the tenant has the same number (trimmed, case-insensitive), not only in the chosen project, so codes stay unique company-wide.

## Raised during implementation (phase-loop, 2026-10-18)

- [x] **Q16 Phase 8 tenant (answered 2026-10-19: db-all / Sabreen_Primary, row 936 published; see [[test-results]]) (blocks phase 8 only).** End to end needs a tenant DB with module row 936 (and the user's permission on 936) and the PropertyManager API on base port + 900. Local SQL logins fail on this machine, so it must be a reachable tenant. **Recommended:** name the tenant (e.g. your local beta tenant) and OK a targeted publish of the 936 row via `db-change` / `publish-db.ps1 -Id cr125488`; the agent then runs A1–A11 and writes `test-results.md`.
- [ ] **Q17 Client drift at release (not this CR's code).** Regenerating `property-manager.api.client` from the current backend types amenity `Serves` as a number, so `amenity\components\amenity-main-grid\amenity-main-grid.component.ts:76,78` (`=== 'project'` / `'property'`) fails TS2367. It is in the baseline build too once the new client is in `node_modules`. **Recommended:** at `release-ticket`, before publishing the client, raise it with the amenity owner (or a one-line fix in its own ticket); this CR does not touch amenity.
