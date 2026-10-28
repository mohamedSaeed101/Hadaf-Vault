---
type: decisions
cr: 125733
updated: 2026-10-22
---

# CR-125733 — Decisions (engineer, 2026-10-22, one by one)

| Q | Decision | Differs from recommendation |
|---|---|---|
| Q1 | Extend cr125638's `Pm_RealEstateSettings` / module 953 / route `real-estate-settings` now on Master_Stable, same file and class names; add/add conflicts resolved on `cr125733_Stage_Beta` | no |
| Q2 | New group 5_3 «الإعدادات والصلاحيات», item 5_3_1; title «الضبط العام» (i18n only) | no |
| Q3 | `Pm_ProofOfIncomeAndExpenses` gets row 3 «نسبة الإنجاز (البيع على الخارطة)»; rows 1 and 2 kept and shown; default 2; enabled only with automatic journals | no |
| Q4 | Five mandatory accounts (BR-6 included); AC-7 reads 5 lists | no |
| Q5 | VAT hint from `Acc_SystemConfiguration.Tax`, fallback `ACFX_CountryTax.TaxPercentage`; display only | no |
| Q6 | Seven PM lookup tables + one reference-data script + static lists + a GET per lookup | no |
| Q7 | `CountryId` FK to `ACFX_Country`; the list shows **every active country** (not only SA / AE / EG); country defaults exist for SA / AE / EG, any other code gets the UAE-like neutral set (financial penalty, 0 % cap, after grace, no contract cap, stages 7 / 30 / 60 / 90, withholding 0) | **yes** |
| Q8 | Dunning stages as **fixed four slots on the settings row** (`Stage1FromDay`, `Stage1ActionId` … `Stage4FromDay`, `Stage4ActionId`, all nullable); **no child table** | **yes** |
| Q9 | Consumers, the Ejar client and the D41 application stay out; the journal preview is static text per policy | no |
| Q10 | Module id **937** instead of reusing cr125638's 953 (937 is unused on every remote branch of both repos). The controller reads `Module.PropertyManagerRealEstateSettings.ModuleId`; the front route and the DB row carry 937. At the Stage_Beta merge cr125638's 953 declaration and row for RealEstateSettings are dropped | **yes** (engineer, after the plan gate); **superseded by Q11** |
| Q11 | Module id back to **953** with cr125638's English name "Property Manager Real Estate Settings" (engineer, 2026-10-25, after the release: "make it 953"), so the Stage_Beta add/add on Module.cs / 0002 / routes.ts collapses to one line; Arabic name stays «الضبط العام» (the screen title of the source note; cr125638's row says «إعدادات التسويق العقاري»), menu stays 5_3_1 (cr125638's 5_1_6 is still dropped at the merge). No `UQ_Acc_Module_ModuleName` clash: same id, same name | **yes** (engineer) |

## Review round 1 (2026-10-22)

| Row | Decision |
|---|---|
| R1-1 | No stored country → the neutral defaults (`ForCountryCode(null)`), not Saudi; the `"SA"` fallback is gone (Q7) |
| R1-2 | «استرجاع افتراضيات الدولة» refills only the penalty-tab controls (treatment, cap, start, capped-at-principal, contract cap, the four stages); the other tabs keep what was typed |
| R1-3/4 | The currency and VAT hints moved into `RealEstateCountryDefaultsDto` (`CurrencyCode`, `VatPercentage`), returned by both `GET RealEstateSettings` (in `Defaults`) and `GET CountryDefaults/{countryId}`; `RealEstateSettingsDto.CurrencySymbol` / `VatPercentage` removed (never shipped). One lookup helper `RealEstateSettings\Common\RealEstateCountryLookup.cs` serves both queries |
| R1-5 | Module 937 is named "Property Manager General Settings" / «الضبط العام» (Module.cs and 0002), distinct from cr125638's 953 under `UQ_Acc_Module_ModuleName`; `ModuleNameForUI` stays `RealEstateSettings` (no unique index on it) |
| R1-7 | In «يدوي» mode the disabled policy and the two rent accounts are saved as they are (`getRawValue`); switching to manual keeps them, so switching back restores them. Consumers in later CRs read them only when `CreateJournalsManually = 0` |
| R1-8 | AC-9 / spec D9 "shows the server message": what ships is a client-side required check naming the fields and switching to their tab; server field errors (D5 / D8) are swallowed by `ServerErrorInterceptor` and only guard the API |
| R1-12 | `FirstHomeTaxExemptionCap` is `DECIMAL(19,4)` (money), correcting spec D2's 18,2; db-rules §Schema Change Rules 2 wins |
| R1-13 | `PenaltyCappedAtPrincipal`, `EjarDefaultPaymentForCommercial`, `EInvoiceExemptInstallments` stay `BIT NULL` — **rule bent:** db-rules §Data Types (bit NOT NULL with a default). Null means "not set → country / BR-5 default" (D7); a NOT NULL default would lose that |
| R1-17 | The 7 new lookup tables keep a PK column named `Id` — **rule bent:** accflex-erp-data.md §Database and Mapping Conventions (`<Entity>Id`). Matches the newer PM lookup precedent (`Pm_ContractType`, Stage_Beta's installment-plan lookups) and the fixed-id seed in 0466 |
| R1-28 | The FormGroup lives in the DataService and the tab presenters inject it, without `formState$` — **rule bent:** accflex-erp.md §Feature Module Architecture (feature-without-search shape); precedent `logistics-settings` |
