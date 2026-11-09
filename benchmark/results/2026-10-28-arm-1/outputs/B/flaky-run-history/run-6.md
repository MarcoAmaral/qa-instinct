# Flaky Test Analysis – Commit c0ffee1

## Summary

**2 flaky tests** | **1 test is deterministically broken** | **1 test is stable**

---

## Flaky Tests

### cart > updates the total when the quantity changes
**Status:** Flaky (3 failures in 10 runs = 30% failure rate)

**Root Cause:**  
Race condition in DOM update detection. The test waits a fixed 300ms then reads the total once. The failure mode is consistent (always receives €29.00 instead of €58.00—exactly half), indicating that sometimes the DOM reflects only one of two quantity increments or the update hasn't rendered before the read.

**Recommendation:**  
Replace `page.waitForTimeout(300)` with a web-first assertion. Wait for the total element to update to the expected value:
```
await expect(totalElement).toContainText('€58.00')
```
This leverages Playwright's built-in retry logic (default 30s timeout) instead of a hardcoded wait.

---

### search > filters results by tag
**Status:** Flaky (4 failures in 10 runs = 40% failure rate)

**Root Cause:**  
Test order dependency and insufficient test isolation. The test seeds with tag "summer", but `tags.spec.ts` renames this tag during its run. With 4 parallel workers, tests can execute in any order. When `tags.spec.ts` runs before or concurrently with `search.spec.ts`, the seeded data is corrupted, causing the filter to return stale data (5 results instead of 3). Proof: the test passes 20/20 when run alone (`--workers=1`).

**Recommendation:**  
Isolate test data:
- Use a unique tag per test run (e.g., `summer-${Date.now()}`) or UUID instead of the seeded "summer".
- Or: make each test use its own database/user isolation context.
- Or: ensure `tags.spec.ts` uses rollback or cleanup to restore seeded state.

Verify the fix by running all suites in parallel (`--workers=4`) 10+ times.

---

### orders > shows the latest order first
**Status:** Flaky (2 failures in 10 runs = 20% failure rate)

**Root Cause:**  
Backend latency / race condition. The order creation succeeds on the client, but GET /orders does not reflect the new order immediately. The test creates an order (new user each run), then reads the list, expecting Order #1043 first. In 2 of 10 full runs (and 3 of 50 repeat runs in isolation), GET /orders returned the previous order list—the new order was inserted 0–2 seconds after the write.

**Recommendation:**  
Replace hardcoded waits or immediate reads with web-first assertions:
```
await expect(page.locator('[data-testid="latest-order"]')).toContainText('Order #1043', { timeout: 5000 })
```
This waits up to 5 seconds (Playwright default retry logic) for the new order to appear. Adjust timeout if the backend SLA exceeds 5s.

Alternatively, if the assertion is already web-first, increase the timeout to 5–10 seconds to account for backend propagation delay.

---

## Deterministically Broken

### profile > saves a new avatar
**Status:** Not flaky—consistently broken (0/10 passes)

**Root Cause:**  
The test always receives `undefined` for the avatar name, never the expected "avatar.png". This is not a race condition; it's a logic bug. Either:
- The avatar upload endpoint is failing silently and not setting the avatar.
- The avatar element is not being populated after upload.
- The test is reading the wrong selector or the avatar data structure has changed.

**Recommendation:**  
1. Debug: Check server logs and the network tab to confirm the upload request succeeds and the avatar is stored.
2. Check the DOM: verify the avatar element exists and inspect its actual content.
3. If the avatar is set in the backend but not reflected in the DOM, check for missing API calls (e.g., a `GET /profile` after upload) or stale component state.
4. This test blocks merges until fixed—do not skip.

---

## Stable

### login > signs in with valid credentials
**Status:** Stable (10/10 passes)

No action required. This test provides high confidence in the auth flow.
