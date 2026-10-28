START_URL = "http://localhost:4200/apps/Sabreen"
ROUTE = "http://localhost:4200/apps/Sabreen/property-manager/real-estate-settings"


def close_toasts(d):
    for _ in range(4):
        btn = d.page.locator(".toast-close-button:visible")
        if btn.count() == 0:
            break
        try:
            btn.first.click(timeout=1000)
        except Exception:
            break
        d.wait(200)


def tab(d, title):
    d.click(f'.dx-tabs .dx-tab:has-text("{title}") >> nth=0')
    d.wait(1200)


def pane(d):
    return d.page.locator(".dx-multiview-item.dx-item-selected")


def run(d):
    d.settle()
    # non-admin guard needs a local permission entry for module 953 (removed in teardown)
    d.page.evaluate("""() => {
        const cur = JSON.parse(localStorage.getItem('UserPermissions') || '[]');
        if (!cur.find(p => p.ModuleId === 953)) {
            cur.push({ ModuleId: 953, AllowView: true, AllowAdd: true, AllowEdit: true, AllowDelete: true, AllowPrint: true, SelectedUserExtraModulePermissionDto: [] });
            localStorage.setItem('UserPermissions', JSON.stringify(cur));
        }
    }""")
    d.goto(ROUTE)
    d.page.wait_for_selector(".dx-tabs .dx-tab", timeout=60000)
    d.page.wait_for_selector('.dx-texteditor:has(.dx-label span:text-is("الدولة *")) input.dx-texteditor-input', timeout=60000)
    d.wait(2500)
    close_toasts(d)

    # 1 — the screen
    d.mark(1)
    d.move_to('.dx-tabs .dx-tab:has-text("التكاملات الحكومية") >> nth=0')
    d.wait(800)
    d.move_to('.dx-tabs .dx-tab:has-text("عام") >> nth=0')
    d.wait(3500)

    # 2 — general tab: re-pick the country, hints refresh
    d.mark(2)
    d.click('.dx-texteditor:has(.dx-label span:text-is("الدولة *")) .dx-dropdowneditor-button')
    d.wait(1200)
    d.click('.dx-overlay-wrapper .dx-list-item:has-text("مصر")')
    d.wait(2500)
    d.move_to('.dx-texteditor:has(.dx-label span:text-is("رخصة الوساطة العقارية")) input.dx-texteditor-input')
    d.wait(2500)

    # 3 — accounts tab, open one list
    d.mark(3)
    tab(d, "الحسابات")
    d.click('.dx-multiview-item.dx-item-selected .dx-texteditor:has(.dx-label span:text-is("مستحقات ملاك تحت التسوية *")) .dx-dropdowneditor-button')
    d.wait(2500)
    d.page.keyboard.press("Escape")
    d.wait(1500)

    # 4 — save with a missing account
    d.mark(4)
    owner = '.dx-multiview-item.dx-item-selected .dx-texteditor:has(.dx-label span:text-is("مستحقات ملاك تحت التسوية *"))'
    d.move_to(owner + " input.dx-texteditor-input")
    d.wait(400)
    d.click(owner + " .dx-clear-button-area")
    d.wait(800)
    tab(d, "عام")
    d.page.keyboard.press("Control+S")
    d.wait(3500)
    # put the account back so the final save is complete
    d.click(owner + " .dx-dropdowneditor-button")
    d.wait(1200)
    d.page.keyboard.press("ArrowDown")
    d.page.keyboard.press("Enter")
    d.wait(1500)
    close_toasts(d)

    # 5 — defaults tab + (i) hint
    d.mark(5)
    tab(d, "القيم الافتراضية")
    d.move_to("#reSettingsHintReservationValidityDays")
    d.wait(2500)
    d.move_to('.dx-multiview-item.dx-item-selected .dx-texteditor:has(.dx-label span:text-is("أيام السماح قبل التأخير")) input.dx-texteditor-input')
    d.wait(1500)

    # 6 — revenue tab: manual, then automatic
    d.mark(6)
    tab(d, "إثبات الإيراد")
    d.click('.dx-multiview-item.dx-item-selected .dx-radiobutton:has-text("يدوي")')
    d.wait(2500)
    d.click('.dx-multiview-item.dx-item-selected .dx-radiobutton:has-text("تلقائي")')
    d.wait(1500)
    d.click('.dx-multiview-item.dx-item-selected .dx-radiobutton:has-text("نسبة الإنجاز")')
    d.wait(2500)
    d.scroll(300)
    d.wait(1500)

    # 7 — penalties tab: restore country defaults
    d.mark(7)
    tab(d, "غرامات التأخير والتعثر")
    d.wait(2000)
    d.click('.dx-multiview-item.dx-item-selected .dx-button:has-text("استرجاع افتراضيات الدولة")')
    d.wait(3500)

    # 8 — integrations tab, save all
    d.mark(8)
    tab(d, "التكاملات الحكومية")
    d.wait(2000)
    d.page.keyboard.press("Control+S")
    d.wait(3500)
    d.wait(1500)
