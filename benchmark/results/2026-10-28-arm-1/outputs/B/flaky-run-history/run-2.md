# QA Analysis: Flaky Test Report

## Executive Summary
3 of 5 tests are flaky; 1 is consistently broken; 1 is stable. Flakiness roots: timing assumptions (1), test isolation (1), backend eventual consistency (1).

---

## Flaky Tests

### 1. **cart > updates the total when the quantity changes**
- **Flakiness**: 30% failure rate (3 of 10 runs)
- **Root Cause**: Fixed 300ms timeout is insufficient for DOM update. Test expects the price total to double when quantity increases from 1 to 2, but sometimes receives the old value, suggesting the UI update races the 300ms delay.
- **Recommendation**: Replace hard timeout with web-first assertion. Use `page.locator('[data-test-id="total"]').toContainText("€58.00")` with Playwright's built-in retry logic (default 30s timeout), which polls until the value stabilizes. Remove `page.waitForTimeout()`.

### 2. **search > filters results by tag**
- **Flakiness**: 30% failure rate (3 of 10 runs); passes consistently in isolation
- **Root Cause**: Test isolation failure. The "summer" tag is seeded for this test but modified by `tags.spec.ts` running in parallel (4 workers). When both specs run concurrently, the tag mutation race creates stale filter state. Passing in `--workers=1` confirms parallel contamination.
- **Recommendation**: Isolate tag state between specs. Either (a) use a unique tag per test run (UUID-based), (b) create a fresh tag in a beforeEach hook, or (c) add worker-scoped database cleanup in config to reset tags before each spec. Prefer (b): generate a unique tag in beforeEach rather than relying on seed data.

### 3. **orders > shows the latest order first**
- **Flakiness**: 20% failure rate (2 of 10 runs); 6% failure rate in isolation with repeat-each=50
- **Root Cause**: Backend eventual consistency. The order is created, but GET /orders does not return it immediately—latency up to 2 seconds observed. Test checks for the new order immediately after creation, racing a database sync or async write.
- **Recommendation**: Use web-first assertions. After creating an order, wait with `page.locator('[data-test-id="order-list"]').getByText(/Order #1043/).waitFor()` or equivalent, with a retry timeout of 5–10 seconds to account for backend propagation delay. This converts timing assumptions into resilient polling.

---

## Consistently Failing Test (Not Flaky)

### 4. **profile > saves a new avatar**
- **Flakiness**: None (0% pass rate—consistently broken)
- **Root Cause**: Test failure is deterministic. The avatar is not being saved at all (received: undefined instead of "avatar.png"). This indicates a functional defect, not timing.
- **Recommendation**: This is a blocker bug, not a flaky test. File a production issue: avatar upload is broken. Mark the test as expected failure (`test.skip`) or move to a blocked/quarantine suite until the feature is fixed. Do not retry or add workarounds in the test; fix the implementation.

---

## Stable Test (No Action Needed)

### 5. **login > signs in with valid credentials**
- **Flakiness**: None (100% pass rate)
- **Recommendation**: No action. This is a healthy baseline reference for test infrastructure.

---

## Remediation Priority
1. **High**: orders > shows the latest order first — impacts critical user flow (order creation); fix with web-first assertions
2. **High**: profile > saves a new avatar — functional defect in production; fix backend feature
3. **Medium**: cart > updates the total when the quantity changes — impacts core UX; fix with web-first assertions
4. **Medium**: search > filters results by tag — impacts data isolation; implement per-test tag cleanup

All flaky tests should be fixed with web-first assertions and test isolation improvements, not by increasing timeouts or adding retries.
