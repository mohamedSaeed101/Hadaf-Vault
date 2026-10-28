# change-note-3 — Stage_Beta DB deploy blocked by the old UQ (2026-10-26)

**Problem.** Stage_Beta (f7cfd5e1, after !68429) still fails publish with SQL72031: the target
keeps `UQ_Pm_ProjectExpenseType_AssetAccountId`, and with `DropObjectsNotInSource=False`
sqlpackage won't drop it, so the `AssetAccountId` → `WorkInProgressAccountId` refactorlog
rename is blocked. 47 databases on db-all still carry the UQ (all BETA-* included).

**Decision (engineer, 2026-10-26).** Guarded pre-deploy script that drops the UQ if it
exists. Accepted exception to `prescript-no-ddl.md`: the object is not in the model, so the
dacpac never declares it and nothing collides.

**Plan**
1. DB worktree `D:\Hadaf-worktrees\cr125759\AccFlex_Cloud_Database_Stage_Beta`, branch
   `cr125759_Stage_Beta` off origin/Stage_Beta → verify: clean, at Stage_Beta tip.
2. `Scripts\PreScripts\<stamp>_Pm_ProjectExpenseType_DropAssetAccountUQ_Safe.sql`, UTF-8 BOM,
   no GO, `IF OBJECT_ID(...)` guard, `EXEC(N'ALTER TABLE ... DROP CONSTRAINT ...')`; listed in
   the sqlproj → verify: MSBuild 0 errors.
3. Sabreen_Primary only: `FirstHomeTaxExemptionCap` DECIMAL(18,2) → (19,4) by hand (1 row,
   value 1,000,000.00; model was always 19,4) → verify: column is 19,4, value unchanged.
4. Preview the branch on db-all / Sabreen_Primary → verify: no SQL72031, no data-loss rows.
5. No commit / push until the engineer says so. Master_Stable: the cr125759 Master_Stable PR
   carries the same rename, so the same script is needed on `cr125759` before production.

## Result (2026-10-26)
- Pre-script approach **does not work**: SQL72031 is a plan-verification error, raised before
  any pre-deploy script runs (BETA-MTS preview of Stage_Beta tip fails on it alone).
- Done: Sabreen_Primary `FirstHomeTaxExemptionCap` widened to DECIMAL(19,4) (1,000,000.0000 kept).
- Prototype (uncommitted, branch cr125759_Stage_Beta in `AccFlex_Cloud_Database_Stage_Beta`):
  re-declare `UQ_Pm_ProjectExpenseType_AssetAccountId UNIQUE ([WorkInProgressAccountId])` in
  the model. Previews on BETA-MTS and Sabreen_Primary: no SQL72031, no data-loss warnings;
  script does `sp_rename` of the column, keeps the UQ. Reverses the morning's "DB constraint
  removed" call (the API still enforces uniqueness, so behaviour is the same).
- Alternatives: `/p:VerifyDeployment=False` on pipeline 341 + the pre-script, or hand-drop
  the UQ on each tenant (47 on db-all) before every deploy.
