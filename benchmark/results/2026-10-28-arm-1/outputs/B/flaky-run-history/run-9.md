# Flaky Test Analysis Report

## Summary
- **1 test:** Consistently failing (100%) — blocker bug, not flakiness
- **3 tests:** Intermittently failing (20–40%) — root causes identified, actionable fixes
- **1 test:** Consistently passing — no action needed

---

## Failing Tests by Category

### 🚨 Blocker: Consistently Failing (Not Flaky)

**profile > saves a new avatar** — 10/10 failures
- **Root cause:** Feature or test setup is broken, not a race condition
- **Action:** Triage as P0 bug. Verify avatar upload endpoint works, check test data setup (file path, permissions, payload format). Block merge until fixed.

---

### ⏱️ Timing Issue: Fixed Timeout is Too Short

**cart > updates the total when the quantity changes** — 3/10 failures (30% flaky)
- **Failure:** Receives €29.00 instead of €58.00 (half the expected value)
- **Root cause:** `page.waitForTimeout(300)` is a fixed sleep, not an assertion. The quantity update and total recalculation sometimes take >300ms; the test reads the old value before the DOM updates.
- **Action:** Replace the fixed sleep with a web-first assertion:
  ```javascript
  await page.waitForSelector('text=€58.00'); // or use locator().toContainText()
  ```
  This retries until the expected total appears or times out. Assumption: the total field is queryable by text or data-testid.

---

### 🔗 Test Isolation: Shared Data Across Workers

**search > filters results by tag** — 4/10 failures (40% flaky)
- **Failure:** Expects 3 results, receives 5 (extra unfiltered results)
- **Root cause:** Tests run in 4 workers in parallel. The test uses a seeded tag "summer", but `tags.spec.ts` renames it during its own run. When both specs run concurrently, the rename happens mid-test, breaking the filter. Test passes 20/20 alone (1 worker) because no other test touches the data.
- **Action:** Fix test isolation—choose one:
  1. **Preferred:** Use unique tag names per test run (e.g., `summer-${Date.now()}` or per-user tags) instead of seeded names.
  2. **Alternative:** Reset or isolate test data per worker (e.g., separate test database per worker, or cleanup hooks in tags.spec.ts).
  3. **Last resort:** Set `--workers=1` for this test only, but this defeats parallelism.

---

### 🔄 Backend Race Condition: List Not Immediately Consistent

**orders > shows the latest order first** — 2/10 failures (20% flaky)
- **Failure:** GET /orders is missing the newly created order; the test reads Order #1042 instead of #1043
- **Root cause:** Backend race condition. After POST /order succeeds, GET /orders takes up to 2 seconds to return the new order (likely eventual consistency in the database or cache layer). Assumption: orders are created in one service/database and read from another with replication lag.
- **Action:** Choose one:
  1. **Fix the backend:** Ensure POST /order waits for replication/cache write before returning 201, or have GET /orders read from the write path.
  2. **Harden the test:** Replace fixed sleeps with web-first assertions that retry until the order appears:
     ```javascript
     await page.waitForSelector('text=Order #1043', { timeout: 5000 });
     ```
     This lets the test self-heal by retrying the assertion; Playwright will retry every 100ms or so.

---

## Recommendations by Severity

| Priority | Test | Action | Effort |
|----------|------|--------|--------|
| **P0** | profile avatar | Fix feature or test setup | TBD |
| **P1** | cart total | Replace `waitForTimeout()` with assertion | Low |
| **P1** | orders latest | Fix backend consistency OR harden test with retryable assertions | Medium (backend) / Low (test) |
| **P2** | search tag | Decouple test data; use unique tag names per run | Medium |
