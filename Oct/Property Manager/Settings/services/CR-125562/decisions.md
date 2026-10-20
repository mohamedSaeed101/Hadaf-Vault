---
type: decisions
cr: 125562
updated: 2026-10-19
---

# CR-125562 — Decisions

The engineer approved the plan with every recommended answer in chat, 2026-10-19 (gate 3 passed).

- **D1 (Q1)** This CR ships the catalog only. AC-1, AC-2, BR-2 and the «عقود الإيجار» column are deferred to the lease-contract CR. Delete is a hard delete with no usage check.
- **D2 (Q2)** Module id **947**.
- **D3 (Q3)** Menu item **5_1_4** in group "5_1" «البيانات الأساسية للعقارات». Groups 5 / 5_1 are declared on this branch the way Stage_Beta has them. The duplicate group fields in Stage_Beta's `WebMenuGroup.cs` are reported, not fixed.
- **D4 (Q4)** The VAT flag is stored only.
- **D5 (Q5)** `AnnualPrice DECIMAL(18,4)`, ≥ 0, default 0.
- **D6 (Q6)** ContractClause screen pattern: a search grid plus a separate form.
- **D7 (business-check-1 rows 2–5, agent call)** `AnnualPrice` is in the tenant base currency, with no `CurrencyId`; the lease line re-enters or converts it. Adding a currency later is an additive nullable column. The revenue / exempt-revenue account and the VAT-rate source go on the lease-contract CR's list for the PO. The table gets `CK_Pm_ServiceItem_AnnualPrice CHECK (>= 0)`, and the column is named `IsSubjectToVat` (the legacy term). There is no KG in this workspace (`Accflex_KG` is not cloned), so the check used the legacy desktop module and the PM sibling tables.
- **D8 (Q7)** For the lease-contract CR: service-line VAT uses the country rate (`CountryTax`), not a PM-level setting.
- **D9 (Q8)** No currency on the service item; `AnnualPrice` is in the tenant base currency. The engineer had no preference, so the recommended answer stands.
- **D10 (Q9)** The PO raises the lease-contract CR that carries the deferred items. The engineer had no preference.
- **D11 (Q10)** Stage_Beta's duplicate menu-group fields are ignored for now and handled when the Stage_Beta PR conflicts.
- **D12 (Q11)** The business check stands without the KG; PM has no KG coverage.
- **D13 (Q12)** CR-125562 keeps module 947 and menu 5_1_4; CR-125563 has to move (948 / 5_1_5 proposed).
- **D14 (Q14, engineer, 2026-10-19)** `AnnualPrice` is `DECIMAL(19,4)` per db-rules §Schema Change Rules 2 (replaces D5's 18,4): table, EF mapping and the Sabreen test table.
- **D15 (Q13, engineer, 2026-10-19)** The dx-validator reset runs only after `resetItem()`. `patchItem()` cancels a pending reset instead of running one, because in DevExtreme 24.2 a reset clears the editor value.
