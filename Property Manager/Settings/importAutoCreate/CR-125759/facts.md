# CR-125759 facts

Source: ADO 125759 description (engineer's words, 2026-10-22) and the engineer's annotated template screenshot (chat, 2026-10-22).

1. Upload validates automatically and imports the valid rows in one step; error rows are skipped and shown with their errors. Applies to Import Projects and Import Properties. (ADO 125759 §1)
2. Lookup values the file names but the tenant lacks are created during the import and used for the row. (ADO §2)
3. The result summary shows what was imported and also every lookup record that was created. (ADO §3)
4. Auto-create fields, Import Projects (screenshot, boxed): نوع المشروع (6), حالة المشروع (8), المحافظة (12), المدينة (13), المركز (14), الإطلالة (22), النشاط (23).
   Not boxed, so they must already exist: ملكية المشروع (5), نوع الاستثمار (7), توزيع التكاليف (9), ادارة المبيعات (10), **الدولة (11)**, العملة (21).
5. Auto-create fields, Import Properties (screenshot, boxed): نوع العقار (6), نشاط العقار (8), حالة العقار (9), نموذج العقار (12), اطلالة العقار (17).
   Not boxed: نوع الإستثمار (7). Template shown has 19 columns.
6. Implied repos: AccFlex_Cloud_ERP (PropertyManager API), AccFlex_Cloud_Front (property-manager project). DB: none expected unless a log of created records is needed.
