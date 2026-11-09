# CI Flakiness Analysis Report

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Flakiness Rate:** 30% (3 failures in 10 runs)

**Root Cause:** Insufficient hardcoded timeout for DOM update. The test waits 300ms after clicking "+", but the price calculation is completing asynchronously beyond that window on some runs.

**Action:** Replace the fixed `page.waitForTimeout(300)` with a web-first assertion that polls for the expected value. Use `page.locator('[data-testid="total"]').toContainText('€58.00')` or similar to implicitly wait until the price updates. This makes the test resilient to timing variance in the application's render cycle.

---

### 2. search > filters results by tag
**Flakiness Rate:** 30% (3 failures in 10 runs)

**Root Cause:** Test isolation failure under parallel execution. The `tags.spec.ts` test renames the "summer" tag during its run. When the search test runs in parallel (4 workers), it sometimes queries after the rename, getting 5 results instead of the seeded 3. Passing all 20 repeats when run alone (single worker) confirms this.

**Action:** Fix test data isolation. Either:
- Make `tags.spec.ts` use a unique, dynamically-generated tag name that cannot collide with other tests.
- Add teardown in `tags.spec.ts` to restore the tag to its original state after renaming.
- Revert to deterministic test data between runs (e.g., reset the database or mock tag data).

---

### 3. orders > shows the latest order first
**Flakiness Rate:** 20% (2 failures in 10 runs)

**Root Cause:** Backend API lag. POST order creation completes, but GET /orders does not return the new order immediately; the user finds it missing for up to 2 seconds. A 50-repeat run solo saw 3 failures, indicating this is a real backend consistency issue, not test-specific.

**Action:** Replace hard assertions with web-first assertions that poll the GET /orders endpoint until the expected order appears:
```
await page.locator('text=Order #1043').waitFor({ timeout: 5000 });
```
This masks a potential backend bug (order creation not immediately visible), so also log this as a backend investigation: why is there a 2-second lag between order creation and visibility in the list? This may indicate missing indexes or async processing that should be synchronous.

---

## Non-Flaky Tests

### profile > saves a new avatar
**Failure Rate:** 100% (10 consecutive failures)

**Classification:** Not flaky—this is a consistent functional failure.

**Action:** Debug as a bug, not a flaky test. Investigate:
- Is the avatar upload POST succeeding?
- Does the GET /profile return the avatar field, or is it missing entirely?
- Is the selector targeting the correct DOM element?
- Check browser console for errors during upload.

This test should be **blocked** until the feature is fixed; re-enable after verification in staging.

### login > signs in with valid credentials
**Failure Rate:** 0% (10 consecutive passes)

**Action:** No action. This test is stable and suitable as a smoke/confidence check.
