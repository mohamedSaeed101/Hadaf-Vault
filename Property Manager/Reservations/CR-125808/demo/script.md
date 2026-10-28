# CR-125808 — Demo script (draft, waiting for approval)

Environment: the set's local run (PM API from cr125808 on :1618 + front build on :4200) against **db-all / Sabreen_Primary**, company **Sabreen**. The change is not deployed to Stage Beta yet (its Stage_Beta PRs are in conflict).
Voice: Hanafi (Gemini Iapetus) + Arabic captions. Expected length about 1:30.

| # | On screen | Caption / voice |
|---|---|---|
| 1 | Rent Reservations list (التأجير › الحجز) with its columns and the status filter | دي شاشة «حجوزات الإيجار». بنحجز فيها عقار للمستأجر قبل العقد، بعربون حجز. |
| 2 | New reservation: date today, «صالح حتى» +14 days, start +15 days, 1 year, bank transfer, status مسودة | أول ما نفتح حجز جديد، التاريخ والصلاحية وبداية الإيجار بيتملوا لوحدهم من الضبط العام. |
| 3 | Pick project «القدس» → the unit list shows only available rent units → pick the unit | نختار المشروع، فيظهر بس العقارات المتاحة للإيجار في المشروع ده. |
| 4 | Type annual rent 120,000 → deposit becomes 6,000 | نكتب الإيجار السنوي، والعربون بيتحسب لوحده: خمسة في المية من الإيجار. |
| 5 | Pick the tenant; open «+ عميل جديد» briefly and close it (not saved) | نختار المستأجر. ولو مش موجود، ممكن نضيفه من زرار «عميل جديد» من غير ما نسيب الشاشة. |
| 6 | Save → number RR-2026-0004, status مسودة | نحفظ، فيطلع رقم الحجز، والحالة مسودة. المسودة بس اللي ينفع تتعدّل أو تتمسح. |
| 7 | «تأكيد الحجز» → confirm dialog → yes → status مؤكد, form read-only | نأكد الحجز، فالعقار بيبقى «محجوز»، ومحدش يقدر يحجزه تاني. |
| 8 | «إلغاء الحجز» → dialog → yes → status ملغي; back to the list | ولو المستأجر رجع في كلامه، نلغي الحجز، والعقار بيرجع «متاح» على طول. |
| 9 | The list again with the new row ملغي | الخلاصة: حجز بعربون، يأكد العقار، ويتلغي يرجعه. والفاتورة والتحويل لعقد إيجار جايين في مرحلة جاية. |

**Data the take changes on Sabreen (test tenant):** creates reservation RR-2026-0004 for unit T125487-04 («القدس»), confirms it (unit → محجوز, one property-log row) and cancels it (unit → متاح, one more log row). The unit ends Available, as before. Nothing else is saved; the new-customer popup is opened and closed without saving.

**Not shown:** the expired warning (no expired confirmed reservation exists without backdating data), and invoice / receipt / conversion to a lease contract (deferred, deffer.md).

**Sign-in:** `.env.local` has no `ACCFLEX_APP_USER`, so you sign in once by hand in the Chrome window `web_login.py` opens (I never type the password).
