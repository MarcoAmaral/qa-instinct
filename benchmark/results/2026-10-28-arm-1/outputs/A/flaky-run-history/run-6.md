# CI Flakiness Analysis

## Flaky Tests

### 1. **cart > updates the total when the quantity changes**
- **Failure Rate:** 3/10 (30%)
- **Root Cause:** Insufficient wait time. The test uses a fixed 300ms timeout, but the DOM update takes longer in some runs. After clicking "+", the test immediately reads the total, sometimes catching the old value before the increment is applied.
- **Action:** Replace `page.waitForTimeout(300)` with a web-first assertion that waits for the element to contain the expected value (€58.00). Use `expect(locator).toContainText('€58.00')` which polls until the value appears.

### 2. **search > filters results by tag**
- **Failure Rate:** 4/10 (40%)
- **Root Cause:** Test isolation failure. The seeded tag "summer" is being renamed by `tags.spec.ts` during parallel runs. When this test runs after that one, the tag no longer exists or has been renamed, returning unexpected results. Passing 20/20 in isolation confirms this.
- **Action:** Implement test data cleanup/reset. Either: (a) restore the tag to its original state after `tags.spec.ts` completes, (b) use a unique tag per test run (e.g., timestamp-based), or (c) ensure database reset between test files. Consider using a test database transaction that rolls back after each test.

### 3. **orders > shows the latest order first**
- **Failure Rate:** 2/10 (20%) in parallel; 3/50 (6%) in isolation
- **Root Cause:** Eventual consistency issue. There's a 1–2 second delay between order creation and when it appears in the GET /orders response, likely due to async processing or read-replica lag.
- **Action:** Replace the single `textContent()` read with a web-first assertion using `expect(locator).toContainText('Order #1043')`, which will poll until the order appears. Alternatively, explicitly wait for the backend with a polling loop checking GET /orders.

---

## Consistently Failing (Not Flaky)

### **profile > saves a new avatar**
- **Failure Rate:** 10/10 (100%)
- **Root Cause:** Real bug, not flakiness. The avatar is not being saved/returned correctly. The received value is `undefined` instead of `"avatar.png"`.
- **Action:** This is a genuine defect in the application or test setup. Investigate: (a) whether the avatar upload endpoint is working, (b) whether the test is setting up the avatar correctly, (c) whether the response format is correct. This should be treated as a blocking bug, not a flake to tolerate.

---

## Consistently Passing (No Action Needed)

### **login > signs in with valid credentials**
- **Failure Rate:** 0/10 (0%)
- **Status:** Stable; no action needed.
