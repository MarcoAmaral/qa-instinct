# Flaky test analysis: e2e suite at c0ffee1 (main)

**Source:** 10 CI runs of the same commit, Playwright, 4 workers, `retries: 0`, 120 tests. Read only: the run table and the failure messages supplied. Nothing was run by me; the repeat runs quoted below are the team's own, as reported.

**Assumptions (information not supplied):**
- The 115 tests not in the table passed in all 10 runs. If any of them has a mixed record, it is a suspect too and belongs in the ledger.
- Quarantine period and escalation threshold: the `testing-guidelines` rule could not be loaded (see the end of this report), so I use **one sprint = 2 weeks** (deadline 2026-11-09 from today, 2026-10-26) and treat **more than 5% of the suite quarantined** as the escalation point. Replace both with the rule's values.
- Test IDs are `<spec file> > <title>`; owners are "TBD" until the team assigns them. A row without an owner is not yet a quarantine.

## 1. Verdict per test

| Test | Failures / runs | Verdict | Cause class |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 / 10 | **Flaky** | Test timing (provisional, see below) |
| profile > saves a new avatar | 10 / 10 | **Deterministic failure, not flaky** | Defect (product or test), main is red |
| search > filters results by tag | 4 / 10 | **Flaky** | Order or shared state (cross-spec data mutation) |
| orders > shows the latest order first | 2 / 10 | **Flaky** | **Product intermittent defect** (eventual consistency) |
| login > signs in with valid credentials | 0 / 10 | Not a suspect | 0 failures in 10 runs; this bounds the rate, it does not prove zero |

## 2. Why, and what to do with each

### cart > updates the total when the quantity changes: fix the test, then re-check

**Evidence.** Fails 3 of 10 with `Timeout 5000ms exceeded waiting for getByTestId('cart-total') to have text "€58.00"`. The test clicks "+" and then calls `page.waitForTimeout(300)` before asserting.

**Reading.** The hard sleep is a `code-style-qa` violation and must go, but note what the message says: the final assertion is already web-first and waited a further 5 s. So the sleep is not what fails; something after the click takes longer than 5.3 s, or the click never registered (clicked before the handler was attached, a common cause when the test clicks right after navigation). Under 4 workers the app is also under load, which widens the window.

**Classification:** test timing, provisional. What decides it: open the Playwright trace of one failed run and check whether the quantity changed and whether the cart update request was sent. If the request was sent and the response carried the new total but the DOM did not update, this is a product defect and moves to `/qa-defect`.

**Fix.** Remove the sleep. Wait for the cart update response (`page.waitForResponse` on the cart endpoint, started before the click) and assert the quantity field first, then the total, with `expect(...).toHaveText(...)`. Do not raise the assertion timeout as the fix.

**Exit proof.** On the fix commit: `npx playwright test cart.spec.ts --workers=4 --repeat-each=50` with 0 failures recorded, plus red-green: break the total calculation (or stub the response with the old total) and confirm the test fails.

### profile > saves a new avatar: not flaky, report it now

**Evidence.** Fails 10 of 10 with `Expected: "avatar.png", Received: undefined`. Same message every run, no variance.

**Reading.** This is a deterministic failure on main. It is either a product defect (the saved avatar is not returned or not persisted) or a test defect (the test reads a property that no longer exists in the response or page). Either way, main has been red for 10 runs on this test and that is the first thing to say to the team. Per ISTQB CTFL §1.2.3 the cause may be a defect or the environment; one manual or API check settles which: save an avatar by hand and read the profile back.

**Action.** Do not quarantine; quarantine is for tests whose verdict changes. File it with `/qa-defect` as a reproducible defect ("Always", 10 of 10), assign an owner, and fix or revert the change that broke it. If the team must unblock the pipeline before the fix, skip it with the defect reference in the skip reason, not with `@quarantine`.

### search > filters results by tag: fix the data isolation

**Evidence.** Fails 4 of 10 in CI with `expected 3 results, received 5`. Alone (`npx playwright test search.spec.ts --workers=1 --repeat-each=20`) it passed 20 of 20. It filters by the seeded tag `summer`, which `tags.spec.ts` renames during its own run.

**Reading.** Textbook shared-state collision: with 4 workers, whether `tags.spec.ts` has already renamed `summer` when `search.spec.ts` queries it depends on scheduling. The 20 of 20 pass alone and the known mutation make the class certain.

**One thing to look at.** A renamed tag should give 0 results, not 5. If 5 is the unfiltered total, the search endpoint may be silently ignoring an unknown tag and returning everything. That is a product behaviour worth a quick check and possibly its own report; it is not what makes the test flaky.

**Fix.** Neither spec may use the shared seed `summer`. Each test creates its own tag with a unique name (for example suffixed with the test ID or a timestamp) in a `beforeEach` or fixture and cleans it up; `tags.spec.ts` renames only a tag it created. Do not fix it with serial mode or a fixed spec order; that hides the coupling and slows the suite.

**Exit proof.** On the fix commit: `npx playwright test --workers=4 --repeat-each=20 search.spec.ts tags.spec.ts` with 0 failures recorded, plus red-green: break the tag filter (return all results) and confirm the search test fails.

### orders > shows the latest order first: product defect, report with frequency

**Evidence.** Fails 2 of 10 in CI with `Expected "Order #1043", Received "Order #1042"`. The team's `--repeat-each=50` run of this spec alone, with web-first assertions and a fresh user per run, still failed 3 of 50. In those runs `GET /orders` returned the list without the new order for up to 2 s after creation.

**Reading.** Correct waits, isolated data, still fails, and the API itself is observed returning stale data. This is not a test problem. It is an intermittent product defect: an order exists but is not yet visible on read (read replica lag, a cache, or an asynchronous write). Quarantining it alone would hide a defect that real users will hit.

**Action.** File with `/qa-defect` as a **product** defect with the observed frequency: 3 of 50 alone, 2 of 10 in CI, stale read for up to 2 s. Quarantine the test with the report ID so the pipeline is not blocked, and keep it running in the non-blocking quarantine job so the product fix is visible when it lands. Do not fix the test by polling until the order appears or by adding a sleep; a test that waits out the staleness turns the defect into a pass.

**Exit proof.** After the product fix: `npx playwright test orders.spec.ts --workers=4 --repeat-each=100` with 0 failures recorded (the 3 of 50 base rate needs more than 50 runs to be meaningful), plus red-green: break the ordering and confirm the test fails.

### login > signs in with valid credentials

0 failures in 10 runs. No action. The sample is small; this bounds the failure rate, it does not prove the test is stable.

## 3. Quarantine proposal and ledger

Proposed rows for `flaky/ledger.md`. The team decides and assigns owners; nothing is quarantined until it does.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart.spec.ts > updates the total when the quantity changes | Test timing (provisional, confirm from trace) | None needed unless trace shows a product cause | TBD | 2026-10-26 | 2026-11-09 | quarantined |
| search.spec.ts > filters results by tag | Order or shared state (seed tag mutated by tags.spec.ts) | None (test-side); optional report for unknown-tag filter behaviour | TBD | 2026-10-26 | 2026-11-09 | quarantined |
| orders.spec.ts > shows the latest order first | Product intermittent defect (stale GET /orders up to 2 s) | DR to be filed via `/qa-defect`, frequency 3/50 alone, 2/10 in CI | TBD (product team) | 2026-10-26 | 2026-11-09 | quarantined |

Not in the ledger: `profile.spec.ts > saves a new avatar` (deterministic, defect report instead) and `login.spec.ts` (no evidence of flakiness).

**Share.** 3 quarantined of 120 listed tests = 2.5%. Under the assumed 5% threshold, so no escalation. Confirm the denominator with `npx playwright test --list` rather than the figure in the run summary.

**Pipeline changes.**
- Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs.
- Add a separate, non-blocking job running `--grep @quarantine` on every pipeline run so fixes become visible.
- Keep `retries: 0`. Raising retries would make cart and search go green while leaving the causes in place, and would hide the orders defect entirely (ISTQB CTFL §6.2: relying on a tool without critical thinking).
- No self-healing selectors anywhere in the fix.

**At the deadline.** Each row is either retired (fixed, with the repeat-run output and red-green proof recorded) or deleted with the reason in the ledger, or extended with a recorded decision and a new date. Cart and search are small test-side fixes and should not need the full period.

## 4. What this history cannot show

- Runs before these 10 and on earlier commits; whether these tests were already flaky before c0ffee1.
- The other 115 tests; assumed stable at 10 of 10.
- Whether the CI environment itself was stable across the 10 runs (runner load, database latency). The stale read in orders may have an infrastructure component that only the service owner can see.
- Whether the cart click registered in the failed runs; the trace decides that.
- Why search received 5 results rather than 0; one manual query decides that.

**Rules not applied.** The `testing-guidelines` rule (quarantine period, escalation threshold and who to escalate to) and the `code-style-qa` rule could not be loaded: no `qa-rules` skill is installed and file lookup in the skill tree was denied in this session. The 2-week deadline and 5% threshold above are stated assumptions, not the rule's figures.
