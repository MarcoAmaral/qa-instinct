## E2E Test Flakiness Analysis

### Flaky Tests

#### 1. **cart > updates the total when the quantity changes**
- **Status**: Flaky (3 failures in 10 runs, 30% failure rate)
- **Root Cause**: Race condition. The test uses a fixed 300ms timeout followed by a single `textContent()` read. The €29.00 (half of €58.00) indicates the quantity increment is not yet reflected in the UI when the assertion runs, suggesting the DOM update is slower than the timeout on those runs.
- **Recommendation**: Replace `page.waitForTimeout(300)` with a web-first assertion that polls until the expected value appears (e.g., `expect(totalElement).toContainText('€58.00')` with built-in retry). This removes dependency on arbitrary timing.

#### 2. **search > filters results by tag**
- **Status**: Flaky (4 failures in 10 runs, 40% failure rate) — but 20/20 pass when run alone
- **Root Cause**: Test isolation failure. The test seeds the "summer" tag, but `tags.spec.ts` renames that tag during concurrent runs. When both tests execute in parallel, the shared test data is corrupted, causing stale queries to return extra results.
- **Recommendation**: Isolate test data. Either (a) give each test a unique tag name (e.g., include a run/worker ID), (b) run tag-related specs sequentially, or (c) reset seeded data before each test via a database fixture or API call.

#### 3. **orders > shows the latest order first**
- **Status**: Flaky (2 failures in 10 runs, 20% failure rate; 3 failures in 50 repeats alone)
- **Root Cause**: Backend consistency lag. The GET /orders endpoint returns a stale list for up to 2 seconds after order creation, indicating eventual consistency or database replication delay in the backend.
- **Recommendation**: This is a backend issue, not a test flake. Replace the single read with a web-first assertion that retries: `expect(page.locator('text=Order #1043')).toBeVisible()` will poll with retry logic until the fresh data appears. Alternatively, verify with the API team whether read-after-write consistency can be tightened; consider adding a test-only synchronization endpoint if needed.

### Non-Flaky Tests

#### **profile > saves a new avatar**
- **Status**: Broken, not flaky (10/10 failures, same error every run)
- **Root Cause**: Feature or test defect. The avatar upload returns `undefined` instead of "avatar.png", indicating either the upload fails, the response parsing is wrong, or the test selector is invalid.
- **Recommendation**: Debug the feature: check that the avatar upload endpoint works, verify the response schema, and confirm the test selector matches the actual DOM. Fix the underlying issue before resuming test maintenance.

#### **login > signs in with valid credentials**
- **Status**: Stable (10/10 passes)
- **Recommendation**: No action needed.
