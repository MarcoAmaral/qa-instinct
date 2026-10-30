# Flaky Test Analysis: c0ffee1 CI Runs

## Summary
- **1 consistently failing test** (not flaky, needs a bug fix)
- **3 genuinely flaky tests** (intermittent failures due to test/system issues)
- **1 reliable test** (no action needed)

---

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Flakiness:** 3 failures in 10 runs (30%)

**Root Cause:** Hard-coded 300ms timeout is insufficient. The test clicks "+", waits with `page.waitForTimeout(300)`, then immediately checks the total. The DOM update sometimes takes longer than 300ms.

**Recommendation:** Replace the hard-coded timeout with a web-first assertion (e.g., `expect(locator).toContainText('€58.00')`), which includes automatic retry logic with exponential backoff. Playwright will retry for up to 30 seconds by default.

---

### 2. search > filters results by tag
**Flakiness:** 4 failures in 10 runs (40%); passes 20/20 when isolated

**Root Cause:** Test isolation failure. The test relies on a seeded tag "summer", but `tags.spec.ts` renames this tag during its own run. When the suites run concurrently (4 workers), the tag gets modified mid-test, causing the search to return unfiltered results (5 instead of 3).

**Recommendation:** Either:
- Modify `tags.spec.ts` to not mutate the seeded "summer" tag, or
- Use a unique tag name per test run (e.g., `summer-${Date.now()}`) to avoid collisions, or
- Add a cleanup hook to restore the "summer" tag to its original state after `tags.spec.ts` completes

---

### 3. orders > shows the latest order first
**Flakiness:** 2 failures in 10 runs (20%); 3 failures in 50 isolated runs (6%)

**Root Cause:** Backend race condition. The order creation API returns success, but the order is not immediately available in the GET /orders response for up to 2 seconds. Even with web-first assertions, the list endpoint hasn't returned the new order yet.

**Recommendation:** Add retry logic to the assertion:
```javascript
await expect(async () => {
  const response = await page.request.get('/orders');
  const orders = await response.json();
  expect(orders[0].id).toBe('Order #1043');
}).toPass({ timeout: 5000 });
```
Alternatively, fix the backend to ensure orders are immediately queryable after creation (check for async indexing delays or cache invalidation issues).

---

## Consistently Failing Test

### profile > saves a new avatar
**Flakiness:** 0 failures in 10 runs (100% failure rate—not flaky)

**Root Cause:** Real bug. The test expects `"avatar.png"` but receives `undefined`, consistently. The avatar is either not being saved to the server, not being returned in the API response, or not being set in the DOM.

**Recommendation:** Debug the avatar upload/save flow:
- Check if the file upload is actually reaching the server
- Verify the backend saves and returns the avatar filename
- Confirm the response is being correctly parsed and rendered in the DOM
- This is a blocker and should be fixed before considering it a valid test.

---

## Reliable Test

**login > signs in with valid credentials** — 10/10 passes. No action needed.
