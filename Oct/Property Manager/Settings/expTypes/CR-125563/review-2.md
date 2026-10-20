# Review round 2 — CR_125563   base DB 0fe9f7a7f / ERP dff0955744 / Front c0721b7e07   head = base (working tree, nothing committed)   verdict: pass

Re-checked only the rows of `review-1.md` against the working tree of the three repos in `D:\Hadaf\worktrees\cr125563\` (`git status` + files read whole). Re-ran `dotnet test PropertyManager.Application.Test --filter ProjectExpenseType` (BaseOutputPath redirected to scratch): **Passed 57 / Failed 0** (56 from round 1 + the new mid-level cost-centre test).

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| — | none | — | — | No row remains open and no fix introduced a block. | — |

## Verified (`done` rows)

- **1** spec.md:74 — "Carried, not owned" Out-of-Scope line for the Amenity `Serves` string→int copy of CR-125487 is present and names the PR description. Closed.
- **2** ProjectExpenseTypeDtoLoader.cs:62-65, 138-158 — `LoadChildrenByParentAsync` walks one tree level per query from the linked roots (`frontier.Contains(ParentCostCenterId)`), `visited` guards cycles; subtree set built from the returned edges only; the GL debit query is still one grouped query bounded by asset-account ids and the collected cost-centre ids. New test `GetAll_ProjectOnAMidLevelCostCenter_SumsItsDescendantsOnly_NotItsParentOrSiblings` asserts 111 of {1, 10, 100 in-subtree; 1000 parent; 2000, 4000 sibling branch}, which would fail with the old whole-table walk only if the walk were wrong, and does fail if the root itself or siblings leak in. Closed.
- **5** project-expense-types-data.service.ts:16, 35 — `subs = new SubSink()`, `this.subs.sink = this.client.getAccounts()…`. Closed.
- **6** UpdateProjectExpenseTypeCommand.cs:26 — `IsActive { get; set; } = true`, symmetric with Create. Closed.
- **7** ar-EG/property-manager.json:93 — `_ExpenseAccount_` = «حساب المصروف». Closed.
- **10** (done part) Create/UpdateProjectExpenseTypeCommand.cs — `[StringLength(50)]` Code, `[StringLength(250)]` NameAr / NameEn in both commands; `using System.ComponentModel.DataAnnotations` added. Closed.
- **11** (done part) ProjectExpenseTypeController.cs:52 — `ProducesResponseType(typeof(ValidationProblemDetails), 400)` added on GetById. Closed.
- **14** project-expense-types-grid.component.html:10, 17 — `class="min-w-0"` on `<dx-data-grid>` and `[wordWrapEnabled]="true"`. Closed.
- **15** project-expense-type-form-popup.component.html:5, 13-15 — `titleTemplate="title"` with `<h6>` in a `dxTemplate`, matching the logistics contract-type precedent. Closed.
- **16** grid.html:89, 100 — `[visible]="hasEditPermission"` / `[visible]="hasDeletePermission"` on both button columns (and on the buttons). Closed.
- **17** grid.ts:25, 74-75; popup.html:121 — `isSaving` set before the request, reset in `finalize`, Save `[disabled]="isSaving"`; `isSaving` passed as `@Input` to the popup. Closed.
- **18** grid.ts:49-50 — `accountValue` returns `''` when both number and name are empty. Closed.

## `disagree` rows — accepted

- **10** `[Required]` / `[Range]` not added: accepted. `ProjectExpenseType.Validate` (ProjectExpenseType.cs:41-63) already returns the resx-keyed `ExpenseTypeCodeRequired` / `…NameRequired` / `…AssetAccountRequired` / `…ExpenseAccountRequired` errors (spec A9, covered by `Create_WithoutRequiredFields_ReturnsEveryRequiredError`); model-state annotations would short-circuit to an un-localised 400 before the handler runs. `[StringLength]` is the only part that was missing and it is in.
- **11** `NotFound()` kept: accepted. The front calls `getById` only for a row it just listed (grid.ts:65-67); `Ok(null)` would open the popup in create mode for a stale row, which is worse than the NSwag exception surfacing as the generic error toast. The 404 is declared in `ProducesResponseType`.

## Left as agreed in round 1

Rows 3, 4, 8, 9 (superseded by 14/15), 12, 13 stay optional nits; row 19 (`property-manager.api.client` pin 1.0.108 → publish from `cr125563` and bump) is the `release-ticket` gate, not an implementer row.

**Round 2 result:** 0 block, 0 should, 0 nit open. Verdict **pass**. No round 3 needed.
