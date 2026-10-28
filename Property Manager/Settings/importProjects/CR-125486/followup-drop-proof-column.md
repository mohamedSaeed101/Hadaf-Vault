---
type: followup
cr: 125486
updated: 2026-10-18
status: investigated (read-only); ready to become its own CR
---

# Follow-up: drop `Pm_Project.ProofOfIncomeAndExpenses`

Column: `[ProofOfIncomeAndExpenses] INT NOT NULL`, constraint `DF_Pm_Project_ProofOfIncomeAndExpenses DEFAULT ((1))`,
line 39 of `AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Tables\Pm_Project.sql`.
Related: [[decisions]] Q11 (drop) and Q13 (keep for now), [[HANDOFF]] "Next step" item 4.

## Short answer

**The premise behind Q13 is only half true, and a plain model drop is enough.**
`DB.Deployer\Operations.cs:28` does hard-code `BlockOnPossibleDataLoss = true`, but **no tenant upgrade goes through it**.

- The tenant upgrade is `AccessControl` (`Accflex_SharedProjects_ERP\Identity\AccessControl.Service`):
  `UpgradeDatabaseCommandHandler.cs` calls `DatabaseOperations.UpgradeDatabase` (`DatabaseOperations.cs:95-164`).
  It builds a `DacDeployOptions` with **`BlockOnPossibleDataLoss = false`**, `GenerateSmartDefaults = true`,
  `BlockWhenDriftDetected = true` (lines 120-130), generates the script with `GenerateDeployScript`, and runs it.
  That value has been `false` since the file was created (`549411b`, 2024-12-16) and is unchanged on `origin/main`.
- The Stage pipeline `Build\sqlProject-deploy.yaml:55` passes `/p:BlockOnPossibleDataLoss=False`.
- The only `true` values are `DB.Deployer` (a standalone helper; I found **no consumer** of `DB.Deployer` or its package
  `Database.Deploy` in Cloud_ERP, SharedProjects, the desktop repo or the DB repo beyond its own csproj/sln/post-build copy)
  and AccessControl's `UpgradeMainCenterDatabase` / `UpgradeSubBranchDatabase` (lines 180-226). Those two run **after** the
  main upgrade and only for Main/Sub-branch tenants, so the column is already gone when they diff (see Risks).

So Q13's "a dacpac drop stops tenant upgrades through DB.Deployer" does not match the production path.
`publish-db.ps1` (workspace tool) also defaults to blocking, but has `-AllowDataLoss` for an agreed drop.

## How other drops were shipped here

All were plain model edits. No Pre/Post script, no deployer change, no per-object exception:

| Commit | Date | What |
|---|---|---|
| `235691bb2` (hossam.shafik, cr121695) | 2026-09-26 | deleted `AutoImportAvailableDescriptorsInPhysicalInventory` (BIT NOT NULL + DF) from `Lgx_SystemConfigurations.sql`; message: "the publish must allow data loss" |
| `bb3cd06d4` | 2026-06-15 | removed columns from `Lgx_PurchaseOrderDetail.sql` |
| `9a5be6733` | 2025-04-14 | removed a column from `Lgx_ProductionOrder.sql` plus the views/reports reading it, in the same commit |
| `62adc7f4b`, `b3600e6fe` | 2021-10-18 | removed columns from `Lgx_Tax*`, `Inv_Category` |
| `86e930984` | 2026-06-08 | a drop was **reverted** on `Lgx_SalesOrderDetail.sql` (reason not in the message) |

Repo rules agree: `db-rules.md` and `prescript-no-ddl.md` forbid `ALTER TABLE ... DROP COLUMN` in a script because the dacpac
diff would collide with it. `prescript-no-ddl.md` / `db-rules.md` only describe a two-release pattern for *adding* a NOT NULL column.

## Per-object exceptions: not supported

DacFx has one global `BlockOnPossibleDataLoss` flag. `DoNotDropObjectType(s)` / `ExcludeObjectType(s)` work per object *type*
(for example all Tables), never per column. A per-column carve-out would need a custom deployment contributor, which is not
worth building when the live path already allows data loss. No deployer change is recommended.

## Do any readers of the column remain?

Checked 2026-10-18; none blocks the drop once CR-125486's code is what runs:

- **Cloud_ERP, project side**: in the `cr125486` set, `Project`, `ProjectPoco`, `ProjectDto`, `ProjectInfoDto`, Create/Update
  commands, both queries and the EF config have no reference to `Pm_Project.ProofOfIncomeAndExpenses`. `ProjectConfigurations.cs:38`
  is the only `Pm_Project` mention in C#/SQL/JSON. New rows rely on `DF_..._ProofOfIncomeAndExpenses` (DEFAULT 1).
  **On `Stage_Beta` / `Master_Stable` today the code still maps it** (`Project.cs:42`, `ProjectDto.cs:49`, `GetProjectInfoByIdQuery.cs:56`).
- **Cloud_ERP, property side** (`ProofOfIncomeAndExpensesId`, `ProofOfIncomeAndExpenses` lookup entity): belongs to CR-125487. Different column; not touched here.
- **AnalyticsReader / DB model**: `git grep` of `origin/Master_Stable`, `Stage_Beta` and `Stage_Stable` finds the column only in
  `Pm_Project.sql`; no view, TVF, procedure or report reads it, and nothing in `dbo\` other than `Pm_*` table files mentions `Pm_Project`.
- **Desktop** (`D:\Hadaf\AccFlex_ERP`, read-only, `git grep` on the checked-out branch `cr94062`): no `ProofOfIncome` and no `Pm_Project` at all.
  I did not scan other desktop branches.

## Recommended path: one follow-up CR, a single model edit, gated on timing

**Gate (the real risk):** the drop must reach a database only after *no running API build still maps the column*. An older API
`INSERT`/`SELECT` of `Pm_Project` includes it and fails with `Invalid column name`. So start the follow-up CR only after
CR-125486 is merged to `Master_Stable` **and** live in Production (check `whats_live` in Merge Desk). Its own PRs then go
`Stage_Beta` first, `Master_Stable` second, as for any Change Request. The drop is irreversible; once live there is no rollback of the data.

**Files to change (DB repo only):**

1. `AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Tables\Pm_Project.sql`: delete line 39
   (`[ProofOfIncomeAndExpenses] ... DF_Pm_Project_ProofOfIncomeAndExpenses ...`). The dacpac drops the default constraint and the column itself.
   The next line is `[Location] Geography NULL`, which already ends the column list with no comma issue (the file has no comma before `CONSTRAINT [PK_...]`).
2. Nothing else: no `.sqlproj` edit (the table file stays registered), no Pre/Post script (rules forbid DDL there and data is not being moved),
   no deployer / pipeline / AccessControl change, no Cloud_ERP change (already done in CR-125486).
3. Keep `Pm_ProofOfIncomeAndExpenses.sql` and `0328_Pm_ProofOfIncomeAndExpenses.sql`; `Pm_Properties` still has an FK to the lookup until CR-125487's follow-up.

**Verify before the PR** (not run here: this task was read-only and local SQL logins are unreliable):

- `scripts\publish-db.ps1 -Script -Database <tenant>_Primary -Id <set>` against a tenant copy that has `Pm_Project` rows.
  Expect `ALTER TABLE [dbo].[Pm_Project] DROP CONSTRAINT [DF_Pm_Project_ProofOfIncomeAndExpenses]` and `DROP COLUMN [ProofOfIncomeAndExpenses]`,
  and, with blocking on, DacFx's "Rows were detected ... data loss" guard, which confirms the AccessControl `false` path is what lets it through.
  Apply for real with `-AllowDataLoss` (the engineer's explicit go).
- Check no *other* object is rebuilt: the column is not last (`Location` follows it), so DacFx should issue a plain `DROP COLUMN`, not a table rebuild of a table that has IMAGE and geography columns. Read the script to confirm.
- After a Stage_Beta deploy, open the Projects screen and the import screen and create one project.

**Optional bundling:** if the engineer wants one retirement, add the property side in the same follow-up CR: `Pm_Properties.ProofOfIncomeAndExpensesId`
(CR-125487 Q14 leaves it `INT NULL`, FK dropped) and then the lookup table plus its reference-data script. Keep them separate if CR-125487 is not live yet; the same gate applies.

## Alternatives, ranked

1. **Plain drop later (recommended above).** Matches 5 precedents; zero tooling work.
2. **Drop in CR-125486 itself.** Technically possible now (the live path allows data loss). Q13 chose not to; the only reason to revisit is the gate above: CR-125486's PR to `Master_Stable` carries the code and the DB together, and a DB upgraded early breaks any not-yet-updated API. Not recommended.
3. **Make the column `INT NULL`, drop the DF, then drop later** (what CR-125487 did for the property column). Needless for `Pm_Project`: EF already omits the column and DEFAULT 1 fills it. It would only help if a hard-blocking path ever had to be crossed.
4. **Change `DB.Deployer` or add a pre-script that deletes rows.** Rejected: no consumer for the first; the second destroys projects and breaks the no-DDL / no-edit-shipped rules.

## Risks and loose ends

- **Main/Sub-branch tenants**: `UpgradeMainCenterDatabase` / `UpgradeSubBranchDatabase` use `BlockOnPossibleDataLoss = true` with `IncludeCompositeObjects = true`, and their dacpacs reference the main project. They run after the main upgrade, so the diff should be empty for `Pm_Project`. If a tenant's main upgrade is skipped or fails midway, they could report the drop as data loss. Worth one test on a Main-branch tenant, or note it in the PR.
- **Multi-version environments**: AccessControl picks a Stable or Beta model per tenant (`DatabaseModelResolver`). If a Stable-version API still maps the column against a DB upgraded with the Beta/Master dacpac, it breaks; same gate as above.
- **Correct the record**: [[decisions]] Q13 and HANDOFF item 4 say the column waits on "DB.Deployer can allow that data loss". Reword to "wait until CR-125486 is live in Production"; CR-125487 Q14 repeats the same premise for its column.
- **Aside, unrelated to this CR**: `Build\sqlProject-deploy.yaml:53-54` has a SQL username and password in clear text in the repository. It should move to a pipeline secret/variable group; the engineer should decide who rotates it. I did not copy it here.
