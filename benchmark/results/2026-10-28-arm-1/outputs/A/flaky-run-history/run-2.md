## Flaky Test Analysis: e2e Suite (commit c0ffee1)

### 🔴 **Broken Test (Not Flaky)**

**profile > saves a new avatar** — 10/10 failures (100%)

**Why:** The avatar is undefined every run, indicating a deterministic failure, not flakiness. The test or feature is broken.

**What to do:** Fix the underlying issue—check that the avatar file exists, the upload endpoint works, and the test selector is correct. This blocks CI until resolved. Disable the test in CI if necessary to unblock the pipeline, then fix and re-enable.

---

### 🟡 **Flaky Tests**

**cart > updates the total when the quantity changes** — 3/10 failures (30%)

**Why:** The test uses `page.waitForTimeout(300)`, a fixed wait. The €29→€58 discrepancy suggests the quantity increment hasn't been processed by the time `textContent()` reads. Fixed waits are inherently flaky; they assume the application responds within a hardcoded window.

**What to do:** Replace `waitForTimeout(300)` with a web-first assertion: `await expect(totalElement).toContainText('€58.00')`. Playwright will poll until the value appears or timeout, eliminating race conditions.

---

**search > filters results by tag** — 4/10 failures (40%), 0/20 when run in isolation

**Why:** The test relies on a seeded "summer" tag that `tags.spec.ts` renames during its run. When run alone, no other test interferes. When run with others, test execution order varies, and the tag may be renamed before this test runs—yielding stale or extra results (5 vs 3).

**What to do:** Enforce test isolation: either (a) reset the tag to its seeded state after `tags.spec.ts` finishes, or (b) use unique tag names per test run (e.g., `summer-run-${Date.now()}`). If neither is feasible, make the test order explicit (`test.describe.serial()`) for this pair, though that reduces parallelism.

---

**orders > shows the latest order first** — 2/10 failures (20%), 3/50 in isolated repeat-each

**Why:** The GET /orders endpoint has eventual consistency lag—the new order is created but doesn't appear in the list response for up to 2 seconds. Fixed waits or assumptions of immediate consistency fail.

**What to do:** Use web-first assertions with retry: `await expect(page.locator('order-item')).filter({ hasText: 'Order #1043' }).first().toBeVisible()`. Playwright will poll until the order appears. Alternatively, mock the orders endpoint to return immediately, or add a small retry loop in the test that checks for the order every 100ms up to 3s.

---

### ✅ **Stable**

**login > signs in with valid credentials** — 10/10 passes. No action needed.
