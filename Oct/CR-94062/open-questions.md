# CR-94062 — open questions

- [ ] **Q6 (phase P2): Which tenant products count as "has Logistics"?** This decides whether the web shows the Logistics customers type.
  - **Implemented:** `Product.Logistics`, `Product.LogisticsWeb` or `Product.LogisticsSubs`, in `BankGuaranteePayeeType.IsLicensed`.
  - **Desktop** checks `Product.Logistics` only (`frmUserLogin.cs`).
  - **The Logistics API's own licence gate** also lets in Manufacturing, ReadyMix and the Sales/Stock/Procurement subscription tenants.
  - **Recommendation:** keep the three products. A tenant on those other products can have Logistics customers too, so if support confirms they do, widen the check to match the Logistics API gate.
  - Blocked on: engineer / PO. Not blocking any phase.
