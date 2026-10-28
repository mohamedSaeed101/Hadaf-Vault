# Business check round 2 — CR 126223 — verdict: pass

Fable business-checker, 2026-10-28. KG `Accflex_KG` absent; no PM KG coverage (not a blocker).

## Round-1 rows
| # | status | evidence |
|---|---|---|
| 1 | closed | new lines Active (1), «معاد جدولته» derived from ContractActionDocumentId; GetAllSaleContracts / Pm_Rpt_SoldUnits unchanged |
| 2 | closed | cr126102 TransferringInstallments (Active, DueDate >= transferDate, not RETT) now moves rescheduled lines |
| 3 | closed (ruled) | warn-only recorded as knowing relaxation of Settings field 23 / BR-17 |
| 4 | closed | popup 0/empty → 1, aggregate refuses n < 1 |
| 5 | closed | DueDate >= document date |

## Advisory (confirm with PO; no rule broken)
| # | point | suggestion |
|---|---|---|
| 6 | After a second reschedule, which lines a document cancelled is only in the description text; a future reverse has nothing to restore from | accept description-only, or add `CancelledByContractActionDocumentId INT NULL` on cancelled lines |
| 7 | First due date earlier than the document date creates Active lines a later reschedule/transfer treats as past | R7: refuse (or warn) when first due < document date |
| 8 | Per-line tax Round2 can drift Σ tax by piasters; document Amount is net while list Remaining is gross | R10: Amount = Σ cancelled Amount (net); tax rounding per line as at approval, drift accepted |

## Checked and kept
Transfer after reschedule (copied lines show «ساري» on the new contract; note at Stage_Beta merge); reschedule after transfer refused by R1 on the old contract; derived status consistent; sum invariant, no journals, DOC numbering, tenant scope hold.

Round 3 needed: no.
