# Flaky Test Analysis

## 🚨 cart > updates the total when the quantity changes
**Flakiness: 30% (3/10 failures)**

**Root Cause:** Insufficient wait time. The test waits 300ms with `page.waitForTimeout(300)` then immediately reads the total. Half the time (€29.00 vs €58.00), the UI hasn't updated yet.

**Action:** Replace fixed timeout with web-first assertions. Instead of `waitForTimeout(300)` + `textContent()`, use `page.locator('[data-testid="total"]').toContainText("€58.00")`, which polls until the value matches. Web-first assertions are built for exactly this.

---

## 🛑 profile > saves a new avatar
**Flakiness: N/A (0% pass rate — 100% consistently broken)**

**Root Cause:** This is not a flaky test. The avatar feature is broken: the saved value is `undefined` when it should be `"avatar.png"`. Either the save endpoint fails silently, the upload is lost, or the retrieval query is wrong.

**Action:** **This is a bug, not a flake.** Debug the avatar upload path end-to-end: does the form submit? Does the API accept the file? Does the database store it? Is the retrieve query finding it? Consider adding logs or using DevTools in the test to inspect the network requests. Disable or skip this test in CI until fixed.

---

## ⚠️ search > filters results by tag
**Flakiness: 40% (4/10 failures)**

**Root Cause:** Test isolation failure. `tags.spec.ts` runs in parallel (4 workers) and renames the seeded `"summer"` tag. The search test expects 3 results tagged "summer", but finds 5 (either unfiltered or tagged with a different version of the tag). Runs in isolation pass 20/20 because no other test interferes.

**Action:** 
- **Preferred:** Add cleanup to `tags.spec.ts` (restore the tag name to "summer" after the test, or use a transaction/rollback).
- **Fallback:** Run `tags.spec.ts` serially with `--serial` to prevent parallel interference.
- **Last resort:** Use dedicated test data per test (clone the database, seed it per test run, tear it down after).

---

## ⏱️ orders > shows the latest order first
**Flakiness: 20% (2/10 failures); may be higher under load**

**Root Cause:** Backend race condition. After creating an order, `GET /orders` takes up to 2 seconds to return it. The test checks too soon. Even with web-first assertions (which wait), a 50-repeat run still failed 3/50 times, suggesting the backend regularly takes 2+ seconds.

**Action:**
- **Root fix:** Debug the backend. Is there a cache miss? A database replication delay? A lock contention on the orders table? Trace a single order creation and see where the 2-second gap is.
- **Interim workaround:** Use `page.locator('[data-testid="orders"] >> text="Order #1043"').waitFor({ timeout: 5000 })` or similar, with a generous timeout. This masks the backend issue but buys time to fix it.
- **Monitoring:** Add a metric to track order creation-to-list-visibility latency in production. This kind of delay suggests a real user-facing problem.

---

## ✅ login > signs in with valid credentials
**Status:** Solid — 10/10 passes. No action needed.
