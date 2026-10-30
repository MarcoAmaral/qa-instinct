# Flaky Test Analysis Report

## Summary
- **3 flaky tests** identified (intermittent failures)
- **1 broken test** identified (consistently failing—not flaky)
- **1 stable test** (100% pass rate)

---

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Failure Rate:** 30% (3/10)  
**Severity:** High  
**Root Cause:** Insufficient wait time before assertion. The test waits 300ms and reads once, but the DOM update takes longer than 300ms on some runs.

**Action:**
- Replace `page.waitForTimeout(300)` with a web-first assertion: `await expect(totalElement).toContainText("€58.00")` with Playwright's built-in retry logic (default timeout 5s).
- Remove the static sleep entirely; let Playwright poll until the expected value appears.
- This eliminates timing races and makes the test more robust.

---

### 2. search > filters results by tag
**Failure Rate:** 40% (4/10)  
**Severity:** High  
**Root Cause:** Test isolation failure. The test depends on a seeded "summer" tag, but `tags.spec.ts` renames it during its run. Parallel execution or run order causes the tag to be missing when this test runs. Passes 20/20 in isolation (single worker, dedicated tag state).

**Action:**
- **Isolate test data:** Create a unique tag (e.g., `summer-search-${uuid}`) for this test instead of relying on a shared seed.
- Or: Reset the "summer" tag state before this test runs (add a setup fixture).
- Or: Enforce serial execution of `tags.spec.ts` and `search.spec.ts` (set `fullyParallel: false` for these, or use `@serial` fixture).
- Recommended: Use per-test unique data. This scales better than coordination.

---

### 3. orders > shows the latest order first
**Failure Rate:** 20% (2/10); 6% when repeated (3/50)  
**Severity:** Medium (backend reliability issue)  
**Root Cause:** Backend race condition. The `GET /orders` endpoint returns stale data for up to 2 seconds after order creation—eventual consistency delay or cache invalidation lag.

**Action:**
- **Fix the backend:** Ensure GET /orders reflects newly created orders immediately (fix cache invalidation, use strong consistency, or add a sync point).
- **Workaround for now:** Add a polling loop in the test:
  ```
  await expect(async () => {
    const response = await page.request.get('/orders');
    const orders = await response.json();
    expect(orders[0].id).toBe('Order #1043');
  }).toPass({ timeout: 5000 });
  ```
- This makes the test resilient while the backend issue is being fixed.

---

## Broken Tests (Not Flaky)

### profile > saves a new avatar
**Failure Rate:** 100% (10/10)  
**Severity:** Critical  
**Root Cause:** Consistently failing, not intermittent. Either:
- The upload endpoint is broken and always returns undefined for avatar name.
- The test setup is broken (missing auth, invalid file, malformed request).
- The UI element doesn't exist or the assertion selector is wrong.

**Action:**
- **Investigate immediately.** This is a broken test or broken feature, not a flaky one. Run the test locally with `--debug` to see what's happening.
- Check: Is the avatar upload endpoint working? Is the test using the correct selectors? Is auth set up?
- Once fixed, add it to your deployment checklist (don't ship with 100% failure).
- Do not retry broken tests; fix the root cause.

---

## Stable Tests

### login > signs in with valid credentials
**Failure Rate:** 0% (10/10)  
**Severity:** N/A  
**Status:** Healthy. Keep as a benchmark for what stable looks like.
