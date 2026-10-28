---
type: open-questions
cr: 125733
updated: 2026-10-22
---

# CR-125733 — Open questions (plan gate) — all answered 2026-10-22, see [[decisions]] (Q7, Q8 differ from the recommendation)

Each has the agent's recommended answer; "yes to all" runs the plan as written.

- [x] **Q1 Home of the settings.** Stage_Beta already has `Pm_RealEstateSettings` (one row, `CustomerGroupId`) with screen / module 953 «إعدادات التسويق العقاري» from cr125638; its Stage_Beta PRs are merged, its Master_Stable PR does not exist yet. **Recommended:** build on `Master_Stable` now using **exactly cr125638's names and shapes** (table `Pm_RealEstateSettings` with `CHECK (Id = 1)` and `CustomerGroupId`, aggregate `RealEstateSettings`, `RealEstateSettingsController` at `api/RealEstateSettings`, module 953, route `real-estate-settings`, module `real-estate-settings`) and add this CR's columns, tabs and lookups on top. The Stage_Beta PR will then have add/add conflicts that resolve as "keep both" on a `cr125733_Stage_Beta` branch (standing rule); the Master_Stable PR conflicts only if cr125638 lands first. Alternative: wait for cr125638's Master_Stable PR and merge `origin/Master_Stable` into the set before phase 1 (clean, but the date is unknown).
- [x] **Q2 Menu.** New group **5_3 «الإعدادات والصلاحيات»** under «إعدادات العقارات», item **5_3_1** → `real-estate-settings` (cr125638 put it at 5_1_6, a duplicate id). **Recommended:** yes; the screen title becomes «الضبط العام» (i18n only; the module name stays «إعدادات التسويق العقاري»).
- [x] **Q3 `Pm_ProofOfIncomeAndExpenses` values.** The lookup has 1 «التعاقد على الوحدة», 2 «تسليم الوحدة»; field 27 wants «عند التسليم / نسبة الإنجاز»; BR-17 still names «عند التعاقد». **Recommended:** add **3 «نسبة الإنجاز (البيع على الخارطة)» / "Percentage of completion (off-plan)"** to the seed and the static list, keep 1, show all three, default 2, enabled only when revenue journals = automatic.
- [x] **Q4 Fifth account.** BR-6 adds «مدفوعات إيجار تحت التحويل» (1135) as mandatory; BR-13 / AC-7 say four lists only. **Recommended:** five mandatory accounts, AC-7 reads "5 lists"; it is the Ejar landing account and costs nothing now.
- [x] **Q5 VAT hint source (AC-2, BR-9).** **Recommended:** `Acc_SystemConfiguration.Tax` (GL settings 1_8) via `IGeneralLedgerContext`, falling back to `ACFX_CountryTax.TaxPercentage` of the chosen country when null; display only, never stored.
- [x] **Q6 Lookups.** Rent frequency, penalty treatment, penalty start, contract penalty cap, dunning action, Ejar mode, Ejar environment as PM lookup tables + one reference-data script, per the house pattern. Stage_Beta's `Pm_InstallmentPlanFrequency` is not reused (not on Master_Stable; lease periodicity is a different concept). **Recommended:** yes.
- [x] **Q7 Country.** Store `CountryId` as an FK to `ACFX_Country`; the front lists only SA / AE / EG by code; country defaults are keyed by code in Logic. **Recommended:** yes.
- [x] **Q8 Dunning stages storage.** Child table `Pm_RealEstateSettingsDefaultStage` (FromDay, ActionId), replaced wholesale on save; when empty the country defaults apply (BR-2) and are shown greyed. **Recommended:** yes.
- [x] **Q9 Consumers out of scope.** AC-1, AC-3, AC-4, AC-5, AC-8, AC-12, AC-14, BR-3/4/8/10/11/16/17/21–24, the Ejar client, the new application (D41). **Recommended:** confirm; the journal preview table on the revenue tab is static text per policy.

Blocked on someone else: none. Source-note questions (journal accounts not on the tab, REGA expiry alert, completion-percentage source) stay with the PO; they do not block this CR.
