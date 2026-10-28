# CR-125759 decisions

- **Field list (engineer, 2026-10-22, screenshot):** facts.md 4-5. Country, ownership, investment type, cost distribution, sales organization and currency are never auto-created.
- **Q1 Summary (no preference → recommended):** under the import result, a «تم إنشاؤه» section grouped by field, listing the names created. Same on both screens.
- **Q2 Permission (engineer):** the import screen's Add permission (944 / 945) is enough to create the missing lookup records.
- **Q3–Q8 (engineer: "skip all, go ahead" → recommended answers):**
  - Q3 A new Pm_ lookup (type / status / activity / view / model) gets Serial = max(Serial) in its table + 1, incrementing per new record.
  - Q4 A new record's second-language name = the cell text.
  - Q5 A missing value is created only for rows that are valid apart from it; skipped rows create nothing.
  - Q6 Projects: the parent cost center dropdown stays above the upload. If valid rows need a cost center and none is chosen, nothing is imported and the message says so (current ImportParentCostCenterRequired).
  - Q7 Both imports use the projects Normalize (trim, case, alef forms, ة/ه, ى/ي, tashkeel). Existing inactive records are matched, not duplicated. One new record per distinct normalized value per file.
  - Q8 No confirmation dialog: upload validates and imports in one step.
- **Q9 Same name under another parent (business-check-1 advisory; engineer said "skip all" → recommended):** a governorate / city / center is matched only under the row's parent. If the name exists only under a different parent, a new record is created under the row's parent (it is "not defined" there). This replaces the ImportGovernorateNotInCountry / ImportCityNotInGovernorate / ImportCenterNotInCity row errors. The «تم إنشاؤه» section shows it, so a wrong parent in the file is visible. Engineer can override at the plan gate.
- **Q10 Digit-only cells (review-1 row 1, orchestrator, recommended option):** a cell made only of digits is treated as a code; if no record has that code it stays a «not allowed» row error and nothing is created. Names with letters are auto-created as before. The engineer can override.
- **Q11 (engineer, 2026-10-25):** rename «حساب الأصل» → «حساب أعمال تحت التنفيذ» on the Project Expense Types screen (CR-125563, Closed) and ship it on this CR's branch (engineer: "same cr125759"). Scope: screen + the API error messages (engineer). Form label without «(المُرسمل)» (no preference → recommended). See change-note-1.md.
- **Q12 (engineer, 2026-10-25):** rename column `Pm_ProjectExpenseType.AssetAccountId` → `WorkInProgressAccountId` through DB + all code (engineer chose the recommended name and depth). Error enum names / resx keys keep `AssetAccount` (orchestrator call: internal ids). See change-note-2.md.
- **Q13 (orchestrator, 2026-10-25, merge fix):** Master_Stable (cr125638 sale quotations) added `isAvailableForSale` to `ProjectStatus.Create/Update`. A status auto-created by the import gets `false`, same as the column default `DF_Pm_ProjectStatus_IsAvailableForSale` (0); the user turns it on from the status screen. Engineer can override.
