## Detected Tests

### Flaky (variable verdict across 10 runs)
- cart > updates the total when the quantity changes: 7P/3F
- search > filters results by tag: 7P/3F  
- orders > shows the latest order first: 8P/2F

### Deterministic Failure (fails every run)
- profile > saves a new avatar: 0P/10F

### Passing (all runs)
- login > signs in with valid credentials: 10P/0F

---

## Classification

### Deterministic Failures → Report as Product Defect

**profile > saves a new avatar**
- **Verdict**: 10 consecutive failures (deterministic, not flaky)
- **Failure**: Expected "avatar.png", received undefined
- **Class**: Deterministic defect
- **Action**: File `/qa-defect` report for the avatar upload feature. This is a product bug, not a test issue. Do not quarantine.

---

### Flaky Tests

#### 1. cart > updates the total when the quantity changes
- **Verdict**: 3 failures in 10 runs (30% fail rate)
- **Failure**: Expected "€58.00", received "€29.00" (half the expected amount; inconsistent)
- **Cause class**: Test timing
- **Evidence**: Test clicks "+", then uses `page.waitForTimeout(300)`, then reads total once. The hard-coded 300ms sleep is insufficient on some runs; the DOM re-render or price calculation finishes after this timeout.
- **Action**: Fix the test by replacing the sleep with a web-first assertion: `expect(page.locator('selector-for-total')).toContainText('€58.00')`. Then verify with `npx playwright test cart.spec.ts --repeat-each=50 --workers=4`.
- **Quarantine**: Tag `@flaky`. If not fixed within 2 weeks (deadline **2026-11-11**), escalate to `@quarantine`.

---

#### 2. search > filters results by tag
- **Verdict**: 3 failures in suite (30% fail rate); **0 failures in isolation** (passed 20/20 with `--workers=1 --repeat-each=20`)
- **Failure**: Expected 3 results, received 5
- **Cause class**: Test isolation / shared state collision
- **Evidence**: Passes consistently in isolation. Uses seeded tag "summer", which tags.spec.ts renames during its own run. Fails only in the full suite, indicating tags.spec.ts mutates shared test data that this test depends on.
- **Action**: Fix test isolation. Ensure tags.spec.ts does not mutate the "summer" tag or add setup/teardown to isolate per-test data. Verify with `npx playwright test --workers=4 --repeat-each=10`.
- **Quarantine**: Tag `@flaky`. If not fixed within 2 weeks (deadline **2026-11-11**), escalate to `@quarantine`.

---

#### 3. orders > shows the latest order first
- **Verdict**: 2 failures in suite (20% fail rate); 3 failures in isolation (6% fail rate: 3 of 50 runs with `--repeat-each=50`, new user per run)
- **Failure**: Expected "Order #1043", received "Order #1042" (new order not in list)
- **Cause class**: Product intermittent defect (backend eventual consistency race)
- **Evidence**: Test runs in isolation with correct web-first assertions and isolated data; still fails 3/50 times. Root cause: GET /orders returns the list **without the newly created order for 0–2 seconds** after POST /orders succeeds. This is not a test timing issue; the backend has a real eventual consistency bug.
- **Action**: File `/qa-defect` report for the backend team. Report: POST /orders returns 201, but GET /orders omits the new order for up to 2 seconds. Frequency: 6% (3 of 50 runs under isolated conditions). Likely impact: production users see incomplete order lists briefly after placing an order. Do not adjust the test or add retries; this masks a real defect.
- **Quarantine**: Tag `@quarantine` (with defect report link). Owner: Backend. Deadline: **2026-11-11**. Keep this test out of CI until the backend race is fixed.

---

## Proposed Quarantine Ledger

| Test ID | Cause Class | Defect Report | Owner | Quarantined | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| search > filters results by tag | Test isolation | — | QA / Test Author | 2026-10-28 | 2026-11-11 | Pending test fix |
| orders > shows the latest order first | Product eventual consistency | DR-??? | Backend | 2026-10-28 | 2026-11-11 | Pending backend fix |

**Quarantine share**: 2 of 120 tests = 1.67% (proceed; well below typical escalation thresholds).

---

## Summary for the Team

| Test | Class | Action |
| --- | --- | --- |
| profile > avatar | Deterministic failure | File defect report; not flaky, do not quarantine |
| cart > total | Test timing | Fix: replace `waitForTimeout(300)` with web-first assertion; verify with repeat run |
| search > tag | Test isolation | Fix: isolate test data so tags.spec.ts does not mutate the "summer" tag; verify in full suite |
| orders > latest | Product race | File backend defect report (P1); quarantine test; backend team to fix eventual consistency lag |

**Assumption**: Sprint period = 2 weeks (deadline 2026-11-11). Escalation threshold for quarantine share not accessible; load `testing-guidelines` rule to confirm.
