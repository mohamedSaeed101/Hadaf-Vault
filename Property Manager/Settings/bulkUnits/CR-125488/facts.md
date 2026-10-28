---
type: facts
cr: 125488
updated: 2026-10-18
source: "[[bulkUnits]]"
---

# CR-125488 — Facts: Bulk generate properties (توليد العقارات `set.bulkUnits`)

- **ADO:** Change Request 125488, created by the agent at the engineer's request (2026-10-18), In Development. Fields copied from sibling CR 125487 (area `3- Customer Issues`, Program Property Manager, customer نواصى العقارية, version 7.0.82.x, due 2026-11-01).
  https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125488
- **Merge Desk:** ticket #12540, Beta, Acknowledge, owner Mohamed Saeed, repos API / WebContainer / Database, contract change on. Branch `cr125488` on origin in all three.
- **Source:** [[bulkUnits]] (the only source; the ADO description is a summary of it). No attachments.
- **Module / surface:** Property Manager (cloud): `AccFlex_Cloud_ERP\...\PropertyManager\`, front project `property-manager`, DB `Pm_*`. Desktop not touched.
- **Environment:** Stage Beta (first PR → `Stage_Beta`, second → `Master_Stable`).
- **Siblings:** CR 125486 (import projects, module 934) and CR 125487 (import units, module 935), same menu group «أدوات المشاريع والعقارات». Neither is implemented yet.

## Scope (one source per point: [[bulkUnits]])

1. New screen «توليد العقارات» under إعدادات العقارات › أدوات المشاريع والعقارات, plus a «توليد عقارات» button on the properties list; after save it opens the properties list. (§الوصول والتدفق)
2. Pattern group: project (leaf projects only), building, from floor, to floor, units per floor, code pattern `{P}-{B}-{F}{U}`, type, usage, area, rooms, first-floor price, increase per floor, annual rent, linked-garage checkbox. (§الحقول 1–14)
3. Editable grid built from the pattern: create flag, code, floor, type, area, rooms, sale price, annual rent, linked garage, check status; add row, delete row. (§الحقول 15–24, §الأزرار)
4. Summary line «هيتعمل: N عقار + N جراج» with duplicate and error counts; rebuild-from-pattern button; save button. (§ترتيب الشاشة, BR-2)
5. Row check status: جديد / موجود – هيتخطى / خطأ (6 messages) / مش هيتعمل. (§أعمدة القائمة 7)
6. Rebuild rule: auto-rebuild until the user edits the grid; then a warning and an explicit rebuild. (BR-3)
7. Inheritance from the project (ownership, geography, land number, sales org, cost center, view, revenue recognition, status, currency, investment type). (BR-4)
8. Values: price = first-floor price + increase × (floor − from floor); name = type name + code; status «متاح»; auto pcode; no cost. (BR-5)
9. Non-sale → price 0; rent → rent prices (annual, monthly = annual ÷ 12 × 1.05). (BR-6)
10. Linked garage: code `<code>-G`, floor −1, type garage, residential, area 15, rooms 0, layout G1, price 35,000, rent 3,000, parent = the generated unit, pcode = parent pcode + `01`. (BR-7)
11. History event «تم إنشاء العقار بالتوليد الجماعي» on each main unit. (BR-8)
12. Required inputs enforced, pattern must hold `{F}` and `{U}`, batch limit, all-or-nothing. (BR-9)
13. Save blocked on any error row; skip and not-created rows ignored; save disabled with no new row. (BR-10, BR-11)
14. Acceptance AC-1…AC-7. (§معايير القبول)
15. Note's own open questions: garage values fixed or inputs; duplicate codes inside one batch; cost center per unit (D32) or the project's. (§أسئلة مفتوحة)

## Code facts (scouts, read on `Master_Stable` via the cr125487 set)

- `Property` aggregate `PropertyManager.Logic\PropertyAggregate\Property.cs`: `PropertySerial` (pcode, unique `UQ_Pm_Properties_PropertySerial`), `PropertyNumber` (رقم العقار, user text, not unique), `PropertyName` + `PropertyNameSecondLanguage` (both required; a DB duplicate → `CannotDuplicateNameOrNameSecondLanguage`), `ProjectId`, `ParentPropertyId` / `ChildrenProperties`, `PropertyTypeId` (required, lookup `Pm_ProjectType` shared with projects), `PropertyActivityId` (`Pm_ProjectActivities`), `PropertyStatusId` (`Pm_ProjectStatus`), `PropertyModelId` (`Pm_PropertyModel`), `NoOfFloor`, `NoOfRoom`, `PropertyAreaInMeter`, `PropertyPrice`, `CurrencyId`, `ProofOfIncomeAndExpensesId`, geography, `PropertyInvestmentTypeList`.
- Domain rules `Property.ValidateProperties` (`Property.cs:271`): number, name, second name, type, country, governorate, city, currency, ≥ 1 investment type.
- Create path `CreatePropertyCommand.cs:194-265`: `GetNextPropertyCode(parent)` → `PropertyPoco` → `Property.Create` → `SaveChangesWithValidation`.
- `GetNextCodeService.GetNextPropertyCode` (`PropertyManager.Application\Shared\GetNextCodeService.cs:49`): with a parent, parent serial + next child count (`01` for the first child), which is exactly BR-7's garage pcode; without a parent, MAX(root serial) + 1 read from the DB.
- `Project`: `ProjectNumber` (user text, the `{P}` in AC-1 «RYH»), `ProjectSerial` (numeric), `ParentProjectId` / `ChildrenProjects`, `ProjectInvestmentTypeList`, and the fields BR-4 inherits.
- `Pm_InvestmentType` static: 1 بيع, 2 إيجار, 3 إدارة, 4 خارج الخدمة.
- Not in the cloud: rent prices, property history, an availability status «متاح», a building field, a «composite units» tab (the only link is `ParentPropertyId`). Same findings as CR-125487 Q1–Q4.
- Blank `PropertyModel` throws at `Property.cs:119` and `:220` (CR-125487 Q12).
- KG: no `Accflex_KG` folder in the workspace; no Property Manager entity notes (Settings.md D46).
