# Flaky Test Analysis — e2e Suite (120 tests, commit c0ffee1)

**Scope & Assumptions:**
- Analysis based on 10 runs with consistent environment (Playwright, 4 workers, no retries).
- Failure messages are consistent within each test, indicating deterministic root causes rather than transient infra issues.
- Seeded test data exists and is reset between runs; backend and frontend are functioning at baseline.

---

## Summary

| Test | Status | Failure Rate | Root Cause | Severity |
| --- | --- | --- | --- | --- |
| cart > updates the total | **FLAKY** | 30% | Insufficient wait time for async quantity update | High |
| profile > saves a new avatar | **BROKEN** (not flaky) | 100% | Consistent failure; likely product/implementation bug | Critical |
| search > filters results by tag | **FLAKY** | 40% | Test isolation failure; tag state mutated by concurrent `tags.spec.ts` | High |
| orders > shows the latest order | **FLAKY** | 20% | Backend race condition; ~2s eventual consistency delay | Medium |
| login > signs in with valid credentials | ✓ STABLE | 0% | No action needed | — |

---

## Detailed Findings & Recommendations

### 1. **cart > updates the total when the quantity changes** — FLAKY (30%)

**Root Cause:**  
Race condition between UI state update and test assertion. The test waits a hardcoded 300ms after clicking "+", but the DOM update and recalculation take longer in some runs. The discrepancy (€29.00 vs €58.00) suggests the quantity increased but the total calculation didn't execute.

**Recommendation:**  
Replace `page.waitForTimeout(300)` with a web-first assertion:
```javascript
await expect(page.locator('[data-testid="cart-total"]')).toContainText('€58.00');
```
This waits up to the default timeout (30s) for the element to reach the expected state, eliminating the arbitrary delay. If the test still flakes, the bug is in the component's recalculation logic.

---

### 2. **profile > saves a new avatar** — BROKEN (100% failure rate)

**Root Cause:**  
This is not flakiness—it's a consistent failure. Either:
- The avatar upload handler doesn't save the file correctly, or
- The DOM element/value is being read before it's populated, or  
- The test setup (user state, permissions) is incorrect.

**Recommendation:**  
1. **Do not treat as flaky.** This blocks the feature.
2. Verify the test locally in isolation: `npx playwright test profile.spec.ts --workers=1` and inspect network traffic for the upload request.
3. If the upload fails server-side, file a bug against the avatar upload endpoint.
4. If the upload succeeds but the UI doesn't reflect it, file a bug against the profile component.
5. Once fixed, add this test to a smoke suite (run every deploy) to catch regressions immediately.

---

### 3. **search > filters results by tag** — FLAKY (40%, but test-order dependent)

**Root Cause:**  
Test isolation failure due to shared state. The test filters by the seeded tag "summer," but `tags.spec.ts` renames this tag during parallel execution. The 4-worker pool can run both specs simultaneously, causing the rename to delete or modify the tag mid-search, inflating result counts.

**Recommendation:**  
1. **Isolate test data per run.** Modify the test setup to create a unique tag name per run (e.g., `summer-${Date.now()}`) rather than relying on seeded data.
2. Alternatively, ensure `tags.spec.ts` works only with tags it creates, not shared fixtures.
3. If seeded data is required, use test-level database transactions that roll back after each run (if your DB supports it), or reset the tag between specs.
4. Verify the fix: re-run the suite and confirm search.spec.ts passes consistently with `--workers=4`.

---

### 4. **orders > shows the latest order first** — FLAKY (20%, ~6% in extended run)

**Root Cause:**  
Backend eventual consistency issue. After creating an order, GET /orders doesn't immediately return it (latency up to 2 seconds). This is not a test bug; it's a product-level consistency SLA issue.

**Recommendation:**  
1. **Use web-first assertions with polling.** Replace the single `textContent()` read with:
   ```javascript
   await expect(page.locator('[data-testid="order-list-item"]:first')).toContainText('Order #1043');
   ```
   This polls the DOM for up to 30s, giving the backend time to replicate the data.
2. **Investigate backend.** If GET /orders routinely lags 2+ seconds after INSERT, file a performance bug. Typical SLA: new orders appear within 100ms. Diagnose: Is the create endpoint async? Is there a write-read consistency issue in the database?
3. **If high latency is by design,** document it in the API and accept the test flake as expected (add retry logic to Playwright config for this spec only).

---

## Triage Priorities

1. **Immediate:** Fix `profile > saves a new avatar` (100% failure blocks feature).
2. **High:** Resolve `search > filters results by tag` (test isolation is foundational; 40% flake blocks CI confidence).
3. **High:** Replace hardcoded waits in `cart > updates the total` with web-first assertions (30% flake).
4. **Medium:** Investigate backend latency in `orders > shows the latest order` and apply polling assertions (6–20% flake is acceptable only if documented).
