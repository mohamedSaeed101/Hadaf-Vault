---
type: test-results
cr: 125562
date: 2026-10-19
phase: 7 (end to end)
---

# CR-125562 — Phase 7 end-to-end results

## Setup

- **Tenant:** `db-all` / `Sabreen_Primary` (company Sabreen), as the engineer chose for phase 7.
- **Schema:** [[cr125562-sabreen.sql]], a guarded, idempotent script. It creates `Pm_ServiceItem` (the same DDL as the sqlproj file) and inserts `Acc_Module` **947** with `IDENTITY_INSERT`. Nothing else on the tenant changed.
- **API:** PropertyManager from the set (Debug), `https://localhost:2518` (1418 + 1100), `ASPNETCORE_ENVIRONMENT=Development`, `Authority` = accesscontrol.localbeta. `DebugTenantConnection` was set as a process variable only.
  - The first run died with "Out of memory." after about 20 requests. The PowerShell host had buffered the Information-level EF log. Restarted with `Logging__LogLevel__Default=Warning` and the log in a file; stable after that.
- **Front:** the set's front on `localhost:4200`, with the locally patched `property-manager.api.client`. The `config.json` changes were local only: propertymanagerapi → localhost:2518, and miscapi / dashboard → localbeta. The file was restored afterwards.
- **Sign-in:** the pane's identity session was still valid, so it went straight to Sabreen.
- **Override proof:** `sys.dm_exec_sessions` showed `Sabreen_Primary | cr125562-pm-local | DESKTOP-KPT7EFB | 2026-10-19 20:28`.

## Results

| AC | Case | Result | Evidence |
|---|---|---|---|
| A1 | Add «نظافة دورية» SRV-01, 3,600, VAT on, active | **pass** | Toast «تم الانشاء». The grid row shows SRV-01 / نظافة دورية / 3,600 / ✓ / ✓. SQL: `1 SRV-01 نظافة دورية Periodic cleaning 3600.0000 1 1`, CreatedById 24 |
| A2 | Duplicate code | **pass** | Typed lower-case `srv-01` → «الكود موجود مسبقاً», nothing saved. Duplicates are caught regardless of case (the DB collation decides; the unit tests could not show this) |
| A3 | No code / no Arabic name | **pass** | Front: «برجاء استكمال الحقول المطلوبة» with both fields flagged. Server (direct POST): 400 «كود البند مطلوب», «اسم البند بالعربية مطلوب» |
| A4 | Defaults | **pass** | A new form opens with annual 0, VAT ✓, active ✓. SRV-02 saved with nothing else typed → `.0000 1 1` |
| A5 | Deactivate | **pass** | SRV-02 edited (active and VAT unticked) → the grid shows both blank. `Search?isActive=true` → TotalCount 1 (SRV-01 only); no filter → 2 |
| A6 | Delete | **pass** | Confirmation «هل تريد حذف بند الخدمة هذا؟» → نعم → the row is gone from the grid and from SQL |
| A7 | Menu | **pass (menu)** / not covered (permission) | `GET api/MenuList`: "5" «إعدادات العقارات» › "5_1" «البيانات الأساسية للعقارات» › `5_1_4` «بنود الخدمات», moduleId 947, route `service-items`, icon `fas fa-book`. No non-admin user was tried |
| A8 | Negative annual value | **pass** | The front number box won't take a minus sign (−5 snaps back to 0). A direct POST with −5 → 400 «القيمة السنوية الافتراضية لا يمكن أن تكون سالبة» |

## Findings for the review (not blocking)

- **The blank form shows red required-field errors right after a save or delete** (both fields flagged before the user types anything). `clearState` resets the form but not the DevExtreme validators. `feature-without-search.md` calls `clearDxValidators()` after `resetItem` for this.
- **After a save the form drops back to read-only**, so the next item needs «إنشاء» again. That matches the shared form-state pattern (AfterSave = disabled), so it is a note only.
- At this pane width the grid's code / name columns are cut off on the right, and the delete popup opens outside the visible area. The page is wider than the pane here; check it at a normal desktop width.

## Not covered

- A user without module 947 rights (A7 permission half).
- The English UI (`en-US`): the keys exist, but the screen was only run in Arabic.
- Concurrency: the DTO has no RowVer, the same as the ContractClause template.

## Data left on Sabreen_Primary

- Table `Pm_ServiceItem` and `Acc_Module` row **947**.
- Service item 1 `SRV-01` «نظافة دورية» 3,600 (SRV-02 was deleted in A6).

They stay as test data; remove them only on the engineer's word.

## Re-check after review (2026-10-19, Q13 + Q14)

- **Q13 fixed:** `patchItem()` no longer resets the dx-validators, and it cancels a pending reset from `resetItem()` (a reset within 200 ms of a save would otherwise blank the item just opened). Browser: open SRV-01 → after 2 s Code / names / 3,600 still shown, 0 `.dx-invalid`. Edit the annual value to 4,800.25 → «تم التحديث», grid 4,800.25. The blank form after the save has 0 red fields (the review-1 row 1 fix holds).
- **Q14 applied:** `AnnualPrice DECIMAL(19,4)` in `Pm_ServiceItem.sql` and the EF mapping. Sabreen: guarded `ALTER COLUMN` ([[cr125562-sabreen-19-4.sql]]) → precision 19, scale 4. SQL after the edit: `1 SRV-01 4800.2500`, saved through `cr125562-pm-local`.
- **Gates:** sqlproj MSBuild exit 0, PropertyManager.API build 0 errors, 32/32 ServiceItem tests, front `npm run testing` exit 0, prettier clean.
- **Data on Sabreen now:** SRV-01 at 4,800.25 (was 3,600).
