# Flaky test analysis: e2e suite, commit c0ffee1, main

**Source.** Ten CI runs of the same commit, Playwright, 4 workers, retries 0, and the repeat runs quoted in the request. Everything below was read from that history; nothing was run in this session. Where I name a repeat run, it is the one the team already did.

**Assumptions.**
- The 115 tests not listed passed all 10 runs. The suite size of 120 comes from the request, not from `npx playwright test --list`; confirm the count before computing the share for real.
- Sprints are two weeks, so the rule's "2 sprints" is 4 weeks: quarantined 2026-10-26, deadline 2026-11-23.
- Owners are the feature-area owners (cart, search, orders, profile). Names are placeholders until the team fills them in; a ledger row without a real owner is not a quarantine.
- No traces or JUnit artefacts were kept for the failed CI runs (retries were 0, so there is no runner `flaky` outcome either).

## Verdict per test

| Test | Runs | Failures | Verdict |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 10 | 3 | Flaky |
| search > filters results by tag | 10 | 4 | Flaky |
| orders > shows the latest order first | 10 | 2 | Flaky |
| profile > saves a new avatar | 10 | 10 | Not flaky: deterministic failure |
| login > signs in with valid credentials | 10 | 0 | Not flaky: 0 failures in 10 runs (a bound, not a proof) |

## Flaky tests: cause and action

### 1. search > filters results by tag

- **Cause class:** order or shared state (cross-spec data collision under parallel workers).
- **Evidence:** 4 failures in 10 CI runs with 4 workers; 0 failures in 20 runs alone with `--workers=1`. The test asserts on the seeded tag "summer", which `tags.spec.ts` renames during its own run. When the two specs overlap, the filter matches a different set and returns 5 results instead of 3.
- **Action:** fix the test isolation, not the product. Each spec creates and owns its tag: `search.spec.ts` creates a tag with a unique name in `beforeEach` and filters on that; `tags.spec.ts` renames a tag it created itself, never the seed. Neither spec should touch shared seed data.
- **Exit:** on the fix commit, run the whole suite with 4 workers, `--repeat-each=20`, and separately run `search.spec.ts` and `tags.spec.ts` together with `--workers=2 --repeat-each=50`; record the command and output. Red-green: break the tag filter (or point the test at a tag with 5 items) and confirm the test fails.

### 2. orders > shows the latest order first

- **Cause class:** product intermittent defect (eventual consistency, or stale cache, on the orders list).
- **Evidence:** 2 failures in 10 CI runs. The `--repeat-each=50` run of this spec alone, with web-first assertions and a fresh user per run, still failed 3 of 50; in those runs GET /orders omitted the just-created order for up to 2 seconds. Correct waits and isolated data rule out the test; the read-after-write lag is in the product.
- **Action:** file a product defect with `/qa-defect`, observed frequency "3 of 50 alone, 2 of 10 in CI", with the request/response timeline from one failed run as evidence. Quarantine the test so the lag stays visible in the non-blocking job rather than hidden. Do not "fix" the test by polling GET /orders until the order appears: that passes whatever the lag is and hides the defect. If the product owner decides the lag is accepted behaviour, the decision goes in the defect report, and the test is redesigned to assert the agreed consistency bound (for example, the order appears within N seconds), which is a different test, not a retry.
- **Exit:** after the product fix, `--repeat-each=100` on this spec with 4 workers, 0 failures, command and output recorded. Red-green: reintroduce the lag (or stub GET /orders to return the stale list) and confirm the test fails.

### 3. cart > updates the total when the quantity changes

- **Cause class:** unknown between test timing and product; provisionally test timing. The trace decides it.
- **Evidence:** 3 failures in 10 CI runs, the same message each time. The test clicks "+", sleeps 300 ms, then asserts `toHaveText("€58.00")`. The message says the assertion waited 5000 ms, so the sleep is a smell but is not what failed: the total never showed €58.00 in roughly 5.3 s. That fits a click that was lost (clicked before the handler was attached or while the button re-rendered), a slow update under 4 workers, or a product race. The history cannot tell which.
- **What decides it:** open a trace of a failed run. If the click produced no request, the click was lost: test timing. If the request went out and the response carried €58.00 but the DOM did not update, or the response carried another total: product defect, report it with `/qa-defect`.
- **Action now:** remove `page.waitForTimeout(300)` and wait for the cart update response in the same step as the click (`Promise.all([page.waitForResponse(...), plus.click()])`), keep the web-first `toHaveText`. Then `--repeat-each=100` on the spec with 4 workers and `--trace on`. If it still fails, classify as product and file the defect with the frequency.
- **Exit:** `--repeat-each=100` with 0 failures, command and output recorded. Red-green: change the expected total (or break the quantity handler) and confirm the test fails.

## Deterministic failure, reported apart

**profile > saves a new avatar**: 10 failures in 10 runs, `Expected "avatar.png", Received undefined`. This is not flaky and must not be quarantined. It is a failing test on main at c0ffee1. Check by hand whether the avatar is actually saved: if it is, the test reads the wrong field (test defect, fix the test); if it is not, file a product defect with `/qa-defect` and mark it "Always" (reproduced 10 of 10). If this test carries `@smoke`, the rule's stop line applies: block merges until it is resolved. Its suite tag is not in the history; the team confirms it.

## Ledger (proposed rows for flaky/ledger.md)

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| search > filters results by tag | Order or shared state | DR-SEARCH-NNN (test defect: shared seed tag) | search area owner | 2026-10-26 | 2026-11-23 | quarantined |
| orders > shows the latest order first | Product intermittent defect | DR-ORDERS-NNN (product: GET /orders stale up to 2 s, 3/50) | orders area owner | 2026-10-26 | 2026-11-23 | quarantined |
| cart > updates the total when the quantity changes | Unknown (test timing vs product); trace decides | DR-CART-NNN (opened as test defect, reclassify if trace shows product) | cart area owner | 2026-10-26 | 2026-11-23 | quarantined |

**Share.** Quarantined: 3 of 120 tests, 2.5%, under the rule's 5% threshold, so no escalation to the Development Lead. The figure is only valid once the count is confirmed with `npx playwright test --list`.

**Pipeline changes.**
- Tag the three tests `@flaky` and `@quarantine`; open the three defect reports.
- Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs.
- Add a separate non-blocking job running `--grep @quarantine` so a fix shows up as green there before retiring the row.
- Keep `retries: 0`. Raising retries would turn the orders defect into a green run and hide it.
- At 2026-11-23 without a verified fix: delete the test with the reason recorded in the ledger, or extend with a recorded decision and a new deadline. Retire a row only with the repeat-run output and the red-green proof on the fix commit.

## What the history cannot show

- Runs before these ten, and any flake rate of the 115 unlisted tests, are unknown; "all passed" is the assumption above.
- With retries 0 there is no runner-level `flaky` outcome, and no traces were kept, so the cart cause rests on the next traced repeat run.
- Causes outside the repository (shared environment load, backend deploys during the runs) are invisible here; the orders lag was reproduced on an isolated run, so it is not attributed to those.

The `testing-guidelines` and `code-style-qa` rules were read from the project's rules folder and applied; no rule was skipped.
