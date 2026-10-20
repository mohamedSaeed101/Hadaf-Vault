import json, os, sys, time
from playwright.sync_api import sync_playwright

D = sys.argv[1]
BASE = "http://localhost:4200/apps/UNP-Ali/payroll"
PROFILE = os.path.join(os.environ["LOCALAPPDATA"], "accflex-playwright-profile")
segs = {}
t0 = None


def now():
    return round(time.time() - t0, 2)


def start(n):
    segs.setdefault(n, {})["start"] = now()


def end(n, hold=1.5):
    time.sleep(hold)
    segs[n]["end"] = now()


def click_btn(page, text):
    page.locator(".dx-button", has_text=text).first.click()


def preview_and_wait(page, grid="report-grid dx-data-grid"):
    click_btn(page, "عرض")
    page.wait_for_function(
        "g => { const el=[...document.querySelectorAll(g)].pop(); return el && el.querySelectorAll('.dx-data-row').length > 0 }",
        arg=grid, timeout=30000)


def open_print(page):
    click_btn(page, "طباعة")
    dlg = page.locator(".dx-overlay-content", has_text="تحديد التنسيق")
    dlg.wait_for(state="visible", timeout=20000)
    time.sleep(0.8)
    dlg.locator(".dx-button", has_text="اختيار").click()
    page.wait_for_function(
        "() => [...document.querySelectorAll('.dx-overlay-content')].some(o => o.offsetParent && /Document is ready/.test(o.innerText))",
        timeout=60000)


def close_print(page):
    page.keyboard.press("Escape")
    time.sleep(0.5)
    btn = page.locator(".dx-popup-title .dx-closebutton:visible, .dx-overlay-content:visible .dx-icon-close").first
    if btn.count():
        btn.click()
    time.sleep(0.8)


def goto(page, path, ready_text="عرض"):
    page.goto(f"{BASE}/{path}")
    page.locator(".dx-button", has_text=ready_text).first.wait_for(timeout=60000)
    time.sleep(2.5)


with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(
        PROFILE, channel="chrome", headless=True, ignore_https_errors=True,
        viewport={"width": 1366, "height": 768},
        record_video_dir=os.path.join(D, "rec"), record_video_size={"width": 1366, "height": 768},
        args=["--lang=ar-EG"])
    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    t0 = time.time()
    page.goto("http://localhost:4200/apps/UNP-Ali")
    page.evaluate("() => { localStorage.setItem('SelectedLang','ar-EG'); localStorage.setItem('currentLang','ar-EG'); }")

    # 1-2 Employee Save
    goto(page, "human-resource-reports/employee-save-report")
    start(1); end(1, 4)
    start(2); preview_and_wait(page); end(2, 3)
    # 3 print
    start(3); open_print(page); end(3, 5)
    close_print(page)

    # 4 Medical Insurance
    goto(page, "human-resource-reports/insurance-report")
    start(4)
    page.locator("dx-radio-group .dx-item", has_text="تم تسليمها").first.click(); time.sleep(1.2)
    page.locator("dx-radio-group .dx-item", has_text="لم يتم تسليمها").first.click(); time.sleep(1.2)
    page.locator("dx-radio-group .dx-item", has_text="الكل").first.click(); time.sleep(0.8)
    click_btn(page, "عرض"); end(4, 3)

    # 5-6 Employee Statistics
    goto(page, "employee-statistics")
    start(5)
    page.evaluate("""async () => {
        const inst = el => ng.getComponent(el)?.instance;
        const dbs=[...document.querySelectorAll('dx-date-box')].map(inst).filter(Boolean);
        dbs[0].option('value', new Date(2000,0,1)); dbs[1].option('value', new Date(2026,11,31));
        await inst(document.querySelector('pay-shared-employee-list dx-data-grid')).selectAll();
    }""")
    time.sleep(1.5)
    preview_and_wait(page, "report-grid-multi-request dx-data-grid"); end(5, 3)
    start(6)
    page.evaluate("""async () => {
        const g=ng.getComponent(document.querySelector('report-grid-multi-request dx-data-grid')).instance;
        await g.expandRow(g.getVisibleRows().find(r=>r.rowType==='data').key);
    }""")
    page.wait_for_function("() => document.querySelectorAll('report-grid-multi-request dx-data-grid').length > 1", timeout=30000)
    end(6, 4)

    # 7-9 Risk Analysis
    goto(page, "risk-analysis-settlements")
    start(7)
    page.evaluate("() => ng.getComponent(document.querySelector('dx-drop-down-box')).instance.option('value',[17,30,31])")
    time.sleep(1.2)
    preview_and_wait(page); end(7, 4)
    start(8); open_print(page); end(8, 5)
    close_print(page)
    start(9); end(9, 4)

    video = str(page.video.path())
    ctx.close()

json.dump({"video": video, "segs": segs}, open(os.path.join(D, "marks.json"), "w"), indent=1)
print(json.dumps({"video": video, "segs": segs}))
