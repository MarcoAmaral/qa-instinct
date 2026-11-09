## Flaky Test Analysis & Recommendations

### Summary
- **3 flaky tests** requiring fixes (cart, search, orders)
- **1 consistently failing test** indicating a real bug, not flakiness (profile)
- **1 stable test** (login)

---

### Flaky Tests

#### cart > updates the total when the quantity changes
**Flakiness:** 30% (3 failures in 10 runs)

**Root cause:** Insufficient wait time. The test uses a static 300ms sleep before reading the total, but the DOM update occasionally takes longer than 300ms under CI load, causing a race condition.

**Recommended fix:**
- Replace `page.waitForTimeout(300)` with a web-first assertion
- Example: `await expect(page.locator('[data-testid="total"]')).toContainText('€58.00')`
- This waits up to the default timeout (30s) for the expected value, eliminating the race

---

#### search > filters results by tag
**Flakiness:** 40% (4 failures in 10 runs)

**Root cause:** Test isolation violation. The `tags.spec.ts` file renames the "summer" tag during its own test run. When `search.spec.ts` runs in parallel (4 workers), it occasionally sees a stale or renamed tag, returning 5 results instead of the expected 3. The test passes 20/20 in isolation because `tags.spec.ts` doesn't run.

**Recommended fix (choose one):**
1. **Preferred — Add test data isolation:** Reset the "summer" tag to a known state before the search test runs (e.g., in `beforeEach` or via test fixtures)
2. **Alternative — Use unique tag names:** Generate a unique tag name per test run to prevent conflicts with other tests
3. **Last resort — Enforce test order:** Configure Playwright to run `tags.spec.ts` before `search.spec.ts`, with explicit cleanup after `tags.spec.ts`

---

#### orders > shows the latest order first
**Flakiness:** 20% (2 failures in 10 runs); 6% in isolated repeats (3 failures in 50 runs with new user each time)

**Root cause:** API eventual consistency. The order creation succeeds, but GET `/orders` doesn't immediately reflect the new order—it can take up to 2 seconds to appear. The test reads the order list once without waiting for the new order to be present.

**Recommended fix:**
- Replace single read with a polled wait for the new order
- Example: `await expect(page.locator('[data-testid="orders-list"]')).toContainText('Order #1043')`
- Or manually poll: `await page.waitForFunction(() => fetch('/api/orders').then(r => r.json()).then(orders => orders[0].id === 1043))`
- Consider a small delay after order creation before checking, or add a `waitForResponse` hook to confirm the order endpoint reflects the new order

---

### Consistently Failing Test

#### profile > saves a new avatar
**Failure rate:** 100% (10 failures in 10 runs)

**Status:** This is **not a flaky test**—it's a **real bug**. Every run fails with the same error: avatar is `undefined` instead of `"avatar.png"`.

**Recommended action:**
- Debug the avatar save/upload flow in the profile feature
- Check: file upload handler, backend storage, and the GET endpoint that returns the avatar
- This appears to be a regression or incomplete feature, not a timing issue
- Treat as a blocking bug, not a test stability issue

---

### Stable Test

#### login > signs in with valid credentials
**Status:** Passing 10/10 runs — no action needed.
