## Flaky Tests Analysis

**Evidence basis:** Analysis of 10 consecutive CI runs of the same commit (c0ffee1) on main, Playwright 4 workers, retries 0. Data provided; no new runs executed.

---

## Deterministic Failures (Not Flaky)

**profile > saves a new avatar**
- Verdict: Failed 10/10 runs (0% pass rate)
- Failure: Expected "avatar.png", Received undefined
- **Action:** File as `/qa-defect`. This is a deterministic product defect, not a flaky test. Do not quarantine. Investigate why avatar upload always returns undefined.

---

## Flaky Tests (Changing Verdict on Same Code)

### **1. cart > updates the total when the quantity changes**
- Verdict: 7 passes, 3 fails (70% pass rate)
- Failure message: Expected "€58.00", Received "€29.00"
- **Cause class:** Test timing
- **Evidence:** Test uses hard `page.waitForTimeout(300)` before reading total. The UI update may not complete within 300ms, causing intermittent failures where the old total is read.
- **Action:** Replace hard sleep with web-first wait. Change to `page.locator('[data-testid="cart-total"]').toContainText('€58.00')` or equivalent `waitFor()`. Test independently after fix with `--repeat-each=50` to confirm waits are sufficient.
- **Quarantine:** Add `@flaky` tag; if fix is not merged within the sprint, move to `@quarantine`.

### **2. search > filters results by tag**
- Verdict: 6 passes, 4 fails (60% pass rate)
- Failure message: expected 3 results, received 5
- **Cause class:** Test data collision / Order or shared state
- **Evidence:** Test passes 20/20 when run alone (`--workers=1 --repeat-each=20`). Fails in the suite. Uses seeded tag "summer", which `tags.spec.ts` renames during its own run. The shared test data is mutated by another test; order of execution or lack of data isolation causes collision.
- **Action:** Fix test isolation: either (a) use a unique tag per test run instead of a seeded tag, or (b) restore the "summer" tag after `tags.spec.ts` completes. Test independently after fix with full suite run to confirm; do not rely on `--workers=1` alone.
- **Quarantine:** Add `@flaky` tag; if fix is not merged within the sprint, move to `@quarantine`.

### **3. orders > shows the latest order first**
- Verdict: 8 passes, 2 fails (80% pass rate); independent `--repeat-each=50` failed 3/50 (6% rate)
- Failure message: Expected "Order #1043", Received "Order #1042"
- **Cause class:** Product intermittent defect (eventual consistency)
- **Evidence:** Test uses web-first assertions and isolates data (new user per run). Failures correlate with GET /orders returning the list without the new order for up to 2 seconds after creation. The backend API is eventually consistent; the ordering service or cache is not immediately returning fresh data.
- **Action:** 
  - File as `/qa-defect` (product defect: backend eventual consistency lag ≤2s).
  - Add `@flaky` tag to the test.
  - Move to `@quarantine` immediately (this is a product bug, not a test bug).
  - Increase the backend's consistency guarantee or add server-side retries in the test setup (e.g., wait for the order ID to appear in GET /orders before proceeding to the assertion).
  - Do not rely on retries in CI; the defect is real.

---

## Quarantine Ledger Entry (Proposed)

Assuming the team's sprint is 2 weeks (14 days); deadline is 2026-11-11 for all three:

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
|---------|-------------|---------------|-------|----------------|----------|--------|
| cart > updates the total when the quantity changes | Test timing | (fix only) | *assign* | 2026-10-28 | 2026-11-11 | @flaky |
| search > filters results by tag | Test data collision | (fix only) | *assign* | 2026-10-28 | 2026-11-11 | @flaky |
| orders > shows the latest order first | Product intermittent defect | DR-NNN (new) | *assign* | 2026-10-28 | 2026-11-11 | @quarantine |

**Exclude filters:**
- Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs.
- Run a separate non-blocking job with `--grep @quarantine` to track when the defect is resolved.

**Share:** 3 quarantined tests ÷ 120 total tests = 2.5% (below typical escalation thresholds; no escalation needed at this share).

---

## Assumptions

- The suite's 120 tests include the 5 shown; no other tests are assumed flaky.
- The 300ms hard sleep is in the test code, not in a framework configuration.
- "Seeded tag" means the tag is created by the test setup; "renamed" means `tags.spec.ts` overwrites it during its run in the same worker.
- The orders test's backend lag is reproducible and consistent (0–2s), not a transient outage.
