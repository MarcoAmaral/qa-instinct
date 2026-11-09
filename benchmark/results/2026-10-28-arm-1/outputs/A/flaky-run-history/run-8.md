# CI Flakiness Analysis

## Flaky Tests (Require Action)

### 1. search > filters results by tag
**Flake rate:** 40% (4/10 failures)  
**Root cause:** Test isolation failure. The test depends on a seeded `"summer"` tag, but `tags.spec.ts` renames this tag during its own run. When test specs run concurrently, this test reads stale or missing tag data. Evidence: passes 20/20 when run alone (`--workers=1`).  
**Action:** Add test isolation by either:
- Using unique, timestamped tags for each spec (e.g., `summer_${Date.now()}`)
- Resetting shared test data between specs
- Running `tags.spec.ts` sequentially before other tag-dependent tests, or isolate it to its own worker

### 2. cart > updates the total when the quantity changes
**Flake rate:** 30% (3/10 failures)  
**Root cause:** Insufficient wait. The test uses `page.waitForTimeout(300)` (hard-coded delay), but the DOM update takes variable time. When the backend is slow or under load, 300ms is insufficient; the test reads the stale total (€29.00 instead of €58.00).  
**Action:**
- Replace `page.waitForTimeout(300)` with a web-first assertion: `await expect(locator).toContainText('€58.00')` or `await page.waitForSelector('[data-total="€58.00"]')`
- This polls the DOM until the expected value appears (default 30s timeout), eliminating races

### 3. orders > shows the latest order first
**Flake rate:** 20% (2/10 failures); 6% when isolated (3/50)  
**Root cause:** Backend eventual consistency. The order creation API returns success, but GET /orders doesn't include the new order immediately (up to 2 seconds latency). The test reads stale state.  
**Action:**
- Add a wait-for-order loop: fetch `/orders` in a retry loop until the expected order appears, with ~500ms poll interval and 5s total timeout
- Or, wait at the API level by querying a known-order endpoint before navigating to the orders page
- Consider whether the backend latency is a separate bug (SLA violation) worth fixing at the source

---

## Non-Flaky Issues (Different Action)

### profile > saves a new avatar
**Failure rate:** 100% (10/10 failures, 0% pass rate)  
**Root cause:** Not flaky—consistently broken. Avatar field is `undefined` in every run, suggesting a missing test fixture, broken upload endpoint, or incorrect selector.  
**Action:** This is a **blocking bug**, not a flake. Investigate the avatar upload flow (fixture, endpoint, DOM selector) and fix before re-running. Consider blocking this test with `.skip()` until fixed.

### login > signs in with valid credentials
**Flake rate:** 0% (10/10 passes)  
**Action:** None—reliable test, no action needed.
