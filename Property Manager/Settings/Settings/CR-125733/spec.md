---
type: spec
cr: 125733
updated: 2026-10-22
source: "[[facts]], [[Settings]]"
---

# CR-125733 — Spec: Real Estate General Settings (الضبط العام)

Grilling path: the agent interviewed itself against [[facts]] and the source note (`grill-with-docs` process); the KG repo `Accflex_KG` is not cloned in this workspace, so GL rules were read from code. The questions the sources leave open are in [[open-questions]] (Q1–Q9) with recommended answers; answered one by one on 2026-10-22, recorded in [[decisions]]; Q7 and Q8 differ from the recommendation and this spec reflects the decisions.

> **Module id: 937 (engineer, 2026-10-22) then back to 953 with cr125638's English name (engineer, 2026-10-25, "make it 953", decisions Q11); Arabic «الضبط العام», menu 5_3_1.**

## Problem Statement

Property Manager has no company-level settings: the country, the module's GL accounts, document defaults, the revenue-recognition policy (removed from project and property on 18/10), penalty handling and government-integration parameters have nowhere to live. cr125638 started a one-row `Pm_RealEstateSettings` with a single field. Every upcoming screen (reservations, contracts, invoices, penalties) will read these values.

## Solution

Extend the one-row `Pm_RealEstateSettings` record (module 953, route `real-estate-settings`) into the seven-tab «الضبط العام» screen of the source note: the same `GET` / `PUT api/RealEstateSettings`, plus lookup and account endpoints, a country-defaults endpoint for «استرجاع افتراضيات الدولة», and a child table for the dunning stages. The screen validates the mandatory accounts and the automatic-revenue fields on save; consumers are later CRs.

## User Stories

- As an accountant I pick the module's five accounts from filtered, leaf-only account lists and cannot save without them (BR-13, BR-14, BR-6).
- As an admin I set the country and get its currency hint, VAT hint and penalty defaults; «استرجاع افتراضيات الدولة» refills the penalty tab (BR-2, BR-8 screen part).
- As a finance manager I choose manual or automatic revenue journals and, when automatic, the sale recognition policy and the two rent accounts (BR-20, AC-13).
- As an operator I set reservation, grace, rent-frequency and instalment-change defaults with an (i) hint on each (BR-17 storage, AC-6).
- As an integrator I record the Ejar mode / environment / transfer days and the e-invoice exemption flag (BR-5).

## Implementation Decisions

- **D1 Home** (Q1): `Pm_RealEstateSettings`, aggregate `RealEstateSettings`, `RealEstateSettingsController`, front module `real-estate-settings`, module 953, all with cr125638's names and shapes; `CustomerGroupId` kept. New group 5_3 «الإعدادات والصلاحيات» / item 5_3_1 (Q2).
- **D2 Columns** on `Pm_RealEstateSettings`, all nullable (the seeded row is empty; the aggregate enforces the rules on save):
  - General: `CompanyName`, `CompanyNameSecondLanguage` NVARCHAR(250); `CountryId` INT FK `ACFX_Country`; `ShowHijriDate` BIT NOT NULL DF 1; `RegaBrokerageLicense`, `RegaPropertyManagementLicense` NVARCHAR(50); `RegaLicenseExpiryDate` DATE.
  - Accounts (FK `Acc_Account`): `TenantDepositsAccountId`, `OwnerDuesAccountId`, `UnbilledSaleReceivablesAccountId`, `PropertyStockAccountId`, `RentPaymentsInTransitAccountId`.
  - Defaults: `ReservationValidityDays` INT, `ReservationDownPaymentPercent` DECIMAL(5,2), `GracePeriodDays` INT, `RentFrequencyId` INT FK, `InstallmentChangeLimitPercent` DECIMAL(5,2).
  - Revenue: `CreateJournalsManually` BIT NOT NULL DF 1; `ProofOfIncomeAndExpensesId` INT FK `Pm_ProofOfIncomeAndExpenses`; `AccruedRentRevenueAccountId`, `UnearnedRentRevenueAccountId` INT FK `Acc_Account`.
  - Taxes: `FirstHomeTaxExemptionCap` DECIMAL(19,4) (money; corrected from 18,2 by review 1 row 12, db-rules §Schema Change Rules 2); `BrokerCommissionWithholdingPercent` DECIMAL(5,2).
  - Penalties: `LatePenaltyTreatmentId`, `PenaltyStartId`, `ContractPenaltyCapId` INT FK; `AnnualLegalPenaltyCapPercent` DECIMAL(5,2); `PenaltyCappedAtPrincipal` BIT.
  - Integrations: `EjarIntegrationModeId`, `EjarEnvironmentId` INT FK; `EjarTransferBusinessDays` INT; `EjarDefaultPaymentForCommercial` BIT; `EInvoiceExemptInstallments` BIT.
  - Dunning stages (Q8): four fixed slots on the row, `Stage1FromDay`..`Stage4FromDay` INT NULL and `Stage1ActionId`..`Stage4ActionId` INT NULL FK `Pm_DefaultStageAction`; no child table.
- **D3 Lookups** (Q6), each `Id / Name / NameSecondLanguage`, seeded by one reference-data script `04xx_Pm_RealEstateSettingsLookups.sql` and mirrored by a static-list entity in `RealEstateSettingsAggregate\Lookups\`:
  `Pm_RentFrequency` (1 شهري, 2 ربع سنوي, 3 نصف سنوي, 4 سنوي); `Pm_LatePenaltyTreatment` (1 غرامة مالية, 2 أوجه البر, 3 بدون غرامة مالية); `Pm_PenaltyStart` (1 بعد فترة السماح, 2 من تاريخ الاستحقاق); `Pm_ContractPenaltyCap` (1 بدون, 2 قسط واحد); `Pm_DefaultStageAction` (1 تذكير ودي, 2 إنذار رسمي, 3 إشعار تعثر, 4 حلول باقي الأقساط, 5 فسخ العقد – الإخلاء, 6 تحويل للشؤون القانونية); `Pm_EjarIntegrationMode` (1 API, 2 يدوي – استيراد); `Pm_EjarEnvironment` (1 تجريبي, 2 تشغيل).
- **D4 `Pm_ProofOfIncomeAndExpenses`** (Q3): add row 3 to `0328_Pm_ProofOfIncomeAndExpenses.sql` and `ProofOfIncomeAndExpenses.PercentageOfCompletion` to the static list; new `GET api/RealEstateSettings/ProofOfIncomeAndExpenses` lookup. Existing rows and the typo in the English name untouched (surgical).
- **D5 Accounts** (Q4): `GET api/RealEstateSettings/Accounts` → `{ LiabilityAccounts, AssetAccounts }`, `IsLastNode && IsActive`, liability type ids from `AccountType` (current + long-term liabilities), asset ids 6 / 7 / 16 / 18, ordered by number, one GL query. Save re-validates every chosen account (exists, leaf, active, right class) in one GL read and reports a per-field resource message.
- **D6 Country** (Q7): FK to `ACFX_Country`; `GET api/RealEstateSettings/Countries` returns every active country; `RealEstateCountryDefaults` (Logic, static, keyed by code) holds the penalty, tax and reservation defaults of the note (EG: financial, 7 %, from due date, stages 1/31/61/91; SA: none, stages 7/30/60/90; AE: financial, 0 %, after grace); any other code gets the neutral set (financial, 0 % cap, after grace, no contract cap, stages 7 / 30 / 60 / 90, withholding 0); `GET api/RealEstateSettings/CountryDefaults/{countryId}`.
- **D7 Read model:** `RealEstateSettingsDto` = stored values + `CountryCode`, the four stage slots, and `Defaults` (the country defaults; the neutral set when no country is stored) so the front shows "stored ?? default" (BR-2, AC-10). `RealEstateCountryDefaultsDto` also carries the hints `CurrencyCode` (`ACFX_Currency.Code`) and `VatPercentage` (Q5, hint only), so `GET CountryDefaults/{countryId}` refreshes both when the country changes (review 1 rows 1, 3, 4).
- **D8 Save:** one `PUT` replaces everything (BR-7); `UpdateRealEstateSettingsCommand` grows the fields and the four stage slots. Rules in the aggregate: country required; the five accounts required; when `CreateJournalsManually = false` the policy and the two rent accounts are required; percentages 0–100; days ≥ 0; filled stage slots have both day and action, days > 0 and strictly increasing from slot 1 (empty slots only after the last filled one); a `Result` failure per rule (`RealEstateSettingsErrors`, resx ar + en). The command handler loads accounts and country, then `settings.Update(...)` and `SaveChangesWithValidation`.
- **D9 Front:** the shell becomes a `dx-tab-panel` with one component per tab (logistics pattern), the reactive form built in the data service, `dx-select-box` / `dx-lookup` controls, (i) hints via the `hint` attribute + tooltip, the journal preview as a static table keyed by the current policy, «استرجاع افتراضيات الدولة» on the penalty tab, AC-9 selects the accounts tab and shows the server message. i18n `REALESTATESETTINGS.*` extended (ar-EG + en-US), header «الضبط العام».
- **D10 Permissions / menu:** policies View / Edit on module 953 as today; menu group 5_3 + item 5_3_1 in `WebMenuGroup.cs` / `WebMenuItem.cs`; module row 953 in `0002_Acc_Module_Data.sql` and `Module.cs` copied verbatim from Stage_Beta (cr125638) so the merge is clean.

## Testing Decisions

- Unit tests (`PropertyManager.Application.Test\RealEstateSettings\`): required accounts (A3), class filter (A2), automatic-mode requirements (A6), percent / day ranges, stage-slot ordering and completeness (A8), country defaults per code incl. the neutral set for an unlisted code (A7), create-if-missing row, lookup projection by culture, ProofOfIncomeAndExpenses has 3 values.
- E2E on Sabreen after `publish-db.ps1` of the set: A1–A10 with screenshots + SQL proof in `test-results.md`.

## Acceptance

- **A1** The screen opens at إعدادات العقارات › الإعدادات والصلاحيات › الضبط العام with seven tabs and one «حفظ».
- **A2** The accounts tab shows five lists; the liability lists hold only leaf liability accounts, the asset lists only leaf asset accounts (AC-7, Q4).
- **A3** Saving with any of the five accounts empty shows the mandatory-fields message, switches to the accounts tab and saves nothing (AC-9).
- **A4** Choosing the UAE shows the VAT hint from GL settings (5 % on a UAE tenant) and the currency hint د.إ (AC-2 screen half).
- **A5** Hovering the (i) of «أيام السماح قبل التأخير» shows its explanation (AC-6).
- **A6** Selecting «تلقائي» enables the sale policy (three values, default «عند التسليم»), the two rent accounts and switches the journal preview; «يدوي» disables them and clears the requirement (AC-13).
- **A7** Country = السعودية with nothing saved on the penalty tab shows «بدون غرامة مالية» and the stages 7 / 30 / 60 / 90 greyed as defaults (AC-10).
- **A8** Country = مصر, «استرجاع افتراضيات الدولة», save: treatment «مالية», cap 7 %, start «من الاستحقاق», stages 1 / 31 / 61 / 91 are stored (AC-11 screen half).
- **A9** `GET api/RealEstateSettings/ProofOfIncomeAndExpenses` returns 3 rows in the request culture; `Pm_ProofOfIncomeAndExpenses` holds row 3 after deploy.
- **A10** Save with all tabs filled, reload: every value comes back; `CustomerGroupId` (cr125638's field) survives.

## Out of Scope

- The currency hint shows the currency **code** (AED, EGP), not the symbol د.إ: `ACFX_Currency` has no symbol column (review 1 row 4); A4 is met with the code.

Reservations, contracts, invoices, penalties, journals, print headers and the Ejar client (AC-1, AC-3, AC-4, AC-5, AC-8, AC-12, AC-14); the new «إعدادات العقارات» application (D41); dropping `Pm_Properties.ProofOfIncomeAndExpensesId` / `Pm_Project.ProofOfIncomeAndExpenses` (CR 125486 / 125487 follow-ups); the REGA expiry alert; the desktop.

## Further Notes

- The GL accounts on the tab are the five of the note; the eight journal accounts the PO listed as "where defined?" stay open with the PO.
- Three sibling PM CRs touch `Module.cs`, `WebMenuGroup.cs`, `0002_Acc_Module_Data.sql`; conflicts are expected and trivial.
