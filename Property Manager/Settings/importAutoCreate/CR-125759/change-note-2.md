# CR-125759 change note 2 (iterate, 2026-10-25)

- **What:** rename column `dbo.Pm_ProjectExpenseType.AssetAccountId` → `WorkInProgressAccountId` and follow it through the code (engineer, decisions Q12): DB, aggregate/poco, EF, commands, queries, DTOs, validator, tests, synced TS client, Angular screen. Constraints follow: `FK_Pm_ProjectExpenseType_Acc_Account_AssetAccount` → `FK_Pm_ProjectExpenseType_Acc_Account_WorkInProgressAccount`, `UQ_Pm_ProjectExpenseType_AssetAccountId` → `UQ_Pm_ProjectExpenseType_WorkInProgressAccountId`.
- **Where:**
  - DB (`D:\Hadaf-worktrees\cr125759\AccFlex_Cloud_Database`): `dbo\Tables\Pm_ProjectExpenseType.sql` + a Rename refactor entry in `AccFlex_Cloud_Database_State.refactorlog` so the dacpac emits `sp_rename` (no drop / data loss). `Rst_ExpenseDetails` / `Rst_ProjectExpenseDetails` have their own `AssetAccountId`: not touched.
  - API (`D:\Hadaf\worktrees\cr125759\AccFlex_Cloud_ERP`): `PropertyManager.*\ProjectExpenseType*` files that use `AssetAccountId` / `AssetAccount*` member names for this account (entity, poco, EF config, commands, DTOs incl. ActiveProjectExpenseTypeDto / ProjectExpenseTypeAccountsDto, loader, validator, tests). Error enum names and resx keys (`ExpenseTypeAssetAccount*`) stay: internal identifiers, texts already renamed in change-note-1.
  - Client: `sync-api-client` PropertyManager (stage only the expense-type models + barrel). `TSClient\src\index.ts` stays unregenerated (api-clients.md).
  - Front (`D:\Hadaf\worktrees\cr125759\AccFlex_Cloud_Front`): `projects\property-manager\src\app\modules\project-expense-types\**`.
- **Test:** sqlproj MSBuild 0 errors and `publish-db.ps1 -Script` preview shows `sp_rename` for the column (no DROP COLUMN); PropertyManager.API build 0 errors; ExpenseType tests pass; `npm run testing` 0 errors.
- **Risk:** contract change on the expense-type endpoints (field renamed, not added): the Angular screen is the only consumer in the repos (grep). Anything outside the repos reading `AssetAccountId` breaks. Deploy order DB → API → web.
- **Rollback:** revert the commits; the refactorlog rename reverses only with a new rename entry.
