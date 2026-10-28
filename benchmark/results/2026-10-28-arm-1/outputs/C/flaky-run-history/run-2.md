# Flaky Tests Analysis

## Summary

Of 5 tests, 2 are consistently broken, 2 are flaky due to timing issues, and 1 is flaky due to test isolation.

---

## cart > updates the total when the quantity changes

**Flakiness:** 30% (3 failures: R2, R5, R9)

**Root cause:** Hard-coded 300ms timeout is not long enough. The DOM update can take longer than 300ms, especially under load or with 4 parallel workers.

**Action:** Replace `page.waitForTimeout(300)` with a proper wait condition. Use `page.waitForFunction(() => document.querySelector('[data-testid="total"]').textContent === '€58.00')` or wait for the quantity input to reflect the change first, then assert.

**Priority:** High — affects purchase flow.

---

## profile > saves a new avatar

**Flakiness:** 0% (10/10 failures — this is broken, not flaky)

**Root cause:** The avatar file is not being saved or returned from the endpoint. The test expects `"avatar.png"` but receives `undefined`, which suggests either the file upload failed silently, the field is missing from the response, or there's an auth issue specific to the avatar endpoint.

**Action:** 
1. Check if the avatar upload endpoint exists and is mocked correctly in the test setup.
2. Verify the test has the required permissions to upload.
3. Check if the response shape includes the avatar field; if not, update the test assertion.
4. If the upload genuinely fails, add logging to see why.

**Priority:** Critical — the feature does not work.

---

## search > filters results by tag

**Flakiness:** 40% (4 failures: R2, R4, R7, R10)

**Root cause:** Test isolation failure. The test seeds a tag named "summer", but `tags.spec.ts` runs in parallel (4 workers) and renames or deletes the "summer" tag during its own run. When this test runs concurrently with tags.spec.ts, the tag does not exist or has been modified.

**Action:** 
1. Give each test a unique tag name (e.g., use a UUID or test-specific suffix like `"summer-search-test"`).
2. Alternatively, ensure all tag mutations in `tags.spec.ts` use a different tag or clean up after themselves.
3. Do not rely on seeded data shared across test files when tests run in parallel.

**Priority:** High — tests will keep failing unpredictably as more tests are added.

---

## orders > shows the latest order first

**Flakiness:** 20% (2 failures: R3, R8)

**Root cause:** Eventual consistency. The order endpoint is slow to include the newly created order—up to 2 seconds after creation in failed runs. A fixed wait of 300ms (assumed from the cart test pattern) is insufficient. Isolated runs with web-first assertions and a new user per run pass reliably, suggesting the issue is either async processing in the backend or state carryover from prior test runs in parallel.

**Action:**
1. Use web-first assertions with a proper timeout (Playwright's `expect(locator).toContainText()` with a default 30s timeout).
2. Instead of `waitForTimeout()`, use `page.waitForURL()` or `page.waitForFunction()` to poll until the order appears.
3. If the delay is a backend sync issue (e.g., asynchronous log writes), add an explicit wait for the order to appear with a 5-10 second timeout.

**Priority:** Medium — only 2 of 10 runs fail, but it affects the order creation flow.

---

## login > signs in with valid credentials

**Status:** Stable — 10/10 passes. No action needed.

---

## Recommendations

1. **Eliminate hard-coded timeouts:** Replace all `page.waitForTimeout()` with conditional waits (`waitForFunction`, `waitForSelector`, or web-first assertions).
2. **Fix test isolation:** Ensure each test uses unique seeds or cleans up side effects.
3. **Debug the broken avatar test first:** It blocks the profile feature and does not require flakiness investigation.
4. **Add a retry or extended timeout for order tests:** The 20% flakiness is acceptable if backed by a reliable retry strategy or a longer default timeout.
