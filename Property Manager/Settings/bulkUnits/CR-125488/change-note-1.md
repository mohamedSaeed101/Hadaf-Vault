---
type: change-note
cr: 125488
round: 1
source: ADO comment 10010150 (Sabreen Abubakr, PO check, 2026-10-20) — CR back to In Development
---

# Change note 1 — PO check 2026-10-20

## 1. Rent (BR-6 / BR-7) not implemented — **stays out per Q1** (engineer, 2026-10-20; ADO reply comment 10010556)

The PO asks for «الإيجار السنوي» in the pattern, a «الإيجار» grid column, rent prices for
rent-type units (annual; monthly = annual ÷ 12 × 1.05), and garage rent (3,000 or an input).

- This was left out on purpose: Q1 in [[decisions]], and the PO's own [[bulk Units V2]] fields
  13 / 25 and BR-6 say «مش في CR-125488 (Q1): مفيش جدول أسعار إيجار في الكلاود – بييجي مع CR أسعار الإيجار».
- Checked again 2026-10-20: there is still no rent-price table, entity or screen on
  Master_Stable, Stage_Beta or cr125488 (ERP + DB: no `RentPrice` / `PropertyRent` / `AnnualRent`).
- The PO's comment asks for exactly this: if no table exists, say so on the ticket and agree on the approach.
- Price → 0 for non-sale units is already done (spec, A5).

## 2. Internal code in row messages («متكرر في الجدول⟦E24003025⟧») — fixed, ERP `81b9a07125` pushed

- Cause: on Stage_Beta the error-contract work numbers every `PropertiesErrors` entry
  (`BulkCodeDuplicatedInGrid` = 24003025), and `AccflexError.ToString()` appends the marker
  `⟦E<code>⟧`. The middleware strips it only from error responses; the verify grid's row
  messages are plain DTO strings, so the marker reached the screen.
- Fix (`BulkPropertyRowChecker.cs`): row messages use `.Name` (clean text on both branches), and
  domain errors copied from `Property.Create` have the marker removed by a regex (`ErrorMarker`
  is not on Master_Stable yet). Tests assert `.Name`.
- Gates: `PropertyManager.API.csproj` build OK; 71/71 bulk tests pass.
