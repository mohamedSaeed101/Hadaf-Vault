---
type: implementation-plan
cr: 123425
title: Permission groups in every app (GL, Cash, Payroll, Construction)
status: implemented-uncommitted
created: 2026-10-02
tags: [cr, cr-123425, plan, permissions]
---

# CR-123425 — Permission Groups in Every App (Addendum)

> [!info] Builds on [[CR-123425 - Plan]] (Logistics) and [[CR-123425 - Grilling Decisions]].
>
> **User decisions (2026-10-02):**
> - Groups go in every app's Users & Permissions screen.
> - Each app gets its own "Manage Permission Groups" extra permission.
> - GL keeps its current save path. That path turned out to be the Misc API, so no GL-service change is needed.
>
> **Rule for this work:** nothing is committed until the user says so.

## Facts (code map, 2026-10-02)

| App | ApplicationId | Users screen module (route) | Save path | Group-manage permission (new) |
|---|---|---|---|---|
| Logistics | 12 | 627 | Misc `LogisticsUserPermissions` → `UserUpdateCommand` | 494 (exists) |
| GL | 1 | 6 | Misc `api/User/updateUser` → `GeneralLedgerUserPermissions` → `UserUpdateCommand` | **495** |
| Cash (Safe) | 7 | 48 (the controller itself uses 46) | Misc `UserClient.putUser` → `SafeUserPermissions` → `UserUpdateCommand` | **496** (module 48) |
| Payroll | 4 | 294 | Misc `api/User/updateUser` → `PayrollUserPermissions` → `UserUpdateCommand` | **497** |
| Construction | 9 | 330 | Misc `UserClient.putUser` → `ConstractionUserPermissions` → `UserUpdateCommand` | **498** |

- **Backend:**
  - `UserUpdateCommand` and `GetUserDetailsQuery` already handle `PermissionGroupIds` per `ApplicationId`. The member sync and the queries are already generic.
  - Only the authorization is Logistics-specific: the controller's policy is on module 627, and the handlers check permission 494.
- **Front end:**
  - The selector and popup live in the Logistics module and hard-code app 12 and permission 494.
  - GL and Payroll send hand-built DTOs (`src/app/models` `IUser` / `UpdateUserDto`), which have no `PermissionGroupIds`.
  - Only Logistics instantiates `AccflexPermissionsService`, the SignalR listener.
- **IDs:** 495–498 are unused on every remote branch (checked 2026-10-02).

## Decisions

- **D1 — one group controller; authorization moves into the handlers.** The `ModuleId`-based policy can't vary by `ApplicationId`. Each action keeps `[Authorize]`. The handlers map `ApplicationId` to the users module (12→627, 1→6, 7→48, 4→294, 9→330 — the users-screen modules; Cash uses 48, its screen module, rather than the 46 its user controller uses):
  - GET requires `AllowView` on that module.
  - Writes require `AllowEdit` on it plus the app's manage permission.
  - Admins pass.

  This departs from the "policy per action" convention, because one controller serves 5 apps. The alternative was 4 extra controllers plus 4 hand-written TS clients.
- **D2:** `PermissionGroupConstants` gains a map from `ApplicationId` to the manage-permission ID: 12→494, 1→495, 7→496, 4→497, 9→498. Unknown applications are rejected.
- **D3:** the selector and popup move to `src/app/shared/components/permission-groups/`, declared in `AccflexSharedModule` with `accflex-` selectors. Inputs are `applicationId` and `canManage`. Logistics switches to them.
- **D4:** each app shell gets the same wiring as Logistics:
  - the selector and popup above the grid;
  - `showPermissionSources` and `selectedGroups` on the grid;
  - `PermissionGroupIds` sent on save;
  - the selector disabled for admins.

  Existing cache logic stays as each app has it.
- **D5:** inject `AccflexPermissionsService` in the GL, Cash, Payroll and Construction `app.component`s for the live refresh.
- **Out of scope (flagged):** the Cash shell passes `[applicationId]="2"` to its grid, which looks like an existing bug. Payroll's `resetCache` compares the user id with `===` against a string claim.

## Tasks

1. **DB + backend:**
   - DB: rows 495–498 in `0003`.
   - ERP: the ID map, per-app authorization in the 4 handlers (Get/Save/Delete; the plain query too), and the controller's `ModuleId` policy removed in favour of `[Authorize]`.
   - Unit tests for the map.
2. **Front end, shared components:** move the selector and popup to shared, parameterize them, and switch Logistics over. Type-check.
3. **Front end, four apps:** wire the GL, Cash, Payroll and Construction shells, add the DTO fields for GL and Payroll, and inject the SignalR listener in the 4 `app.component`s. Type-check.
4. **Review:** one review of all uncommitted diffs, then a fix round if needed.
