---
type: open-questions
cr: 125487
updated: 2026-10-18
---

# CR-125487 — Open questions

**All answered (2026-10-18):** Q1–Q12 by [[importUnits v2]], Q13 by the engineer in chat. See [[decisions]]. Kept below for the reasoning.

Each question has a recommended answer that the spec and plan already use, so "yes" means no change. Q1–Q4 come from the source note asking for things the cloud does not have; they change the scope.

- [ ] **Q1 Rent prices (الإيجار السنوي, BR-6).** There is no rent-price table, entity or API in the cloud. The Properties screen shows only an empty «أسعار الإيجار» label (`property-main-form.component.html:547`), and `1.05` appears nowhere.
  - **Recommended:** drop the column from this CR. Rent prices arrive with their own CR (screen + model), and the import gains the column then. Storing a value that no screen can show or edit invents the rent model before it is designed.
  - Alternative: this CR adds `Pm_PropertyRentPrice` (PropertyId, AnnualRent, MonthlyRent = annual ÷ 12 × 1.05), written only by the import, with no screen. That is +1 table, +1 entity and +3 files.
- [ ] **Q2 Property history (BR-8 event «تم إنشاء العقار بالاستيراد من Excel – …»).** There is no history/timeline entity or table for properties in the cloud.
  - **Recommended:** no event. The import log (file, user, date, counts) is the audit.
  - Alternative: a new `Pm_PropertyHistory` table + entity written only by the import.
- [ ] **Q3 «متاح» status (BR-8, AC-8).** The cloud has no availability / sales status on a property. The only status is `PropertyStatusId` → `Pm_ProjectStatus`, a tenant-maintained list shared with projects (e.g. «تحت الإنشاء»), which the template's «حالة العقار» column already fills.
  - **Recommended:** no availability status; «حالة العقار» blank → the project's status. AC-8 becomes "status = the row's or the project's; the log row names the file".
- [ ] **Q4 «المبنى» (building) column.** `Pm_Properties` has no building field. In this model a building is a **parent property**: column 5 «رقم العقار الرئيسي», whose serial prefixes its children (business check row 7). So «K» in KWF-K-0501 would be the parent property KWF-K.
  - **Recommended:** drop the column. A building is entered as a parent property row (or an existing one) and named in column 5.
  - Alternative: add `BuildingName nvarchar(100)` to `Pm_Properties` + entity + the screen field. That is a schema change on a shared table.
- [ ] **Q5 Meter numbers.** The note says text, but `ElectricityMeterNumber` / `WaterMeterNumber` are `INT` columns. **Recommended:** accept integers only; anything else → «رقم عداد الكهرباء لازم يكون رقم صحيح». Changing the column type is out of scope. Leading zeros (0501) are lost, the same as on the screen. Confirm that the go-live customer's meter numbers are plain integers.
- [ ] **Q6 «نموذج العقار».** The note says free text, but it is a lookup (`Pm_PropertyModel`). **Recommended:** match by name like the other lists; not found → «… مش من القيم المسموحة».
- [ ] **Q7 Uniqueness.** Nothing enforces a unique number, name or second name today; only `PropertySerial` is unique. **Recommended:** the import enforces all three against the DB and within the file (BR-3 / BR-4: trimmed, case-insensitive). The screen stays as it is, the same call as CR-125486 Q4.
- [ ] **Q8 Inheritance from the project.** On the screen it happens in the browser (`onProjectChanged`), and the user picks the currency. **Recommended:** the import copies these from the project on the server, per BR-5:
  - ownership, sales org, cost center, **currency**
  - country / governorate / city / center, street, land number
  - ProofOfIncome

  It also checks that the project's sales org is linked to the importing user; if not, the row is an error, the same check as the screen's create handler.
- [ ] **Q9 Module id, menu, log table.** **Recommended:**
  - module **935** (934 is CR-125486's), in the same group text «أدوات المشاريع والعقارات» / "Projects & Properties Tools"
  - its own `Pm_PropertyImportLog` table, so the two branches stay independent; the only overlap is adjacent lines in `Module.cs`, `0002_Acc_Module_Data.sql`, `WebMenuItem.cs` and `routes.ts`, resolved at merge
  - no shared import framework between the two CRs for now
- [ ] **Q10 Limits (BR-12).** **Recommended:** 1000 rows and 5 MB per file, the same as CR-125486.
- [ ] **Q12 Blank «نموذج العقار» throws today** (`Property.cs:119` and `:220` read `maybePropertyModel.Value` without a guard; business check row 1).
  - **Recommended:** a one-line guard in each place (`HasValue ? Value.Id : null`, like status, activity and view next to it), so the model stays optional as the note says. This also stops the Properties screen from throwing on a blank model.
  - Alternative: no domain change, and the import makes the model required.
- [ ] **Q11 Note's own open questions.** **Recommended:** no owner column for «لمالكين آخرين» projects; no gas meter, license or construction-date columns. All are added later from the screen.

## Raised during implementation

- [x] **Q14 (answered: NULL + no FK, see [[decisions]]) Column drop vs `BlockOnPossibleDataLoss` (phase 1, 2026-10-18).**
  - **The facts:**
    - `DB.Deployer\Operations.cs` hard-codes `BlockOnPossibleDataLoss = true`.
    - `publish-db.ps1` defaults to true and needs `-AllowDataLoss`.
    - Only `Build\sqlProject-deploy.yaml` (Webserver-dev) passes `False`. The stage Publish / Merge-Publish pipelines only build and copy the dacpac.
    - So upgrading any tenant whose `Pm_Properties` has rows **stops on the drop of `ProofOfIncomeAndExpensesId`**. CR-125486's `Pm_Project.ProofOfIncomeAndExpenses` drop hits the same block.
  - **Recommended:** don't drop the column in this CR. Make it `NULL` in `Pm_Properties.sql` and remove the FK; widening a column is not data loss, so the deploy passes. The code stops using it (already done in phase 2). A later cleanup drops the column with an approved data-loss deploy. Apply the same to CR-125486's project column.
  - **Alternative:** keep the drop, and ops runs this release with data loss allowed on every tenant. That is a deployer or pipeline change, outside the agent.
  - **Blocks:** nothing in the code phases. It must be settled before release and before phase 9 publishes the DB to a test tenant.

- [x] **Q15 (answered: fixed here, see [[decisions]]) Amenity screen vs the regenerated client (phase 8, 2026-10-18).**
  - **The facts:**
    - The front pins `property-manager.api.client` 1.0.108, which types `AmenityDto.Serves` as a **string**.
    - The API has had `int Serves` (an `AmenityType` id: 1 = مشروع, 2 = وحدة) since commit `cc4942e987` (2025-05-13), so every newer client types it as a **number**.
    - The Amenity grid (`modules\amenity\components\amenity-main-grid\amenity-main-grid.component.ts:76,78,100,102,188` and its `tabDataSource` lookup) still uses the strings `'project'` / `'property'`. So today it already sends a string the API cannot bind, and never matches what the API returns. That is a **pre-existing runtime bug**.
    - This CR must bump the client (for `PropertyImportClient`), which turns the bug into 2 compile errors and breaks `npm run testing`.
  - **Recommended:** fix it in this CR. Switch the grid's lookup ids to 1 / 2 and compare against `AmenityType` ids: about 6 lines in one file, needed because the bump forces it. Record it as a reported, out-of-ticket fix in the PR.
  - **Alternative:** a separate Customer Issue / CR that fixes the Amenity grid first, with this CR's release waiting on it.
  - **Blocks:** the front gate going green and release. It does not block review of the import code.

- [x] **Q16 (applied 2026-10-18: `readRows` walks only the rows that hold cells, from the sheet's cell keys, not the `!ref` range; a Node check on `A1:S1048576` with 3 data rows found rows 2, 4, 5 in <1 ms) (review 2, row 18): `readRows` over a huge formatted sheet.**
  - **The problem:** `property-import-excel.service.ts:18-33` still walks the sheet's whole used range. Blank rows don't count toward the 1000-row break, so a sheet formatted down to row 1,048,576 with 3 data rows does about 20M cell lookups and can freeze the tab.
  - **Recommended:** bound the loop at `Math.min(lastRow, MAX_IMPORT_ROWS + 1)`. When the used range goes past that, scan on only until the first non-blank row beyond the limit, and report too-many-rows instead of truncating silently. About 5 lines in one file.
  - **The implementer's view:** the remaining risk is only a sheet that is formatted but blank.
  - **Status:** a `should`, not a block, so it doesn't stop the PR. The engineer decides whether to apply it now or leave it.
