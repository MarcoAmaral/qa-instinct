## CI Flakiness Analysis

### Stable Tests
- **login > signs in with valid credentials**: 10/10 passes. No action needed.

### Consistently Broken (Not Flaky)
- **profile > saves a new avatar**: 0/10 passes. This is a genuine bug, not flakiness. The test consistently receives `undefined` instead of "avatar.png", indicating the avatar property is not being set or returned. **Action**: Debug the avatar upload/save flow; check the API response and form submission. Fix the underlying issue, not the test.

### Flaky Tests

#### 1. cart > updates the total when the quantity changes
- **Flakiness**: 30% (3 failures in 10 runs)
- **Root cause**: Insufficient wait time. The test clicks "+", waits 300ms, then reads the total synchronously. The quantity update is completing (the total is "€29.00" instead of "€58.00", showing the UI did update), but the timing is racing against the calculation or rendering. The hard-coded 300ms timeout is not reliable.
- **Action**: Replace the fixed 300ms wait with a web-first assertion that waits for the total to update to "€58.00". Example: `await expect(totalElement).toHaveText('€58.00')`.

#### 2. search > filters results by tag
- **Flakiness**: 40% (4 failures in 10 runs); 0% when run alone with `--workers=1`
- **Root cause**: Test isolation failure. The test relies on a seeded "summer" tag, but `tags.spec.ts` renames this tag during parallel execution. When both specs run concurrently, the "summer" tag is sometimes renamed before this test filters by it, causing 5 results (unfiltered or filtered incorrectly) instead of 3.
- **Action**: Either (a) isolate test data by using unique tag names per test run (e.g., UUID-based tags), (b) add test serialization so `tags.spec.ts` runs before `search.spec.ts`, or (c) revert any tag changes in `tags.spec.ts` teardown. Do not retry this test; that masks the root issue.

#### 3. orders > shows the latest order first
- **Flakiness**: 20% (2 failures in 10 runs); ~6% when run alone with `--repeat-each=50`
- **Root cause**: Eventual consistency lag. The order is created successfully, but the GET /orders endpoint does not return the new order for up to 2 seconds post-creation. The test checks immediately after creation without waiting for the new order to appear in the list.
- **Action**: Replace the synchronous read with a web-first assertion or polling loop that waits for the new order to appear in the list (e.g., `await expect(orderList).toContainText('Order #1043')` with a reasonable timeout, or use `page.waitForFunction()` to poll). The issue is not test reliability but inadequate wait-for-state logic.
