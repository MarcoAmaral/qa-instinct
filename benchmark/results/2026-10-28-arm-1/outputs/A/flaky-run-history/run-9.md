# Flaky Test Analysis

## Flaky Tests (Intermittent Failures)

### 1. cart > updates the total when the quantity changes
**Failure rate:** 30% (3/10 failures)

**Root cause:** Race condition on quantity update. The test uses a fixed 300ms timeout via `page.waitForTimeout(300)`, then reads the total once. This timeout is insufficient; the backend or frontend quantity update takes longer than 300ms in ~30% of runs.

**Why it's flaky:** Timing is non-deterministic. Network latency, server processing time, or frontend re-render timing varies across runs.

**What to do:** Replace `page.waitForTimeout(300)` with a web-first assertion. Use `page.locator('[data-testid="total"]').toContainText('€58.00')` or equivalent `waitFor()` that polls until the expected value appears. This converts a race condition into a reliable wait.

---

### 2. search > filters results by tag
**Failure rate:** 40% (4/10 failures)

**Root cause:** Test isolation failure. The `tags.spec.ts` test runs concurrently (4 workers) and renames the "summer" tag mid-suite. The search test depends on that tag existing with its original name. When both tests run in parallel, the rename race is lost ~40% of the time.

**Why it's flaky:** Concurrency. Running the search spec alone (1 worker, 20 repeats) passes 100%, proving the test itself is sound.

**What to do:** 
- **Option A (recommended):** Use test fixtures or a setup hook to create unique tag data per test run (e.g., "summer-12345") instead of relying on seeded global state.
- **Option B:** Reorder specs so tags.spec.ts runs before search.spec.ts, then use serial execution or configure worker parallelism to avoid concurrent tag modifications.
- **Option C:** Mock the tags endpoint to return controlled data.

---

### 3. orders > shows the latest order first
**Failure rate:** 20% (2/10 failures)

**Root cause:** Backend eventual consistency delay. The test creates an order, then immediately polls for it. The GET /orders endpoint returns stale data—the newly created order doesn't appear for up to 2 seconds after creation. This is a classic eventual consistency issue (possibly read-after-write, caching, or async persistence).

**Why it's flaky:** Backend response times are non-deterministic. Alone with 50 repeats and fresh users, it fails 6% of the time, confirming the backend is the culprit, not test logic.

**What to do:** Replace hard assertions with web-first waits. Use `page.waitForFunction()` or `expect.poll()` to retry the GET /orders call until the expected order appears (with a reasonable timeout, e.g., 5 seconds). Alternatively, work with backend to ensure orders are visible immediately after creation.

---

## Consistently Broken (Not Flaky)

### profile > saves a new avatar
**Failure rate:** 100% (10/10 failures)

**Root cause:** Feature is broken, not flaky. The avatar field is always `undefined`, indicating the upload or save operation fails consistently.

**What to do:** This is a real bug, not a test problem. Investigate:
- Does the avatar file upload actually reach the server?
- Is the form submission failing?
- Is the API endpoint returning an error that's being silenced?
- Run the feature manually to confirm it's broken in the app itself.

Fix the bug in the app, not the test. Only enable this test once the feature works.

---

## Reliable (No Action Needed)

### login > signs in with valid credentials
**Failure rate:** 0% (0/10 failures)

No action. This test is solid.

---

## Summary Table

| Test | Status | Failure Rate | Fix Priority |
| --- | --- | --- | --- |
| cart | Flaky | 30% | High – replace timeout with waitFor |
| profile | Broken | 100% | Critical – fix feature first |
| search | Flaky | 40% | High – isolate test data |
| orders | Flaky | 20% | Medium – add eventual consistency wait |
| login | Reliable | 0% | None |
