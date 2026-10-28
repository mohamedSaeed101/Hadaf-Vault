# CR-125759 change note 1 (iterate, 2026-10-25)

- **What:** on the Project Expense Types screen («أنواع تكاليف المشاريع», built in CR-125563, which is Closed), rename «حساب الأصل» to «حساب أعمال تحت التنفيذ»: grid column, form field (drop «(المُرسمل)»), and the 7 API validation messages that name it. English: "Work in Progress Account" / "work in progress account".
- **Where:** Front `accflex-erp\src\assets\i18n\{ar-EG,en-US}\property-manager.json`, section `PmProjectExpenseTypes` keys `_AssetAccount_`, `_AssetAccountField_` only (the ASSETS / FIXEDASSETS keys in other modules stay). API `PropertyManager.Logic\Resources\Resource.resx` + `Resource.en.resx` values at lines ~505-538 (+ the matching `Resource.Designer.cs` doc comments). No key, column or code name changes.
- **Test:** `npm run testing` 0 errors; prettier on the two JSON files; PropertyManager.API build 0 errors; PM tests that assert these messages (grep) still pass.
- **Risk:** text only. Another screen using the same i18n keys would change too: grep shows only the expense-type grid and form use them.
- **Rollback:** revert the commit.
