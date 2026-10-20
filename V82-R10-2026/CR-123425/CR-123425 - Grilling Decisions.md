---
type: decision-log
cr: 123425
title: CR-123425 — Design Grilling Session
created: 2026-09-27
status: awaiting-confirmation
open_questions: 0
tags: [cr, cr-123425, decisions, grilling, permissions, logistics]
---

# CR-123425 — Design Grilling Session (Decision Log)

> [!info] Related notes
> CR: [[CR-123425 - Source]] · Plan: [[CR-123425 - Plan]] (written 2026-09-27; adds decisions P1–P7 for the PO)

> [!danger] Round 6 (2026-09-27) supersedes the withhold / view design below
> The user removed the withhold tables and the effective-permission views. The model is now:
> - **A group is a template.** Ticking a group for a user writes its permissions into that user's own `Acc_UserModule` / `Acc_UserModulePermission` rows. The schema is unchanged, and the rows hold the user's complete permissions.
> - **The admin can add or remove any permission for the user**, including ones that came from a group.
> - **Sources are computed at runtime on the user screen:** "added individually" (the user has it, no group grants it) and "removed from group" (a group grants it, the user doesn't have it). Nothing is stored.
> - **Editing a group applies only its delta to every member:** a newly granted permission is added, and a permission the group stops granting is removed. A permission that didn't change and that the user doesn't have is **not** re-added.
> - **Q22:** if another of the member's groups still grants a permission being removed, the member **keeps it**.
> - **Q23:** unticking a group on a user **removes** that group's permissions, except ones another ticked group grants. This is shown as a preview before saving.
> - **Delete, keep:** only the memberships go. **Delete, remove:** the same rule as a group edit, applied as "group → nothing".
>
> **No longer applicable:** Q12's (a)/(a2) discussion, Q17 (withhold storage), Q18 (store differences), Q21 (EF view remap), and §2 "New views" / withhold tables. See [[CR-123425 - Plan]] (rewritten).

---

## 1. Headline Decisions

| Area | Decision |
|---|---|
| **Existing tables** | `Acc_UserModule` / `Acc_UserModulePermission`: **no schema change and no change in meaning**. They keep each user's **individual grants**, the same as today |
| **Effective permissions** | **(union of all the user's groups ∪ individual grants) − individual withholds**. A withhold always wins (Q1, Q11, confirmed by the PO) |
| **Group scope** | A group belongs to **one application** (`ApplicationId`). Only Logistics (12) gets the UI now, but the tables and API are generic (Q7) |
| **What a group holds** | Screen permissions (View/Add/Edit/Delete/Print) + extra permissions **only**. Data scopes (sales/purchase organizations, inventory management/locations, stock types, branches) stay **per user** (Q8) |
| **Membership** | Many-to-many users ↔ groups, **no limit**. Edited **only from the user's screen** (Q13) |
| **Group name** | **Name + Second-language name**, both **mandatory** and both **unique** (Q5, Q5b, Q5c) |
| **Group management permission** | A **new extra permission** on screen 627 (Logistics Users), seeded in `0003_Acc_ModulePermission.sql` (Q4) |
| **Existing users** | No migration and no automatic groups. Their current rows **are** their individual grants, so nobody's access changes (Q2) |
| **Audit** | **Out of scope.** No permission-change audit exists today (Q6) |

---

## 2. Data Model

**Existing tables (untouched)**
- `Acc_UserModule`: individual screen grants
- `Acc_UserModulePermission`: individual extra-permission grants

**New tables**

| Table | Purpose |
|---|---|
| `Acc_PermissionGroup` | `PermissionGroupId, Name, SecondLanguageName, ApplicationId`. Both names unique |
| `Acc_PermissionGroupModule` | `PermissionGroupId, ModuleId, AllowView/Add/Edit/Delete/Print` |
| `Acc_PermissionGroupModulePermission` | `PermissionGroupId, ModulePermissionId` |
| `Acc_UserPermissionGroup` | `UserId, PermissionGroupId` (M:M) |
| `Acc_UserModuleWithhold` | `UserId, ModuleId, WithholdView/Add/Edit/Delete/Print` (individual withholds on screen permissions) |
| `Acc_UserModulePermissionWithhold` | `UserId, ModulePermissionId` (individual withholds on extra permissions) |

**New views**
- `vw_UserEffectiveModule`: for each (UserId, ModuleId), each action = (individual OR any group) AND NOT withheld
- `vw_UserEffectiveModulePermission`: (individual ∪ groups) − withholds

**How reads reach the views (Q21 = a)**
- The existing EF entities `UserModule` / `UserModulePermission` are mapped **to the views** in all 3 contexts: SharedKernel, GL (`GlUserRepo`) and IShop. The ~350 read sites don't change.
- The real tables get **new write entities**, used only by the save path (`UserUpdateCommand` / `UserBuilder`).
- **To do in the plan:**
  - scan for any code other than the users screen that *writes* through `UserModule` / `UserModulePermission`, and move it to the write entities
  - the views need a **stable key**, because the entities have a PK

---

## 3. UI

**Users & Permissions screen (Logistics)**
- A section **above the permissions grid** in the same tab: a groups multi-select checklist with a `+` button (Q14). Ticking or unticking a group updates the grid immediately, before saving.
- **Disabled for `isAdmin` users**, with a note that admins have all permissions (Q15).
- How each permission's source is shown in the grid (Q19):
  - **From a group:** normal tick plus an icon; the tooltip lists the group(s)
  - **Individual grant:** green
  - **Withheld despite a group:** unticked with a red marker; the tooltip says "withheld from group X"
  - **"Reset to groups":** a button on each row that clears that row's exceptions
- What is saved (Q18) is **only the differences from the groups**:
  - Ticked, and no group grants it → a row in the individual grant table
  - Unticked, and a group grants it → a withhold row
  - Anything that matches the groups → no individual row (the exception is removed)

**Groups management popup (Q16)**
- A groups list with add, edit and delete, plus a form with both names and the **same shared grid** (`user-module-permissions-list`) filtered to `ApplicationId = 12`. Extra permissions are in the expandable rows.
- It shows each group's member count, read-only.

---

## 4. Group Changes and Deletion

| Action | Behaviour |
|---|---|
| **Edit a group** | Informational warning: "This change affects N users" → Confirm or Cancel. The change applies to **all** members (Q3b) |
| **Delete a group with members** | A warning showing N users and a choice (Q3, Q3b, Q20): **① Delete and keep permissions**, where the group's permissions are copied to each member as individual grants (anything withheld stays withheld). **② Delete and remove permissions**, where members lose whatever that group alone gave them |

---

## 5. Immediate Effect on Active Sessions (Q10)

- **Server:** already immediate. `PermissionRequirement` / V2 / V3 read the DB on every request with no cache, and they will read through the views.
- **Client:** menus and buttons come from localStorage `UserPermissions{App}`. Finish the SignalR path so that after saving a group, or a user's groups, the server sends `refreshUserPermission` **only to affected users** (today it is a tenant-wide broadcast, and the client listener is never registered). The client re-fetches from `GetAllUserModuleQuery`, which must also read effective permissions, and updates localStorage.
- **To check in the plan:** can the AccessControl hub target specific user ids?

---

## 6. Facts Found in the Code (Research, Not Decisions)

> [!note] Current permission model
> - The screen is at `AccFlex_Cloud_Front\accflex-erp\projects\logistics\src\app\modules\user-permissions\`. The route `users-permissions` is guarded by ModuleId 627.
> - It is **not a tree**. It is a DevExtreme grid (the shared `user-module-permissions-list`) grouped by ModuleCategory/SubCategory, with 5 CRUD checkboxes per row. Extra permissions are in a master-detail row. The same component is used by Cash, Construction, GL and Payroll.
> - **Save:** `PUT /api/LogisticsUserPermissions/UpdateUser/{userId}`, which calls `UserUpdateCommand` → `UserBuilder`. After saving, the client refreshes its token and clears its cache.
> - The model is **grant-only**. There are no deny flags and no existing group or role layer. `Acc_Group` is for account groups and is unrelated.
> - Tenancy is one DB per tenant. `Acc_User` has no company or branch column.
> - Data scopes are **JWT claims** issued at login (`UserTenantInfoService.cs:86-118`).

> [!warning] Read sites (why the views are needed)
> - **About 350** C# reads of `Acc_UserModule` / `Acc_UserModulePermission`.
> - **About 111** go through `CompanyUserRepo`. **About 240** query the tables directly, in about 190 files: Logistics about 147, CashControl 60, Payroll 19.
> - There are **three EF mappings**: SharedKernel, GL and IShop.
> - There are **no** SQL views, stored procedures or functions on these tables. Login does not read them.
> - The localStorage payload is built by `Misc.Application\Users\Queries\GetAllUserModuleQuery.cs`, directly from the tables.

> [!danger] Security issue seen in passing (outside this CR)
> `GET /api/User/UserPermissions?userId=` has no permission policy and takes the userId from the client, so any user can read another user's permissions. A separate task was suggested.

---

## 7. Estimate

The CR says **5 SP**. It will likely be higher: 6 tables + 2 views + EF remapping across 3 contexts + the three-state UI + the popup + targeted SignalR. The plan will give a revised figure.

---

## Question Index

| Q              | Topic                                    | Decision                                                                 |
| -------------- | ---------------------------------------- | ------------------------------------------------------------------------ |
| Q1             | Combining groups and individual settings | (groups ∪ grants) − withholds; a withhold wins                           |
| Q2             | Existing users                           | Unchanged; current rows = individual grants                              |
| Q3 / Q3b / Q20 | Delete / edit group                      | Delete: choose keep or remove. Edit: informational warning only          |
| Q4             | Who manages groups                       | A new extra permission on 627                                            |
| Q5 / 5b / 5c   | Name                                     | Name + Second-language name, both mandatory and unique                   |
| Q6             | Audit                                    | Out of scope                                                             |
| Q7             | Application scope                        | Per application; Logistics UI only now                                   |
| Q8             | Data scopes                              | Not in groups                                                            |
| Q9 / Q12       | Where effective permissions are computed | Existing tables unchanged; union views                                   |
| Q10            | Active sessions                          | Targeted SignalR plus a client re-fetch                                  |
| Q11            | Withholding a group permission           | Allowed (confirmed by the PO)                                            |
| Q13            | Where membership is edited               | User's screen only                                                       |
| Q14            | Checklist placement                      | Above the grid, same tab                                                 |
| Q15            | Admins                                   | Checklist disabled                                                       |
| Q16            | Popup layout                             | Groups list + form + shared grid                                         |
| Q17            | Withhold storage                         | Separate withhold tables; existing tables untouched                      |
| Q18            | Saving                                   | Store only the differences from the groups                               |
| Q19            | Showing sources                          | Icon / green / red / Reset to groups                                     |
| Q21            | How reads reach the views                | ~~(a) Remap EF entities to the views~~: superseded by Round 6 (no views) |
| Round 6        | Storage model                            | Groups are templates copied into the user's own rows; group edit = delta only; sources computed at runtime |
| Q22            | Removed from a group, but another group grants it | Keep it                                                     |
| Q23            | Untick a group on a user                 | Remove its permissions (except ones another ticked group grants); preview before saving |
