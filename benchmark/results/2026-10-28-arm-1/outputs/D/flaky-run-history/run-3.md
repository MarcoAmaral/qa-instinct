## Flaky Tests Analysis

### Summary

| Test | Verdict | Cause Class | Action |
|---|---|---|---|
| cart > updates the total when the quantity changes | Flaky (3/10 failures, 30%) | Test timing: hard sleep instead of web-first wait | Fix the test |
| profile > saves a new avatar | Deterministic failure (10/10) | Not flaky; product defect | Report as defect; do not quarantine as flaky |
| search > filters results by tag | Flaky (4/10 failures, 40%) | Test data collision: tags.spec.ts mutates shared seed | Fix test isolation |
| orders > shows the latest order first | Flaky (2/10 failures, 20%); 3/50 alone (6%) | Product intermittent defect: order retrieval race condition | Quarantine; file defect report |
| login > signs in with valid credentials | Not flaky (0/10 failures) | — | No action |

---

### Deterministic Failure (Out of Scope)

**profile > saves a new avatar**
- Fails 100% (10/10 runs on c0ffee1).
- **Root cause:** Expected "avatar.png", received undefined. Not a flake; a deterministic product defect (avatar upload or retrieval is broken).
- **Action:** File as a product defect via `/qa-defect`; do not quarantine as flaky.

---

### Flaky Test 1: cart > updates the total when the quantity changes

- **Runs:** 10 (R1–R10, commit c0ffee1)
- **Failures:** R2, R5, R9 (3/10, 30% failure rate)
- **Failure signature:** Expected "€58.00"; received "€29.00" (half the value; timing-dependent read)
- **Evidence:** Test uses `page.waitForTimeout(300)` (hard sleep), not a web-first assertion
- **Classification:** **Test timing** — missing web-first wait for the UI to update
- **Fix:** Replace the hard sleep with `page.locator('..total..').toContainText('€58.00')` or `waitForTimeout` of the price update selector
- **Quarantine:** No (test code issue, not a hidden product defect)
- **Ledger entry:** Not needed; fix before merge

---

### Flaky Test 2: search > filters results by tag

- **Runs:** 10 (R1–R10, commit c0ffee1)
- **Failures:** R2, R4, R7, R10 (4/10, 40% failure rate)
- **Failure signature:** Expected 3 results; received 5
- **Repeat run (isolated):** `npx playwright test search.spec.ts --workers=1 --repeat-each=20` → 20/20 passed
- **Root cause:** Test uses seeded tag "summer"; tags.spec.ts renames it during the full suite run, polluting the shared seed
- **Classification:** **Order or shared state / Test data collision**
- **Fix:** 
  - Isolate test data: use a unique tag per run (e.g., `summer-${Date.now()}`) or run tags.spec.ts in a separate isolated suite, OR
  - Restore the seed after tags.spec.ts completes (test teardown or database rollback)
- **Quarantine:** No (test isolation issue, not a product defect; fix is in the test)
- **Ledger entry:** Not needed; fix before merge

---

### Flaky Test 3: orders > shows the latest order first

- **Runs:** 10 (R1–R10, commit c0ffee1)
- **Failures:** R3, R8 (2/10, 20% failure rate in the suite)
- **Repeat run (isolated):** `--repeat-each=50` with web-first assertions and a new user per run → 47/50 passed (3 failures, 6% failure rate)
- **Failure signature:** Expected "Order #1043"; received "Order #1042" (missing the latest order)
- **Root cause:** GET /orders endpoint returned the list without the newly created order for up to 2 seconds after order creation (eventual consistency or backend race condition)
- **Classification:** **Product intermittent defect**
- **Action:**
  1. **File a defect report** via `/qa-defect`:
     - Severity: medium (creates a stale view; user sees old data)
     - Symptom: 3 failures in 50 isolated runs (6% observed frequency on unchanged code)
     - Root: Order creation and retrieval have a race; GET /orders does not immediately reflect the created order
     - Environment: Assumed to occur in test and possibly staging/production
  2. **Quarantine** the test with tag `@quarantine` until fixed:
     - **Ledger entry (add to `flaky/ledger.md`)**:
       | Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
       |---|---|---|---|---|---|---|
       | orders > shows the latest order first | Product intermittent defect (order retrieval race) | (defect ID, e.g., DR-001) | (assign owner) | 2026-10-28 | 2026-11-11 | Quarantined |
     - **Deadline assumption:** 14 days (one 2-week sprint) from quarantine date
  3. **Exclusion:** Add `--grep-invert @quarantine` to `@smoke` and `@regression` CI jobs; run a separate non-blocking job with `@quarantine` so fixes are visible

---

### Next Steps

1. **cart** test: Apply a web-first wait; remove the hard sleep.
2. **search** test: Fix data isolation (unique tag per run or restore seed).
3. **profile** test (deterministic): File a product defect; do not quarantine.
4. **orders** test (flaky): File a product defect; quarantine with ledger entry and deadline; backend team owns the race-condition fix.
5. **login** test: No action; passing.
