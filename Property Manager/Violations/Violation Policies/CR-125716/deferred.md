---
type: deferred
cr: 125716
updated: 2026-10-22
status: final; matches the engineer's answers in [[decisions]]
tags: [property-manager, violations, deferred]
---

# CR-125716 — Deferred points (سياسات المخالفات)

This lists what the source note [[Violation Policies]] asks for that CR 125716 does not deliver, and why. The cloud has no lease contract (عقد الإيجار) and no violation log (سجل المخالفات) on `Master_Stable`, `Stage_Beta` or any `cr*` / `fx*` branch (checked 2026-10-22). This CR delivers the policy catalog and the «سياسة المخالفة» picker on the contract-clause form ([[spec]], [[plan]]).

## Deferred to the «سجل المخالفات» CR

| Point | Source rule | Why it can't be done now | What this CR leaves ready |
|---|---|---|---|
| Occurrence counting: non-cancelled violations of the same policy on the same lease within the window + 1 | BR-2 | no violation log, no lease | the policy stores `RepeatWindowMonths` |
| 3rd noise violation on the same lease within a year = 2,000, end to end | AC-1 | needs BR-2 | the amount part is `AmountForOccurrence(3)` = 2,000, unit-tested (A7) |
| Window 0 = every violation since the lease start counts | AC-2 | no lease start date | `RepeatWindowMonths = 0` is accepted and stored |
| Inactive policy hidden in the «المخالفة» list of the violation log | AC-3 | no violation log screen | the log CR adds its own lookup under its own module (D1). The clause lookup (A9) already hides inactive policies the same way. |
| Block delete of a policy used by a recorded violation | BR-5 (violation half) | no violation table | the delete check covers contract clauses; the log CR adds its own check |
| Recorded violations keep their amount when the policy changes | BR-4 | nothing is recorded yet | the log must copy the amount at record time, not read it live |
| Apply mode behaviour: «تلقائي» adds the penalty to the lease on record; «بعد التأكيد» records «بانتظار التأكيد» until «تأكيد وتطبيق» | field 5 | no lease to charge, no violation status | the policy stores `ApplyModeId` |
| Tenant notice before the fine's apply date (engineer, Q8a); no confirmation after the fine is applied | source open question | sending a notice is part of applying a fine | — The log CR decides whether the notice period is a policy attribute (a column added then) or a log setting. |

## Decided, not deferred

- **VAT:** violation fines carry no VAT (engineer, Q8b), so there is no tax field.
- **The «سياسة المخالفة» picker** on the contract-clause form is **in this CR** (engineer, Q3). That screen was shipped by CR 125483 (Abd Alrhman Hamaj), so tell him when the PR opens.

## Not in the cloud at all yet

- The lease contract (عقد الإيجار) itself, which BR-2, AC-1, AC-2 and the apply mode all hang on.
- Desktop: no change.

## Related

- [[facts]] · [[spec]] · [[plan]] · [[decisions]] · [[open-questions]] · [[business-check-1]] · [[business-check-2]] · [[HANDOFF]]
- Same pattern: CR-125562 service items deferred its lease-dependent rules for the same reason.
