---
type: spec
cr: 125488
size: L
updated: 2026-10-18
status: decided; Q1–Q14 answered in [[bulk Units V2]] ([[decisions]])
sources: "[[facts]], [[bulk Units V2]], [[decisions]]"
---

# CR-125488 — Spec: Bulk generate properties (توليد العقارات)

Grilling path: the agent grilled itself against [[facts]] and the code (no `Accflex_KG` exists). The 14 questions it raised were answered in [[bulk Units V2]]; [[decisions]] holds them.

## Problem Statement

A real-estate customer sets up buildings with dozens of near-identical units (same type, area, rooms, a price that steps by floor, often a garage each). The Properties screen creates one unit at a time and needs every inherited field picked by hand, so go-live data entry is slow and inconsistent.

## Solution

A settings tool «توليد العقارات» (module **936**, group «أدوات المشاريع والعقارات», route `property-bulk-generation`), also opened from a «توليد عقارات» button on the properties list:

1. The user fills the **pattern**: a leaf project, building, floor range, units per floor, code pattern, type, usage, area, rooms, first-floor price, increase per floor, annual rent, and the linked-garage option.
2. The front expands the pattern into an **editable grid**, one row per unit, and asks the server to **verify** it; every row gets a status: جديد / موجود – هيتخطى / خطأ (with its messages) / مش هيتعمل.
3. The user edits cells, adds or deletes rows, unticks «إنشاء».
4. **Save** sends the grid to the server, which re-verifies it and creates every «جديد» row and its garage in **one transaction** (all or nothing), then the front shows «تم إنشاء N عقار» (N includes garages) and opens the properties list.

The grid is the authority at save time (A10): the server never re-expands the pattern; it receives explicit rows.

## User Stories

1. As a setup user, I pick only leaf projects, so units never land on a parent project (BR-1, A9).
2. As a setup user, I type `{P}-{B}-{F}{U}` once and see every code, so codes are consistent (A1).
3. As a setup user, prices step by floor without typing each (BR-5, A2).
4. As a setup user, I see which codes already exist and they are skipped, so a rerun is safe (A3, A7).
5. As a setup user, I get a garage per unit linked as a child property (BR-7, A4).
6. As a setup user, my cell edits survive a pattern change until I press rebuild (BR-3).
7. As a setup user, I cannot save while any row is an error, and I see how many (BR-12, A11).
8. As a setup user, a failure halfway creates nothing (BR-9).

## Implementation Decisions

### Field mapping (pattern → `Property`)

| Spec | Cloud field | Rule |
|---|---|---|
| Project | `ProjectId` | leaf project (no `ChildrenProjects`); new lookup query returns Id, `ProjectNumber`, name, investment type ids |
| `{P}` | `Project.ProjectNumber` | the user's project code (RYH), not the numeric `ProjectSerial`; NOT NULL, so always present (Q3) |
| `{B}` building | — | text only, used in the code; not stored (Q4) |
| `{F}` / `{U}` | — | floor / unit index, 2 digits zero-padded; a negative floor keeps its sign (`-1` → `-01`) |
| Code | `PropertyNumber` | trimmed |
| Floor | `NoOfFloor` | integer |
| Type | `PropertyTypeId` | tenant lookup `Pm_ProjectType` (the screen's list), not a fixed list (Q5) |
| Usage | `PropertyActivityId` | tenant lookup `Pm_ProjectActivities` (Q6); blank → the project's activity; the project's activity is nullable, so null stays null (business check 2 row 17) |
| Area | `PropertyAreaInMeter` | > 0 |
| Rooms | `NoOfRoom` | ≥ 0, blank → 0 |
| Sale price | `PropertyPrice` | grid value; forced to 0 when the investment type is not بيع (BR-6) |
| Name / second name | `PropertyName` / `PropertyNameSecondLanguage` | type name + « » + code, in each language (BR-5) |
| pcode | `PropertySerial` | `GetNextPropertyCode(null)` per main unit; `GetNextPropertyCode(main)` for its garage, which yields main + `01` (BR-7) |
| Status «متاح» | `PropertyStatusId` | the project's status (Q2; no availability status exists) |
| Investment type | `PropertyInvestmentTypeList` | [بيع] when the project has بيع, else [the project's type with the lowest `InvestmentTypeId`] (BR-4; the list has no order, row 3) |
| Inherited | ownership, sales org, cost center, view, currency, country / governorate / city / center, street, land number | copied from the project on the **server** (V2 BR-4; same call as CR-125487 Q8) |
| «اثبات الإيراد» | `ProofOfIncomeAndExpensesId` | not inherited: the field is being removed (CR-125486 Q2/Q11, CR-125487 Q13). While it exists on `Master_Stable`, the bulk handler sets id 1 (the DB default) in one line; whichever of this CR and CR-125487 merges second deletes that line (business check 2 row 13) |
| Model | `PropertyModelId` | empty; needs the blank-model guard at `Property.cs:119` / `:220` (Q9) |
| Annual rent / rent prices | — | not stored: no rent model in the cloud (Q1); the column is not shown |
| History event | — | not written: no history entity (Q2) |
| Cost | — | none (BR-5) |

### Linked garage (BR-7)

- Code `<unit code>-G`, floor −1, rooms 0, `ParentPropertyId` = the generated unit, same project, inherited fields as its unit, same investment type rule.
- Type: a «نوع الجراج» lookup in the pattern, shown and required when the garage option is on, defaulting to the first **active** type whose name or second name is «جراج» / "Garage" (trimmed, case-insensitive); none → empty and the user picks (Q5, business check 2 row 18).
- Area and price: two pattern inputs «مساحة الجراج» (default 15) and «سعر الجراج» (default 35,000), shown with the option (Q7). With the option on, the area is **required and > 0** and the price is ≥ 0 (blank = 0); the server enforces both as request-level checks (Q15, engineer 2026-10-18). Layout G1 and garage rent are dropped (Q1, Q9).
- The «عقارات مركبة» tab of the source is the existing parent/child link; no new tab (Q8).

### Row check (server `VerifyBulkPropertiesCommand`, also run inside save)

Per row, in this order, every message collected:
- «إنشاء» unticked → **مش هيتعمل**, no other check.
- code blank → «الكود فاضي»; floor blank → «الدور فاضي»; area ≤ 0 → «المساحة لازم أكبر من صفر»; price < 0 → «سعر بالسالب»; type missing → the domain's message.
- code repeated among the rows to create (trimmed, case-insensitive) → «متكرر في الجدول» on every copy.
- code already a `PropertyNumber` in the tenant (trimmed, case-insensitive) → **موجود – هيتخطى**, no garage for it, no further check. This runs **before** the garage check, so a rerun after a save with garages skips instead of failing (business check row 1).
- only for a row still «جديد»: garage on and `<code>-G` already exists as a `PropertyNumber` or repeats in the grid → «كود الجراج موجود».
- otherwise → **جديد**. Then `Property.Create` on the built poco without saving (`ValidateProperties` is `internal`), so the domain rules stay the single source (row 12).

Request-level checks: required pattern inputs, leaf project (BR-1 «اختر مشروعاً فرعياً»), the project has a currency («المشروع ليس له عملة»; `Pm_Project.CurrencyId` is nullable on legacy rows, row 2), the project's sales org linked to the user (same check as `CreatePropertyCommand.cs:145-151`), and at most **500 rows** per batch (Q10), counted once, the same way in the front summary and on the server: the rows with «إنشاء» ticked plus one for each of them with «جراج مرتبط» ticked, counted before the exists check; over the limit → «الحد الأقصى 500 سطر» (business check 2 row 15). The pattern must hold `{F}` and `{U}`; that check is in the front, since the server receives rows.

The "exists" check is best effort: `PropertyNumber` has no DB constraint, so two users generating the same codes at the same moment can both insert (row 11). Accepted for a setup tool.

### Save (`CreateBulkPropertiesCommand`)

- Re-runs the verify; any error row → failure with the count («فيه N سطر فيه أخطاء»); no «جديد» row → failure.
- One transaction. In grid order, per main unit: next serial, build the poco, `Property.Create`, add, `SaveChanges` (the serial reads MAX from the DB, so it saves per unit, like CR-125487); then its garage with the unit as parent.
- Returns the count created (units + garages).
- A `UQ_Pm_Properties_PropertySerial` failure rolls back and returns «تعارض في كود العقار – أعد المحاولة», never the name-duplicate message (row 9, Q14).

### Front

- New NgModule `property-bulk-generation` in `projects\property-manager\src\app\modules\`, page without search (`feature-without-search.md`).
- Pattern form (reactive form; «نوع الجراج», «مساحة الجراج», «سعر الجراج» shown with the garage option), over 500 rows → a warning and the save button disabled (A8), the summary line «هيتعمل: N عقار + N جراج · M مكرر · K خطأ», rebuild and save buttons, a DevExtreme grid with cell editing, a create checkbox, a delete column and «إضافة سطر» (new row with pattern values, floor = to-floor).
- Pattern expansion is a pure function `buildRowsFromPattern(pattern, project)` (BR-2, BR-5 price formula, code pattern).
- Dirty flag: any grid edit, add or delete sets it; a pattern change rebuilds when clean, else shows the rebuild warning (BR-3).
- Verify is called (debounced 400 ms) after a rebuild and after each grid edit; the status column and the summary come from its answer.
- Toolbar «استيراد العقارات» → route `property-import` (CR-125487), shown only when the user has module 935 (Q11).
- Properties list: a «توليد عقارات» button → the new route, shown with module 936.
- i18n ar-EG + en-US in `property-manager.json`.

## Acceptance (A1..A11 = V2 AC-1..AC-11, posted to ADO)

- A1 Project RYH, building C, floors 1–4, 3 per floor, garage on → «12 عقار + 12 جراج», first code RYH-C-0101.
- A2 First-floor price 900,000, increase 15,000 → floor-4 units at 945,000.
- A3 RYH-C-0101 already exists → «موجود – هيتخطى», not created again, no garage for it.
- A4 After save, RYH-C-0101-G exists on floor −1, its «العقار الرئيسي» = RYH-C-0101, pcode = parent pcode + `01`, no model, no rent.
- A5 On a project that includes بيع: garage area 20 and price 40,000 → the garages are created with these values (on a non-sale project the price is 0, BR-6).
- A6 Blank «نشاط العقار» → units and garages take the project's activity (none when the project has none).
- A7 A code that exists in another project (even in lower case) → «موجود – هيتخطى».
- A8 More than 500 rows including garages → a warning and the save button disabled.
- A9 The project list shows no project that has sub-projects.
- A10 First row edited to 777,000 and area 140 → the unit is created with these values.
- A11 Two equal codes in the grid → «متكرر في الجدول» and save refused until fixed or unticked.

## Testing Decisions

- Unit tests (`PropertyManager.Application.Test`, `testing-standard.md`) on the verify and save handlers: A3, A4 (parent + serial), A5, A6, A7, A8 (server limit), A10, A11, each error message, inheritance from the project, investment type rule (sale vs first type, price 0), the sales-org check, the 500-row limit, the leaf-project rule, and all-or-nothing (a failure on the last unit leaves zero rows).
- Front: `buildRowsFromPattern` is pure; A1 and A2 are checked end to end, plus a spec file if the property-manager project runs specs (it does not today; then end to end only).
- End to end on a tenant via `local-api-run` (PropertyManager on base + 900): A1–A11 with screenshots and SQL proof in `test-results.md`.

## Out of Scope

- Rent prices, property history, an availability status, a building field (Q1, Q2, Q4); a new «composite units» tab (Q8).
- Excel import (CR 125487); updating existing units.
- Desktop (AccFlex_ERP) and project cost distribution.

## Further Notes

- Shares the menu group and the blank-model guard with CR-125487; the guard is the identical one-line change in both branches, so the second merge sees no conflict if both keep it identical.
- Module ids: 934 (CR-125486), 935 (CR-125487), **936** (this CR).
- Existing mismatch, no change here: `Pm_Project.CurrencyId` → `Acc_Currency` while `Pm_Properties.CurrencyId` → `ACFX_Currency`; the Properties screen copies it the same way (business check 2 row 19).
