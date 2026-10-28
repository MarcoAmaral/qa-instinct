# CI Flakiness Analysis

## Summary
**2 flaky tests** (require fixes), **1 consistently broken test** (feature bug), **1 stable test**.

---

## Flaky Tests

### 1. `cart > updates the total when the quantity changes`
- **Flakiness**: 30% (3 failures in 10 runs)
- **Root Cause**: Hardcoded wait insufficient for DOM update. The test reads a total of €29.00 (half the expected €58.00), indicating the quantity increment either didn't propagate to the price calculation or the second item wasn't counted before the read.
- **Why It's Flaky**: Network latency, processing time, and browser rendering speed vary; 300ms is not guaranteed.
- **Action**: Replace `page.waitForTimeout(300)` with web-first assertions. Use `expect(locator).toContainText('€58.00')` which polls until the condition is met or timeout.

### 2. `search > filters results by tag`
- **Flakiness**: 40% (4 failures in 10 runs)
- **Root Cause**: Test data isolation failure under parallel execution. The test uses a seeded `"summer"` tag, but `tags.spec.ts` renames that tag during concurrent runs (4 workers). When the rename fires before the search test queries, the search test finds 5 unfiltered results instead of 3 filtered results. The test passes 20/20 in isolation because no concurrent mutations occur.
- **Why It's Flaky**: Parallel workers execute tests in non-deterministic order; shared test data has no synchronization.
- **Action**: Isolate test data—either (a) use unique tag names per test run (e.g., `summer-<uuid>`), (b) use `test.describe.serial()` for tests that share state, or (c) reset shared data in a `beforeEach()` hook that runs per-worker.

### 3. `orders > shows the latest order first`
- **Flakiness**: 20% (2 failures in 10 runs; 6% in isolated 50-run repeat)
- **Root Cause**: Backend latency. The order is created but GET /orders does not immediately return it; a manual repeat-50 test with new users showed 3 failures where the order appeared 0–2 seconds later.
- **Why It's Flaky**: The test reads the order list once immediately after creation. If the backend hasn't finished persisting or replicating, the new order is missing.
- **Action**: Replace immediate textContent read with web-first assertions. Use `expect(page.locator('text=Order #1043')).toBeVisible()` which polls the DOM until the element appears or timeout (default 30s). If 30s+ is unreasonable, investigate backend slow queries or post-create webhooks; add a deterministic check (e.g., poll GET /orders until new order is present) to the test or backend.

---

## Consistently Broken (Not Flaky)

### 4. `profile > saves a new avatar`
- **Failure Rate**: 100% (10/10)
- **Root Cause**: Feature bug, not flakiness. The avatar property is undefined after save—either the upload endpoint fails silently, the response doesn't include the new avatar, or the UI doesn't refresh.
- **Action**: This is a legitimate bug. Debug: (a) check the upload request/response in DevTools, (b) verify the backend returns the avatar URL, (c) check that the UI component re-renders after save. Not a test fix; requires code fix.

---

## Stable Test

### 5. `login > signs in with valid credentials`
- **Failure Rate**: 0% (10/10 pass)
- **Action**: No action needed.

---

## Recommendations
1. **Immediate**: Fix `cart` test (easiest—switch to waitFor assertions).
2. **High Priority**: Fix `search` test (data isolation is a blocker for reliable parallel tests).
3. **Medium Priority**: Fix `orders` test and investigate backend latency.
4. **Separate Track**: Debug and fix the `profile` avatar feature.
