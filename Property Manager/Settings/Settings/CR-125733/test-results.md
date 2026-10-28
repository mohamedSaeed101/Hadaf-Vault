---
type: test-results
cr: 125733
updated: 2026-10-22
tenant: db-all / Sabreen_Primary
api: PropertyManager.API from the set, Debug, https://localhost:2718 (base 1418 + 1300), ASPNETCORE_ENVIRONMENT=Development, Authority accesscontrol.localbeta, DebugTenantConnection → Sabreen_Primary (Application Name cr125733-pm-api)
front: set dev server http://localhost:4200, config.json local-only (propertymanagerapi → localhost:2718, every other URL → localbeta), restored afterwards
---

# CR-125733 — End-to-end results on Sabreen (phase 10)

## Tenant preparation (engineer's OK 2026-10-22)

- Sabreen already had cr125638's two-column `Pm_RealEstateSettings` (0 rows) and module 953. The preview script was regenerated and cut down to the CR's batches only: 1 `ALTER TABLE ADD` (41 columns), 7 `CREATE TABLE`, 2 defaults, 19 FKs ([cr125733-sabreen-schema.sql](cr125733-sabreen-schema.sql)). Result on the tenant: 43 columns, 20 FKs, 2 defaults, 7 lookup tables.
- Seeds ([cr125733-sabreen-seed.sql](cr125733-sabreen-seed.sql)): the set's `0466` script (7 lookups: 4 / 3 / 2 / 2 / 6 / 2 / 2 rows + the settings row), the set's `0328` (row 3), and a guarded insert of module **937**.
- Tenant proof: `sys.dm_exec_sessions` shows `cr125733-pm-api` from this machine on `Sabreen_Primary`; swagger lists the 12 `api/RealEstateSettings*` paths; unauthenticated GET → 401; authenticated GETs → 200 with Sabreen data.

## Acceptance

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | `screenshots/A1-general-tab-seven-tabs.jpg`: header «الضبط العام», 7 tabs, one save icon; 11 GETs → 200 |
| A2 | **pass** (type filter) | `A2-accounts-tab-five-lists.jpg`; liability lists hold 711 leaf liability-type accounts, asset lists 508 leaf asset-type accounts (`/Accounts` response). Sabreen's chart has liability-type accounts numbered `1103…` («للدفعات المقدمة»), so "starts with 2" (AC-7 wording) is a chart property, not a filter property |
| A3 | **pass** | `A3-save-empty-accounts-toast.jpg`: red toast «لا يمكن الحفظ – أكمل الحقول الإلزامية: …», five fields marked invalid, the accounts tab selected, 0 PUT requests, row unchanged. With the country also empty the screen selects the general tab first (first missing field) |
| A4 | **partial** | AE is inactive on Sabreen (active: BH, EG, KW, SA). Hints after save with EG: «نسبة الضريبة من إعدادات الحسابات العامة: 0%» (GL `ValueAddedTaxPercent` = 0; the CountryTax fallback did not yield 14 %) and «العملة المعروضة: EGP» (currency code, not a symbol; the currency hint shows only for the stored country) |
| A5 | **pass** | `A5-grace-days-tooltip.png`: «القسط غير المسدد يصبح «متأخر» بعد مرور هذا العدد من الأيام على استحقاقه. فارغ = 0» |
| A6 | **pass** | `A6-revenue-manual.jpg` / `A6-revenue-automatic.jpg`: «تلقائي» enables the 3-value policy (default «تسليم الوحدة») and the two rent accounts, preview grows from 4 to 7 rows (3 rent journals); «يدوي» disables them again |
| A7 | **pass** (DOM) | `A7-penalties-SA-defaults.jpg`: with SA and nothing saved, treatment placeholder «بدون غرامة مالية – إجراءات التعثر فقط», stage placeholders 7 / 30 / 60 / 90 with actions 2 / 3 / 4 / 6, hint «افتراضي الدولة», the other penalty fields hidden. **Visual gap:** DevExtreme shows these placeholders only on focus with floating labels, so the greyed defaults are not visible at rest |
| A8 | **pass** | `A8-penalties-EG-restored.jpg`; stored row: treatment 1, cap 7.00, start 2, capped 1, contract cap 1, stages (1,1) (31,2) (61,4) (91,5), withholding 5.00, first-home cap 1,000,000 |
| A9 | **pass** | `GET /ProofOfIncomeAndExpenses` → ids 1, 2, 3; `Pm_ProofOfIncomeAndExpenses` holds row 3 (re-seeded once, see incident) |
| A10 | **pass** | `A10-save-success.jpg` (PUT 200, toast «تم حفظ الإعدادات»), `A10-reload-general.jpg`, `A10-reload-penalties.jpg`: every tab returns its values after a full reload; `CustomerGroupId` = 1 (OFFICE) survives; first-save INSERT path not exercised because the row pre-existed (cr125638's seed), the UPDATE path is proven |

## Incident during the run (not a CR defect)

While the test ran, another deploy hit Sabreen (sessions `cr125720-local` from ACCFLEXDEV24 and a SqlClient run from DB-ALL at 16:47). Its reference-data MERGEs deleted rows that are not in its source: `Pm_ProofOfIncomeAndExpenses` row 3 and `Acc_Module` 937 (and 938 of cr125716). The first save then failed with `FK_Pm_RealEstateSettings_Pm_ProofOfIncomeAndExpenses` (`A10-first-save-FK-violation.jpg`); re-running the idempotent seed restored row 3 and the save passed. Module 937 could not be re-inserted: the other deploy renamed module 953 to «Property Manager Real Estate Settings», and `UQ_Acc_Module_ModuleName` rejects a second row with that name. The screen does not need the row (the admin bypass and ModuleId 937 on the controller work without it).

## Findings for the review

1. **Deploy blocker at the Stage_Beta merge:** cr125638's module row 953 carries the same `ModuleName` as our 937 row; `UQ_Acc_Module_ModuleName` makes `0002_Acc_Module_Data.sql` fail unless the 953 declaration and row are dropped in the merge (already planned) — and any tenant that already has 953 needs the MERGE to delete it in the same statement (it does, being one MERGE).
2. «استرجاع افتراضيات الدولة» also overwrites the «القيم الافتراضية» and «الضرائب» fields with the country set (14 / 5 / 5 / ربع سنوي / 10, withholding, first-home cap), not only the penalty tab; the typed reservation validity 7 was replaced by 14. Decide whether that is wanted or scope it to the penalty tab (spec BR-2 names the penalty tab).
3. Greyed defaults (A7) are placeholders invisible at rest with floating labels; consider `labelMode="static"` or a visible hint value.
4. The VAT hint is 0 % on this tenant: GL `ValueAddedTaxPercent` = 0 and the CountryTax fallback did not fill it for EG; check the fallback condition (`0` vs `null`) and the TaxTypeId used.
5. Currency hint shows the code (EGP), not the symbol (known deviation).

## Teardown

API and dev server stopped (ports 2718 / 4200 free), `config.json` restored (clean in git), the local `UserPermissions` patch for 937 removed from the browser, env vars died with the shell. Left on Sabreen: the schema, the lookups, row 3, and one filled settings row (test data; the engineer may clear it).

## Review round 1 gates (2026-10-22)

- `PropertyManager.Application.Test`: **610 passed / 0 failed** (Master_Stable baseline 565 / 0; phase 6 had 608). The two new tests: `RealEstateSettingsPersistenceTests.Create_WhenNoRowExists_InsertsRowOne` (EF InMemory, real `RealEstateSettingsConfigurations`, explicit key 1 inserted and read back) and `GetCountryDefaults_ReturnsTheChosenCountrysCurrencyAndVat`; `GetSettings_WithoutRow_…` now asserts the neutral set.
- sqlproj MSBuild 0 errors; PropertyManager.API build 0 errors; client regenerated (clientgen + api:sync), property-manager `tsc --noEmit` exit 0.
- Not re-run on Sabreen: rows 2 / 3 (penalty-only restore, hints following the chosen country) are front-only and proven by tsc and `npm run testing`, not by a browser run.
