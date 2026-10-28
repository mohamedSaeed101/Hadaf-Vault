---
type: facts
cr: 125716
updated: 2026-10-22
---

# CR-125716 — Facts: Violation Policies (سياسات المخالفات)

- **ADO:** Change Request 125716, created by the agent at the engineer's explicit request (2026-10-22) from the source note [[Violation Policies]]. Fields copied from sibling CR 125563 (area `3- Customer Issues`, Program Property Manager, customer نواصى العقارية, country السعودية, version 7.0.82.x, Environment Beta, Category Paid, due 2026-11-01). Assigned to Mohamed Saeed (no auto-reassignment this time); state **In Development**.
- **Merge Desk:** ticket #12595, Beta, Acknowledge, owner mohamed.saed, repos API / WebContainer / Database, contract change on, components Database / Property Manager / Web Container (set by hand). `cr125716` on origin in all 3 repos; none in `AccFlex_ERP` (web only).
- **Kind:** cr → first PR to `Stage_Beta`, second to `Master_Stable`. Base `Master_Stable`.

## Scope (source: [[Violation Policies]], prototype screen `rent.violPolicy`, requirement S21)

1. New screen: التأجير › المخالفات › سياسات المخالفات (Leasing › Violations › Violation Policies). *(source §header)*
2. Purpose: tenant violation penalty policies, tiered by repeat count (1st / 2nd / 3rd+), apply mode automatic or after confirmation. Separate from the late-payment penalty, which lives in the instalment plan (sales) and the payment term (lease) — meeting decision 11/10. *(§الهدف)*
3. Consumers (not in this CR): «سجل المخالفات» (violation log) picks a policy when recording a violation; «شروط وأحكام العقود» has a «سياسة المخالفة» on lease terms. *(§الوصول والتدفق)*
4. Fields *(§الحقول)*:
   | # | Field | Type | Required | Default | Note |
   |---|---|---|---|---|---|
   | 1 | Code | text | yes | | unique (BR-1) |
   | 2 | NameAr | text | yes | | |
   | 3 | NameEn | text | no | | |
   | 4 | ViolationType | list: Noise, Littering, Damage, LeaseTermsBreach, Other | yes | Noise | classification + reports |
   | 5 | ApplyMode | list: AfterConfirmation, Automatic | yes | KSA → AfterConfirmation, else Automatic | Automatic = penalty added to the lease on record; AfterConfirmation = violation «بانتظار التأكيد» until «تأكيد وتطبيق» |
   | 6 | IsActive | checkbox | no | true | inactive hidden from violation log and lease-terms picker |
   | 7 | FirstAmount | money | yes | 0 | |
   | 8 | SecondAmount | money | no | 0 | 0 = first |
   | 9 | ThirdAmount | money | no | 0 | 0 = second (or first) |
   | 10 | RepeatWindowMonths | int | no | 12 | 0 = since lease start |
5. List columns: Code, Violation (name), Type, 1st, 2nd, 3rd+, Repeat window, Apply mode. *(§أعمدة القائمة)*
6. Buttons: New (defaults above), Save (validates required), Delete (confirm), Export (Excel of shown rows). *(§الأزرار)*
7. BR-1 required fields; code unique (the prototype doesn't check — the product must).
8. BR-2 occurrence = count of non-cancelled violations of the same policy on the same lease in the window + 1. **Needs the violation log.**
9. BR-3 amount by occurrence with the zero fallbacks. **Pure function; can live on the aggregate now.**
10. BR-4 editing a policy doesn't change recorded violations.
11. BR-5 block delete of a policy used by a violation or a lease term. **Needs the violation log / lease terms.**
12. AC-1 500/1000/2000 window 12 → 3rd noise violation within a year = 2000. AC-2 window 0 → all since lease start. AC-3 inactive hidden in the violation log. AC-4 cannot save without the first amount.
13. Open questions in source: approval / tenant notification before an automatic penalty? VAT on violation penalties (currently 0% like other penalties)?

## Environment

- Module Property Manager (cloud, web only). Test tenant: Sabreen (db-all/Sabreen_Primary) — memory `pm-test-tenant-sabreen`.
- Attachments: none (source note only).
