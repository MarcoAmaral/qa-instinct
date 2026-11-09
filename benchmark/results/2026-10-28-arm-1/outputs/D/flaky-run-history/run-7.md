## Flaky Tests (detected from 10-run CI history)

### 1. **cart > updates the total when the quantity changes**
- **Verdict:** Flaky (7 passes, 3 failures; 30% failure rate)
- **Cause class:** Test timing
- **Evidence:** Test uses a hard sleep (`page.waitForTimeout(300)`) instead of waiting for DOM update. Expected "€58.00", Received "€29.00" suggests the price calculation hasn't completed in 300ms. This is a missing web-first assertion.
- **Action:** Fix the test. Replace the hard sleep with a wait-for-selector or web-first assertion on the updated total value. No quarantine needed once fixed.

### 2. **search > filters results by tag**
- **Verdict:** Flaky (7 passes, 3 failures; 30% failure rate)
- **Cause class:** Test order or shared state (data pollution)
- **Evidence:** Passed 20 of 20 when run alone (`npx playwright test search.spec.ts --workers=1 --repeat-each=20`). Fails in suite because `tags.spec.ts` renames the seeded "summer" tag during its execution, polluting the shared test data. The test has no isolation.
- **Action:** Fix test isolation. Ensure each test gets fresh seed data or scopes tag names per test. No quarantine needed once fixed.

### 3. **orders > shows the latest order first**
- **Verdict:** Flaky (8 passes, 2 failures; 20% failure rate in suite, 6% in isolation)
- **Cause class:** Product intermittent defect (eventual consistency race)
- **Evidence:** Test is correctly isolated (new user per run, web-first assertions). Failed 3 of 50 in a `--repeat-each=50` solo run. Root cause: GET /orders returns the list **without** the new order for up to 2 seconds after creation. This is a backend consistency guarantee, not a test bug.
- **Action:** File a defect report against the product (order creation is not immediately visible). Quarantine `@flaky @quarantine` to unblock CI. Do not hide with retries; the product needs a fix.

---

## Deterministic Failure (not flaky)

### 4. **profile > saves a new avatar**
- **Verdict:** Deterministic failure (0 passes, 10 failures in 10 runs)
- **Evidence:** Expected "avatar.png", Received undefined in every run. Not a race or timing issue.
- **Action:** File a defect report against the product. Avatar upload or retrieval is broken. Do not quarantine; this is not flaky, it is a bug.

---

## Non-flaky (control)

### 5. **login > signs in with valid credentials**
- **Verdict:** Stable (10 passes, 0 failures). Not flaky.

---

## Quarantine Ledger (`flaky/ledger.md`)

**Assumptions stated:** Testing-guidelines rule period assumed as 2 sprints (14 days). Escalation threshold assumed at 10% of 120 tests (12 tests). Current share: 2 quarantined ÷ 120 = 1.7%; below threshold, no escalation needed.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| search > filters results by tag | Order/shared state | — | *[assign]* | 2026-10-28 | 2026-11-11 | New; fix test isolation |
| orders > shows the latest order first | Product defect | *[create]* | *[assign product]* | 2026-10-28 | 2026-11-11 | New; backend eventual-consistency fix |

**Exclusion:** Add `--grep-invert @quarantine` to smoke and regression jobs. Run quarantined tests in a separate, non-blocking job to surface fixes.

**Note:** cart and search are test fixes with no need to quarantine (they unblock once the test code is corrected). Profile is a deterministic product defect, not flaky. Ledger captures only the product-level defect (orders) and the data-isolation fix (search, which blocks others if it pollutes shared state).
