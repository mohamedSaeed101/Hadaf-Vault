# RCA — CR 112974, QA comment 10015919 (Basma, 2026-10-22)

Branch: `fx112974` (all four repos; there is no `cr112974`). Tenant: `BETA-dbriyadhbn` on `db-all`.

## 1. Desktop: "Yes" on item 2004 → «مجموع قيم الدائن المحلى لا تساوى مجموع قيم المدين المحلى»

- Item 193 (2004, JobItem_193), income 411 (id 33) → 4202 (id 36). Eight owner bills feed it; the
  migration splits the item's share off each bill's 411 line and rebuilds the journal through
  `Journal.UpdateNormalJournal` (`ProjectJobItemAccountMigrationService.RebuildJournalWithNewAccounts`).
- Journal **6437** (owner bill 6) is already off by **0.0001** in the database:
  debits 186044.6572 + 1953468.9010 = 2139513.5582; credits 1841335.5224 + 19111.0500 + 279066.9859 = 2139513.5583.
- `UpdateNormalJournal` re-checks the local balance with tolerance `10^-ApproximateNo`; the tenant has
  `ApproximateNo = 5` → 0.00001, while `Acc_JournalAction` amounts are `decimal(19,4)`. A 4-dp storage
  residue can never pass, even though the migration does not change the journal's totals.
- Scale: 55 live journals on this tenant are unbalanced, 51 of them by ≤ 0.0005 (storage residue).
- Second, latent: the migrated share is not rounded (e.g. 25172.291442, 6 dp); stored at 4 dp, the two
  halves of a split line can drift by 0.0001 and create a new residue.
- The desktop is only the messenger: it calls the cloud PATCH `UpdateProjectJobItemExpenseAndIncomeAccount`.

## 2. Desktop: closed-period message repeated 7 times

- `ProjectJobItemAccountMigrationService.DescribeBlockers` adds one message per blocker, and the plan
  creates one blocker per journal; seven journals in closed periods → seven identical lines. The web
  shows the same list (same API). Fix: distinct messages.

## 3. Web: «وحدة البند غير موجودة» (22015001) saving item 1001 (JobItem_77-1001, id 67526)

- Not caused by this CR. Item 67526 is a raw-material item (`IsRawMaterial = 1`, unit 6, no warehouse
  item), with no owner bills or memos, so the save takes the full update path.
- The front sets `UnitId = 0` for raw-material items on create and full update
  (`job-items.form.service.ts`, same lines on `Master_Stable`). The backend replaces the unit only when
  `IntegrateWithLogistics` is on; this tenant has it off (0), so the lookup of unit 0 fails
  (`UpdateProjectJobItemCommand` / `CreateProjectJobItemCommand`, `JobItemUnitNotFound`).
- Reproducible on `Master_Stable`: a raw-material item cannot be saved on a tenant without logistics integration.
- Origin (re-checked 2026-10-25): front `443402a490d` (2025-09-07, Ahmed Mahmoud, "Logistics Unit in Project Job Item")
  added `if (IsRawMaterial) UnitId = 0` on create and update **unconditionally**, while the same commit gates its
  warehouse-unit validation on `IntegrateWithLogistics`. `ccc3c61b805` (2025-09-03) hid the unit field for raw-material
  items (`*ngIf="!form.value.IsRawMaterial"`). Backend `78667b6867` (2025-09-08) derives the unit from the warehouse
  item only when `IntegrateWithLogistics` is on. So since Sept 2025, raw-material items fail on non-logistics tenants.
- This CR does not touch that path; it actually avoids it for items with transactions (they now go to the
  accounts-only PATCH). Item 67526 has no owner bills/memos, so it takes the full update, same as before the CR.
- Fix options (outside this CR): front zeroes `UnitId` only when `IntegrateWithLogistics` and shows the unit field
  for raw-material items when it is off; or backend keeps the item's stored unit when logistics is off and `UnitId` is 0.
- Tenant data not re-read on 2026-10-25 (db-all unreachable); values above are from 2026-10-22.
