## Detection

Evidence from 10 CI runs of commit c0ffee1:

| Test | Verdict Pattern | Failures | Rate | Classification |
|------|---|---|---|---|
| **cart > updates the total when the quantity changes** | P F P P F P P P F P | Runs 2, 5, 9 | 30% | **Flaky: Test timing** |
| **profile > saves a new avatar** | F F F F F F F F F F | All 10 | 100% | **Deterministic failure** (not flaky) |
| **search > filters results by tag** | P F P F P P F P P F | Runs 2, 4, 7, 10 | 40% | **Flaky: Shared state / test order** |
| **orders > shows the latest order first** | P P F P P P P F P P | Runs 3, 8 | 20% | **Flaky: Product intermittent** |
| login > signs in with valid credentials | P P P P P P P P P P | — | 0% | Stable ✓ |

---

## Flaky Tests: Classification & Root Cause

### 1. cart > updates the total when the quantity changes
**Cause: Test timing (hard sleep, missing web-first wait)**

The test clicks "+", sleeps 300ms with `page.waitForTimeout(300)`, then reads `textContent()` once and compares. When the assertion fails, the expected total is €58.00 but received is €29.00—the UI has not yet reflected the quantity increase. The fixed timeout is insufficient for the component to update; 30% of runs fail because the UI update races past the sleep.

**Action:** Fix the test, not the product.
- Replace `page.waitForTimeout(300)` with a web-first wait: `await page.waitForSelector('.total:has-text("€58.00")')` or `await expect(page.locator('.total')).toContainText('€58.00')`.
- Remove the hard sleep entirely.

---

### 2. search > filters results by tag
**Cause: Shared state / test isolation (data collision across suite runs)**

The test passed 20 of 20 in isolation (`npx playwright test search.spec.ts --workers=1 --repeat-each=20`), but fails 40% of the time in the full suite. The test uses a seeded tag "summer"; the failure data shows it expects 3 results but receives 5, suggesting the tag was renamed by `tags.spec.ts` during a parallel or earlier test run, polluting the search results.

**Action:** Fix the test's isolation, not the product.
- Isolate test data: create a unique tag per test run (e.g., UUID or timestamp) instead of seeding "summer" globally.
- Or: ensure `tags.spec.ts` does not rename seeded tags, or cleans them up after its run.
- Verify test order independence by running the suite with `--shuffle-order`.

---

### 3. orders > shows the latest order first
**Cause: Product intermittent defect (eventual consistency)**

The test is correctly written: it uses web-first assertions and creates a new user for every run. In a `--repeat-each=50` run alone, it still failed 3 of 50 (6% failure rate). In those failures, the GET /orders endpoint returned without the newly created order for up to 2 seconds after the order creation endpoint returned. This is a real backend race condition: the order creation endpoint succeeds before the order propagates to the orders list.

**Action:** File a product defect and quarantine the test.
- **Defect report** (use `/qa-defect`): The order creation endpoint returns success before GET /orders includes the new order; observed 3 failures in 50 runs (6% frequency). Backend eventual consistency issue.
- **Quarantine** (below): Add `@flaky @quarantine` tags, set owner, and deadline.

---

## Deterministic Failure (Not Flaky)

### profile > saves a new avatar
**100% failure rate across all 10 runs.**

Expected "avatar.png" but received `undefined`. This is not flaky; it is a deterministic defect. The avatar upload or storage is broken, not intermittent. 

**Action:** Do not quarantine. File a defect and fix the product or test logic immediately.

---

## Quarantine Ledger Proposal

Assumptions:
- Sprint length = 2 weeks (14 days); quarantine deadline = quarantine date + 14 days.
- Quarantine date: today (2026-10-28).
- Total test count in suite: 120 (given); quarantined would be 1 test → 1/120 = 0.8% (below escalation threshold, assumed to be 5%).
- No escalation required.

| Test ID | Cause Class | Product Defect | Owner | Quarantined | Deadline | Next Step |
|---------|---|---|---|---|---|---|
| orders > shows the latest order first | Product intermittent (eventual consistency) | *To be filed via `/qa-defect`* | *To be assigned* | 2026-10-28 | 2026-11-11 | Fix backend race in order creation → GET /orders propagation; retest with `--repeat-each=50`. Remove `@quarantine` when fixed and green-red proof obtained. |

---

## Summary & Next Steps

| Category | Test | Action Owner | Action |
|---|---|---|---|
| **Fix the test** | cart > updates the total | Dev / QA | Replace hard sleep with web-first wait. Re-run 50 times to confirm stable. |
| **Fix the test** | search > filters results by tag | Dev / QA | Isolate test data (unique tags per run) or fix `tags.spec.ts` cleanup. Re-run suite 10×. |
| **Fix the product** | orders > shows the latest order first | Backend / QA | File defect (eventual consistency in order creation). Quarantine test. Fix backend. Confirm fix with `--repeat-each=50`. |
| **Fix the product** | profile > saves a new avatar | Backend / QA | File defect (deterministic failure). Debug avatar upload / storage logic. Do not quarantine. |
| **No action** | login > signs in with valid credentials | — | Stable; no changes needed. |
