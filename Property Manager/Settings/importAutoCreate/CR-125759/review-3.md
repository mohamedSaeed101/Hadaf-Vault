# Review round 3 — CR_125759 (iterate, change-note-1)   base ERP 1c2d2313 / Front af569bec   head: ERP c50c77ad / Front c3d7cda1 + uncommitted working trees on `cr125759`   verdict: pass

Scope: the uncommitted diff only (`git diff` in both repos); everything committed was reviewed in review-1 / review-2. Spec = change-note-1.md (decisions.md Q11).

Checked:

- Files touched: exactly the 5 named (ERP `Resource.resx`, `Resource.en.resx`, `Resource.Designer.cs`; Front `ar-EG/property-manager.json`, `en-US/property-manager.json`). 21/21 lines ERP, 4/4 Front. Nothing else dirty.
- i18n: only `PmProjectExpenseTypes._AssetAccount_` / `_AssetAccountField_` changed; `ASSETS._AssetAccount_` / `FIXEDASSETS._AssetAccount_` (general-accounting) untouched. Both keys used only by the PM expense-type grid (`project-expense-types-grid.component.html:55`) and form popup (`project-expense-type-form-popup.component.html:69`). «(المُرسمل)» / "(Capitalised)" dropped from the field label as the note says.
- resx: the 7 messages (`ExpenseTypeAssetAccountRequired`, `…Duplicated`, `ExpenseTypeInvalidAssetAccount`, `ExpenseTypeSameAccounts`, `…HasPostings`, `…InUse`, `…NotCostCenterLinked`) changed in ar + en, with the 7 matching Designer.cs `Looks up a localized string similar to` comments. No `data name` / key / property renamed.
- Arabic: «حساب أعمال تحت التنفيذ» reads correctly as a noun phrase in every slot (subject, object of «تغيير», and after «يكون»); the rest of each sentence is the pre-existing wording. «من نوع أصول» in `ExpenseTypeInvalidAssetAccount` is still right: a WIP account is an asset-type account.
- English: "Work in Progress Account" (title case) in the two labels; "work in progress account" (lower) in all 7 messages, consistent with the note.
- Encoding / EOL: all three resx/Designer files UTF-8 BOM + CRLF both at HEAD and now; `ar-EG` JSON UTF-8 BOM + LF at HEAD and now; `en-US` JSON no BOM + LF at HEAD and now. Both JSON files parse (after the pre-existing BOM, same as HEAD).
- Leftover «حساب الأصل» / "asset account" on that screen: none user-visible. Remaining hits are C# `///` doc comments (`ProjectExpenseTypeController.cs:18,79`, `ProjectExpenseTypeAccountValidator.cs:58,79`, `ProjectExpenseTypeDto.cs:21`, test context `:54`) and the code identifiers `AssetAccount*` — out of scope per the note ("No key, column or code name changes").
- Tests: PM tests assert `ProjectExpenseTypeError.<name>.ToString()` (enum names), not the resource text, so the text change cannot break them; no test asserts the old Arabic/English text.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| — | — | — | — | no findings | — |
