## Flaky Test Analysis: Commit c0ffee1, 10 Runs

### Detected Flakes (3 tests; verdict changes on unchanged code)

#### 1. **cart > updates the total when the quantity changes**
- **Failure rate**: 3/10 (30%)
- **Cause class**: Test timing
- **Evidence**: Test clicks "+", waits fixed 300ms with `page.waitForTimeout(300)`, then reads once. In failed runs, the quantity calculation is incomplete (received €29.00 instead of €58.00), indicating the UI update hasn't finished after 300ms. 300ms is a hard sleep, not a web-first assertion.
- **Fix**: Replace `page.waitForTimeout(300)` with a web-first assertion on the total value; e.g., `expect(page.locator('[data-testid="total"]')).toContainText('€58.00')`.

#### 2. **search > filters results by tag**
- **Failure rate**: 4/10 (40%)
- **Cause class**: Order or shared state / test data collision
- **Evidence**: Passes 20/20 when run alone with `--workers=1 --repeat-each=20`. In the suite (4 workers), fails 4/10. Root cause: `tags.spec.ts` renames the seeded tag "summer" during its own run; concurrent test runs (4 workers) collide on shared test data.
- **Fix**: Isolate test data. Use a unique tag per test run (e.g., timestamp-based, or a random suffix) instead of the seeded "summer" tag. Alternatively, ensure tag cleanup between tests, or use a test database transaction that rolls back after each spec.

#### 3. **orders > shows the latest order first**
- **Failure rate**: 2/10 (20%)
- **Cause class**: Product intermittent defect
- **Evidence**: Repeat run of 50 with `--repeat-each=50`, new user per run, web-first assertions → failed 3/50 (6%). In those failures, `GET /orders` returned the list *without* the newly created order for up to 2 seconds after the order was created. The test is correct; the backend has an eventual consistency lag.
- **Action**: File a product defect report with observed frequency (3/50 = 6%). This is a real product issue, not a test issue. Quarantine the test to prevent false negatives, but do not fix the test—fixing would hide the bug.

---

### Deterministic Failure (1 test; always fails on unchanged code)

#### **profile > saves a new avatar**
- **Failure rate**: 10/10 (100%)
- **Cause class**: Not flaky—deterministic failure
- **Recommendation**: File as a product defect or test-setup defect (not a flaky test). The test expects "avatar.png" but receives `undefined`, suggesting either the upload endpoint is broken, the response format is wrong, or the avatar file is missing from the test fixture. Investigate and fix the root cause; do not quarantine.

---

### Healthy Test (1 test)

#### **login > signs in with valid credentials**
- **Failure rate**: 0/10 (0%)
- No action.

---

### Quarantine Ledger (`flaky/ledger.md`)

| Test ID | Cause Class | Product Defect Report | Owner | Quarantined On | Deadline | Status |
|---|---|---|---|---|---|---|
| cart > updates the total when the quantity changes | Test timing | — | *[QA owner]* | 2026-10-28 | 2026-11-11 | Fix test: replace hard sleep with web-first assertion |
| search > filters results by tag | Test data collision | — | *[QA owner]* | 2026-10-28 | 2026-11-11 | Fix test isolation: use unique tag per run or transaction rollback |
| orders > shows the latest order first | Product intermittent defect | DEFECT-NNN | *[Backend owner]* | 2026-10-28 | 2026-11-11 | Backend: investigate eventual consistency lag in POST /orders → GET /orders (3/50 observed) |

**Share of quarantine**: 3 quarantined / 120 tests = 2.5% (below typical escalation threshold; no escalation required).

---

### Test Suite Exclusion

Add to CI `@smoke` and `@regression` jobs:
```
--grep-invert @flaky
```

Keep a separate, non-blocking job to track quarantined tests:
```
--grep @flaky
```
