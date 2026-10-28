# Review round 2 — CR_126303   base DB a2ee2562a / ERP ddb95001f5 / Front 4c4fc7f6c6   head DB 22f4d63fa / ERP 2874f147d6 / Front b4df868464   verdict: pass

Reviewer: Fable 5.1, read-only. Re-checked only the 22 rows of `review-1.md` against the fix commits (ERP `2874f147d6`, Front `b4df868464`; DB unchanged since round 1), `spec.md` R9 and `decisions.md` (review-1 rows 2 and 11 entries). Working trees clean in all three repos.

## Open rows

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| none | | | | | |

## Per-row verification

- 1 done — `SaleContractWaiver.cs:7` now reads "Collected on the contract itself; zero until installment collection exists (D1)". Matches Q10 / R2. Verified in `2874f147d6`.
- 2 done — spec R9 now says "Eligible list, execute and the waiver documents list are scoped to the user's sales organizations ... (documents list added in review-1 row 2, same as `GetSaleContractTransfersQuery`)"; `decisions.md` carries the entry. Code unchanged (the `UserSalesOrganization` join in `GetWaiverDocumentsQuery` is now what the spec asks). Accepted.
- 3 no change — accepted; same bend as the three sibling columns on the single-row table; row 11 records the decision.
- 4 no change — accepted (house pattern, same as Transfer / 126223 reschedule).
- 5 no change — accepted (generated barrel; handled by row 18 at release).
- 6 no change — accepted (base test contexts cannot build with the duplicate DbSet; PR note).
- 7 no change — accepted (Q6 merge layout).
- 8 no change — accepted (RefundAmount is R6 document detail, not an R8 grid column).
- 9 no change — accepted (PO wording; no spec line).
- 10 no change — accepted (A5 covered by `ReleaseSold_SoldBySameContract_AvailableWithNoContract`; browser re-reservation is QA on Stage_Beta).
- 11 done — `decisions.md` "Review-1 row 11" entry records the constant-default acceptance and that the PR must state it. No code change required. Accepted.
- 12 no change — accepted (merge-time instruction for `0464_Pm_SaleQuotationLookups.sql`).
- 13 no change — accepted (969 unique; expect a line conflict only).
- 14 deferred: release-ticket — sound: client regen + Front pin bump is a release-time step in `release-ticket`, not a branch edit.
- 15 no change — dup of 4, accepted.
- 16 done — `builder.Property(x => x.PreviousContractStatusId);` removed from `ContractActionDocumentConfigurations.cs`. `PreviousContractStatusId` is a public `int?` with a private setter on the aggregate (`ContractActionDocument.cs:59`), so EF still maps it by convention; no neighbour broken.
- 17 no change — accepted (mirrors transfer list shape).
- 18 deferred: release-ticket — sound: the 26 reservation client files are identical to origin/Master_Stable; a Master_Stable sync before shipping drops them without a hand edit.
- 19 deferred: release-ticket — sound: the real-estate-settings generated models conflict only with Master_Stable's PriceProcedure fields; resolved by `api:sync` at the sync step, data service merged by hand keeping both.
- 20 done — `canExecute` is `!!this.contractId && !!this.preview`; `onContractChanged` resets `preview = null` and `applyPreview(null)` clears it on a refused preview, so Execute stays disabled until a successful preview. Template `[disabled]="!canExecute"` unchanged.
- 21 done — `documentDate: Date | null`; `onDateChanged(date: Date | null)` now type-checks; `execute()` and `requestPreview()` already guard on `!this.documentDate`, and `PreviewQuery.documentDate` stays `Date` (only built inside the guard).
- 22 no change — accepted (mirrors the transfer constant).

Release-time reminders carried forward (no code change in this set): row 11 PR statement (constant default 1 %), row 6 PR note (duplicate DbSet on Master_Stable test contexts), rows 14 / 18 / 19 handled by `release-ticket` (Master_Stable sync, client regen, Front pin bump), rows 12 / 13 merge-conflict guidance for Stage_Beta.

No `block` rows. Round 3 not needed.
