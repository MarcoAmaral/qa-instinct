## Deterministic Failures

| Test | Verdict | Issue |
| --- | --- | --- |
| profile > saves a new avatar | **Always fails (10/10)** | Not flaky. Deterministic defect: API or implementation broken. Expected "avatar.png", received undefined. Report as product defect (defect type: functionality). Not suitable for quarantine—fix the issue. |

---

## Flaky Tests: Analysis & Actions

### 1. cart > updates the total when the quantity changes
- **Observed**: 7 pass, 3 fail across 10 runs (30% failure rate)  
- **Cause class**: **Test timing**  
- **Evidence**: The test uses `page.waitForTimeout(300)` (hard sleep) instead of a web-first assertion. Receives €29.00 when €58.00 is expected—half the price. The fixed 300ms timeout is a race condition; the UI update may take longer, especially under load or with 4 parallel workers.  
- **Recommendation**:  
  - Replace `page.waitForTimeout(300)` with a web-first assertion that waits for the total to update: `await expect(totalLocator).toContainText('€58.00')` (built-in retry and timeout).  
  - Add the `@flaky` tag to the spec.  
  - Once fixed, run `npx playwright test cart.spec.ts --workers=4 --repeat-each=20` and confirm all 20 pass.  
  - If it passes, remove the tag and mark resolved.

---

### 2. search > filters results by tag
- **Observed**: 7 pass, 3 fail in the suite (30% failure rate); **0 failures in 20 repeat runs alone** (`--workers=1 --repeat-each=20`)  
- **Cause class**: **Order or shared state**  
- **Evidence**: Passes consistently in isolation but fails in the suite. The test uses a seeded tag "summer" which `tags.spec.ts` renames during its own run. The suite's parallel execution (4 workers) means this test can run while `tags.spec.ts` modifies shared data, causing the tag to be missing or renamed by the time the search runs.  
- **Recommendation**:  
  - Fix the test data isolation: either have each test create its own tag (e.g., `summer-<uuid>`) or ensure `tags.spec.ts` cleans up after itself and does not rename seeded tags.  
  - Alternatively, isolate with `beforeEach` / `afterEach` to guarantee the "summer" tag exists with the expected name at test start.  
  - Add the `@flaky` tag to the spec.  
  - Once fixed, run `npx playwright test --workers=4 --repeat-each=20` (full suite) and confirm all 20 passes.  
  - Remove the tag and mark resolved.

---

### 3. orders > shows the latest order first
- **Observed**: 8 pass, 2 fail in suite (20% failure rate); **3 failures in 50 repeat runs alone** with web-first assertions and fresh user per run (6% failure rate)  
- **Cause class**: **Product intermittent defect**  
- **Evidence**: The test passes in isolation most of the time but fails intermittently even with correct waits (web-first assertions) and isolated data (new user each run). The failure is: expected "Order #1043", received "Order #1042". Root cause identified: GET /orders returns the list without the newly created order for up to 2 seconds after creation. This is a backend eventual consistency or race condition, not a test defect.  
- **Recommendation**:  
  - **File a product defect** (use `/qa-defect`) with severity = Medium, title: "GET /orders does not include newly created order for up to 2 seconds" and evidence from the repeat run (3 failures in 50 runs, ~6% rate).  
  - **Quarantine the test** with `@quarantine` tag. Add a row to `flaky/ledger.md`:  
    | orders > shows the latest order first | Product intermittent defect | [defect report ID] | [owner] | [date] | [sprint deadline] | Quarantined |  
  - Run a non-blocking CI job with `@quarantine` tests to verify when the backend fix lands and the defect is closed.  
  - Upon backend fix confirmation, run `npx playwright test orders.spec.ts --workers=4 --repeat-each=50` to confirm 0 failures; then remove both tags and mark `retired (fixed)` in the ledger.

---

## Summary Table

| Test | Runs | Failures | Class | Action |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10 | 10 (100%) | **Deterministic** | Report as product defect, do not quarantine |
| cart > updates the total when the quantity changes | 10 | 3 (30%) | Test timing | Fix hard sleep → web-first assert, tag `@flaky`, repeat-test, resolve |
| search > filters results by tag | 10 suite / 20 alone | 3 suite (30%) / 0 alone | Order/shared state | Fix test data isolation, tag `@flaky`, repeat-test, resolve |
| orders > shows the latest order first | 10 suite / 50 alone | 2 suite (20%) / 3 alone (6%) | Product intermittent | File defect, tag `@quarantine`, add to ledger, await backend fix |
| login > signs in with valid credentials | 10 | 0 (0%) | — | Not flaky, no action |

---

## Notes on Evidence

- **CI history (10 runs)**: Read from provided table.  
- **search > filters results by tag**: Repeat run data from user input (`--workers=1 --repeat-each=20`, 20/20 pass).  
- **orders > shows the latest order first**: Repeat run data from user input (`--repeat-each=50`, 3/50 fail; GET /orders observed delay up to 2s).  
- **Assumption**: The flaky status of the first two can be confirmed only after the test fixes are applied and a 20–50 run repeat is executed in the suite.
