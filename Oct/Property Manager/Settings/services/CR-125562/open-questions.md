---
type: open-questions
cr: 125562
updated: 2026-10-19
---

# CR-125562 — Open questions (for the engineer, at the plan gate)

Each question carries the recommended answer the spec already uses.

- [x] **Q1 No lease contract in the cloud.** AC-1, AC-2, BR-2 (usage-based delete block) and the «عقود الإيجار» column all need a lease contract, and none exists on Master_Stable or Stage_Beta. *Recommended:* this CR ships the catalog only. Drop the column for now, and allow a hard delete. The lease-contract CR adds the services tab, the spread, the VAT line, the count and the delete block.
- [x] **Q2 Module id.** *Recommended:* **947**. Your rule puts new PM ids after 943, and 944–946 are taken.
- [x] **Q3 Menu.** *Recommended:* item **5_1_4** under "5_1" «البيانات الأساسية للعقارات» (5_1_1–5_1_3 are claimed by cr125402 / cr125483 / cr125491). Declare groups 5 / 5_1 on this branch, since Master_Stable lacks them. Side note: Stage_Beta's `WebMenuGroup.cs` declares `PropertyBasicData` and `PropertySettings` twice (cr125402 + cr125483 merge), which should not compile. Tell the owners; don't fix it here.
- [x] **Q4 VAT.** *Recommended:* store the flag only; the lease contract line applies the country rate later.
- [x] **Q5 Annual value type.** *Recommended:* `DECIMAL(18,4)`, ≥ 0, default 0.
- [x] **Q6 Screen style.** *Recommended:* the ContractClause pattern: a search grid plus a separate add/edit form (not row editing).

## Still open (2026-10-19, after the gate)

- [x] **Q7 VAT-rate source (PO).** The source note says «بنسبة الدولة» (the country rate). Desktop uses `Rst_Configration.VatPercent` and posts non-VAT services to `TaxExemptServicesAccountId`. Which one is final? This is for the lease-contract CR; the catalog only stores the flag. *Recommended:* the country rate (`CountryTax`), as the note says. Blocked on: PO.
- [x] **Q8 Currency (engineer can override D7).** `AnnualPrice` has no currency and is in the tenant base currency, while `Pm_Amenity` and `Pm_PaymentTerm` carry a `CurrencyId`. *Recommended:* keep it as is; a nullable `CurrencyId` can be added later.
- [x] **Q9 Lease-contract CR.** AC-1, AC-2, BR-2, the «عقود الإيجار» column and the exempt-revenue account have no home until a lease-contract CR exists. Who raises it? Blocked on: PO.
- [x] **Q10 Stage_Beta `WebMenuGroup.cs`.** It declares `PropertyBasicData` and `PropertySettings` twice (cr125402 + cr125483), which should not compile. Whom to tell? *Recommended:* the owners of cr125402 / cr125483, before this CR's `Stage_Beta` PR.
- [x] **Q11 No KG.** `Accflex_KG` is not cloned here, and the business check ran without it. *Recommended:* tell the PO team that PM has no KG coverage; clone the KG if it exists.
- [x] **Q12 Module-id collision with CR-125563 (project expense types).** That CR's draft also takes module **947**, and menu item **5_1_2**, which is already ContractClauses on cr125483. *Recommended:* CR-125562 keeps 947 / 5_1_4 (its gate passed first). CR-125563 moves to **948** / **5_1_5**.

**Answered by the engineer, 2026-10-19 (one by one, in chat):** Q7 country rate · Q8 no preference → base currency (recommended) · Q9 no preference → the PO raises the lease-contract CR · Q10 ignore for now · Q11 go ahead without the KG · Q12 CR-125562 keeps 947 / 5_1_4.
- [x] **Q13 (review 2, row 1, block):** `service-item-form.component.ts:51-64`: the round 1 fix also calls `clearDxValidators()` in `patchItem()`. In DevExtreme 24.2, `Validator.reset()` clears the editor value, so opening an existing item blanks Code / NameAr after 200 ms and saving fails with `_DataRequired_`. Implementer: none (the regression came from its round 1 fix). *Recommended:* remove the call from `patchItem()` (keep it in `resetItem()`), then re-run E2E open → edit → save once. Decide: the engineer (the loop stops after round 2).
- [x] **Q14 (review 1, row 4):** money column precision. db-rules says `DECIMAL(19,4)`; D5 approved 18,4. *Recommended:* follow the house rule, 19,4 (table + EF mapping; the test table on Sabreen gets an ALTER). Decide: the engineer.
