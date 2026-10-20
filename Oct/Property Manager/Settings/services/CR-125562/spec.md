---
type: spec
cr: 125562
updated: 2026-10-19
status: approved 2026-10-19 (Q1–Q6 = recommended, see decisions.md)
---

# CR-125562 — Spec: Service items (بنود الخدمات)

Written by the agent (the `to-spec` sections) from [[facts]] and [[services]]. The recommended answers in [[open-questions]] are folded in, marked *(Qn)*.

## Problem Statement
The property office offers recurring services (cleaning, security, periodic maintenance) to tenants of the properties it manages. Property Manager cloud has nowhere to define these services, so a lease contract has nothing to pick from.

## Solution
A new master-data screen «بنود الخدمات» under إعدادات العقارات › البيانات الأساسية للعقارات. It lists service items and lets the user add, edit, deactivate and delete them. It is built on the ContractClause pattern end to end (table → aggregate → CQRS → controller → TS client → Angular list + form).

The lease-contract side (the services tab, the installment spread, the VAT line, the usage count, the usage-based delete block) waits for the lease contract, which does not exist in the cloud yet *(Q1)*.

## User Stories
1. As a settings user, I add a service item with code, Arabic name, optional English name, default annual value, VAT flag and active flag.
2. As a settings user, I search the list by code or name and see code, item name, default annual value, VAT and active.
3. As a settings user, I edit an item. Its code must stay unique.
4. As a settings user, I deactivate an item so new contracts stop offering it.
5. As a settings user, I delete an item I created by mistake.

## Implementation Decisions
- **Table `Pm_ServiceItem`**:
  - `Id INT IDENTITY` PK; `Code NVARCHAR(50) NOT NULL` with `UQ_Pm_ServiceItem_Code`; `NameAr NVARCHAR(200) NOT NULL`; `NameEn NVARCHAR(200) NULL`.
  - `AnnualPrice DECIMAL(18,4) NOT NULL DEFAULT 0` with `CK_Pm_ServiceItem_AnnualPrice CHECK (AnnualPrice >= 0)`, in the tenant base currency, no currency column *(Q5, D7)*; `IsSubjectToVat BIT NOT NULL DEFAULT 1`; `IsActive BIT NOT NULL DEFAULT 1`.
  - Audit columns and `RowVer ROWVERSION`, as on `Pm_ContractClause`.
  - Registered in the sqlproj.
- **Module 947** «بنود الخدمات» / "Property Manager Service Items", sub-category «البيانات الأساسية للعقارات», category 14 *(Q2)*. A `Module.PropertyManagerServiceItems` constant goes in `Module.cs`.
- **Menu item `5_1_4`** in group "5_1" `PropertyBasicData` under root "5" `PropertySettings`, route `service-items` *(Q3)*. Master_Stable lacks group 5, so the CR declares groups 5 / 5_1 the way Stage_Beta has them. The `_Stage_Beta` merge then needs the menu-group conflict resolved, as for CR-125487 / 125488.
- **Aggregate `ServiceItem`** (`PropertyManager.Logic\ServiceItemAggregate\`):
  - `Create` / `Update` return `Result`.
  - Rules: code required and ≤ 50; Arabic name required and ≤ 200; English name ≤ 200; annual price ≥ 0.
  - Code uniqueness (BR-1) is checked in the handler against the DB, and the unique index backs it.
  - Errors and messages go in `Resource.resx` / `Resource.en.resx`.
- **CQRS**: Create / Update / Delete commands; GetById; Search (paged, filter by text and `IsActive`, so pickers can ask for active only: BR-3). Controller `api/ServiceItem` with ModuleId 947 and the Add / Edit / Delete / View policies.
- **Delete**: a hard delete, always allowed for now. BR-2 (blocked when used in a lease contract) gets its check when the lease contract adds the FK *(Q1)*.
- **VAT flag**: stored only. The country rate is applied by the lease contract line later *(Q4)*.
- **Front**: `modules\service-items\` copying `contract-clauses`: a shell, a list (`dx-data-grid`, `onCellClick` opens the form), a form and a data service. Route `data: { ModuleId: 947 }` behind `CanActivateRouteGuard` and `AccflexAuthGuard`. The grid has no «عقود الإيجار» column until the lease contract exists *(Q1)*. Add / edit happens on a separate form *(Q6)*.

## Acceptance (A1..An)
- **A1** Add «نظافة دورية», code SRV-01, annual 3,600, VAT on, active → it is saved and listed with those values.
- **A2** Add another item with code SRV-01 → rejected with «الكود موجود مسبقاً» (BR-1).
- **A3** Save with no code or no Arabic name → rejected with the required-field message, front and server.
- **A4** A new item with no values typed defaults to annual 0, VAT on, active on.
- **A5** Deactivate SRV-01 → the list shows it inactive; Search with `isActive = true` does not return it (BR-3 for future pickers).
- **A6** Delete an item → it is gone from the list.
- **A7** Menu: إعدادات العقارات › البيانات الأساسية للعقارات › بنود الخدمات opens the screen; a user without module 947 rights does not see it.
- **A8** A negative annual value → rejected.

Deferred to the lease-contract CR: AC-1 (3,600 / quarterly → 900 per installment), AC-2 (0% VAT line), BR-2 (usage-based delete block), the «عقود الإيجار» count, the revenue / exempt-revenue account mapping and the VAT-rate source (country vs PM settings; desktop uses `Rst_Configration.VatPercent` + `TaxExemptServicesAccountId`), and currency conversion for a foreign-currency lease.

## Testing Decisions
- Unit tests on the aggregate (each rule) and the handlers (duplicate code, not found, delete), following `test-doubles-and-baselines.md`.
- Front: `front-verify-build`.
- End to end on db-all / Sabreen_Primary ([[pm-test-tenant-sabreen]]): A1–A8 in the browser pane against the local PM API on base port + 1100.

## Out of Scope
- The lease contract, its «بنود الخدمات» tab, the installment spread and the VAT line.
- Desktop (AccFlex_ERP).
- Fixing the duplicate group fields in Stage_Beta's `WebMenuGroup.cs`. That is reported, not fixed.

## Further Notes
- Siblings: CR-125486 / 125487 / 125488 (menu group 5), cr125402 (installment plans, 5_1_1), cr125483 (contract clauses, 5_1_2), cr125491 (furnishing, 5_1_3). The last one merged adds its item to `PropertyBasicData`.
