# Change note 1 — CR 112974, QA comment 10015919, issue 2

- **What:** the account-migration blocker message is shown once per distinct message instead of once per blocked journal (QA saw the closed-period line 7 times).
- **Where:** `AccFlex_Cloud_ERP/Construction/Construction.Application/ProjectJobItem/Services/ProjectJobItemAccountMigrationService.cs`, `DescribeBlockers` — distinct messages before `AddError`. Desktop and web both read this API error; no client change.
- **Test:** item 2004 (id 193) on BETA-dbriyadhbn with a closed period covering several owner bills → change income account, choose Yes → one closed-period line. Build of Construction.API green.
- **Risk:** none beyond the message text; the blocker list and the migration decision are unchanged.
- **Rollback:** revert the commit on `fx112974`.

Out of scope for now (user, 2026-10-25): issue 1 (legacy 0.0001 residue blocks the rebuild) and issue 3 (raw-material unit, pre-existing). See `rca-comment-10015919.md`.
