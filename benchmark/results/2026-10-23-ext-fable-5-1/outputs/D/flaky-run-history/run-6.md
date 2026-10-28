# Flaky-test analysis: e2e suite, commit c0ffee1 (main), 10 CI runs

**Evidence base.** Everything below is read from the 10-run history and the failure messages supplied. I ran nothing; the two repeat runs quoted (search, orders) are the team's. Runs: Playwright, 4 workers, `retries: 0`, so the runner's own `flaky` outcome is not available and every flake shows as a plain failure.

**Assumptions (stated, not confirmed).**
- The other 115 tests passed in all 10 runs; only the 5 listed had any failure.
- Sprint length is 2 weeks, so the rule's 2-sprint deadline is 4 weeks from quarantine.
- The suite size of 120 comes from the brief; confirm with `npx playwright test --list` before computing the share for real.
- Owners below are placeholders by feature area; the team assigns real names.
- Defect report IDs are placeholders until filed with `/qa-defect`.

## 1. Verdicts

| Test | Runs | Failures | Verdict |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 10 | 3 | Flaky |
| profile > saves a new avatar | 10 | 10 | **Deterministic failure, not flaky** |
| search > filters results by tag | 10 | 4 | Flaky |
| orders > shows the latest order first | 10 | 2 | Flaky |
| login > signs in with valid credentials | 10 | 0 | 0 failures in 10 runs (bounded, not proven stable) |

## 2. Deterministic failure (report, do not quarantine)

**profile > saves a new avatar.** Fails 10 of 10 with the same message: expected `"avatar.png"`, received `undefined`. A test that fails every time on unchanged code is not flaky; the quarantine protocol does not apply. Something is consistently absent: the avatar file name is not returned by the API, not rendered, or the test reads a field that no longer exists.

Action:
- File it now with `/qa-defect` (frequency "Always", 10 of 10 on c0ffee1). The report describes the failure (received `undefined`), not a guess about where the defect lives.
- Debug on c0ffee1 before deciding whether the defect is in the product or in the test: open the trace, check the upload response and the rendered profile. If the test is on the `@smoke` job, this is a stop line under the rule and the MR or deployment is blocked until resolved.
- Do not tag `@flaky` or `@quarantine`. Hiding a 100% failure is exactly the graveyard the protocol exists to prevent.

## 3. Flaky tests, classified

### cart > updates the total when the quantity changes

- **Observed:** 3 failures in 10 runs (R2, R5, R9), same message each time.
- **Class:** Test timing, provisional. The hard sleep (`page.waitForTimeout(300)`) between the click and the read is the signal, and `code-style-qa` forbids it. One caveat: the message says the 5000 ms web-first wait on `cart-total` also expired, so the sleep alone does not explain the failure. The likeliest cause is that the click on "+" lands before the handler is attached, so the quantity never changes.
- **What decides it:** open the trace of a failed run. If no cart update request was sent after the click, it is test timing. If the request was sent and the server returned the right total late or wrong, reclassify as product defect and report it.
- **Fix (test):** remove the sleep, wait for the cart update response after the click (`page.waitForResponse` or the `expect.poll` pattern), then assert with `toHaveText`. Before the click, assert the control is enabled and the initial total is rendered, so the click cannot land on a half-hydrated page.

### search > filters results by tag

- **Observed:** 4 failures in 10 runs (R2, R4, R7, R10): expected 3 results, received 5. Passed 20 of 20 alone with `--workers=1 --repeat-each=20`.
- **Class:** Order or shared state (test data collision between workers). `tags.spec.ts` renames the seeded tag "summer" during its run; when it lands on a parallel worker at the wrong moment, the search test counts items under a tag that no longer matches. Passes alone, fails in the suite: textbook isolation failure. Not a product defect.
- **Fix (test isolation):** each spec creates and deletes its own tag with a unique name (for example a `test.info().testId` or UUID suffix) instead of sharing the seed. `tags.spec.ts` must rename only a tag it created. If the seed cannot be changed, use a per-worker fixture that seeds a private tag. Do not "fix" with `--workers=1` or serial mode; that hides the dependency and slows the suite.

### orders > shows the latest order first

- **Observed:** 2 failures in 10 CI runs (R3, R8). The team's repeat run (50 runs alone, web-first assertions, a new user per run) still failed 3 of 50, and in those runs `GET /orders` omitted the new order for up to 2 seconds after creation.
- **Class:** **Product intermittent defect.** The test already has correct waits and isolated data, and the failure reproduces alone. A list endpoint that returns stale data for up to 2 s after a write is eventual consistency, a read replica or cache lag, or a missing read-after-write guarantee. A real user who places an order and opens the list can see the same thing.
- **Action:** file with `/qa-defect` as a **product** defect, frequency 3 of 50 alone and 2 of 10 in CI, with the request timing evidence. Quarantine the test to keep CI readable, but the defect report is the deliverable; quarantine alone hides it. Do not make the test poll until the order appears: that converts the bug into a pass. The exit for this row is the product fix, after which the test should pass the repeat run unchanged.

### login > signs in with valid credentials

Not a suspect. 0 failures in 10 runs bounds the rate; it does not prove zero. No action.

## 4. Quarantine and ledger (proposal, team decides)

Per the `testing-guidelines` rule: tag `@flaky`, open the defect report, move to `@quarantine`, resolve or delete within **2 sprints**, escalate to the Development Lead above **5%** of the suite.

Proposed `flaky/ledger.md` rows (quarantined on 2026-10-26, deadline 2026-11-23 under the 2-week sprint assumption):

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | Test timing (provisional, confirm by trace) | DR-CART-001 (to file) | Cart owner (assign) | 2026-10-26 | 2026-11-23 | quarantined |
| search > filters results by tag | Order or shared state | DR-SRCH-001 (to file) | Search owner (assign) | 2026-10-26 | 2026-11-23 | quarantined |
| orders > shows the latest order first | Product intermittent defect | DR-ORD-001 (to file, product) | Orders backend owner (assign) | 2026-10-26 | 2026-11-23 | quarantined |

A row with no owner or no deadline is not a quarantine; fill the owner column before merging the tags.

**Share:** 3 quarantined of 120 = 2.5%, below the 5% threshold. No escalation. Recompute against `npx playwright test --list` on the fix branch. (The profile test is not counted; it is a defect, not a quarantine.)

**Exclusion:** add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs. Add a separate, non-blocking job that runs `--grep @quarantine` on every pipeline so a fix becomes visible without anyone remembering to look.

**Do not** raise `retries` to make the runs green. It would mask the orders defect entirely and turn the cart and search failures into silent noise.

## 5. Exit criteria per row

A row retires only when both hold on the fix commit:

1. **Repeat run passes**, with CI's worker count, and the command and output are recorded in the ledger:
   - cart: `npx playwright test cart.spec.ts --workers=4 --repeat-each=50`
   - search: run with the full suite, not alone, since the collision only appears in parallel: `npx playwright test --workers=4 --repeat-each=10 --grep "search|tags"`
   - orders: `npx playwright test orders.spec.ts --workers=4 --repeat-each=50` after the backend fix, with the test unchanged.
2. **Red-green still holds:** break the behaviour (wrong total, wrong filter, wrong order) and show the spec fails. A test that can no longer fail is not fixed.

Then remove `@flaky` and `@quarantine` and mark the row `retired (fixed)`. At 2026-11-23 without a fix: delete the test with the reason recorded, or extend with a recorded decision and a new date.

## 6. What this history cannot show

- Only 10 runs on one commit. Rates like 2 in 10 are rough; the orders rate from 50 runs is the better figure.
- With `retries: 0` there is no runner-level `flaky` outcome, so earlier green runs that passed on retry (if the setting ever differed) are not visible.
- Whether any of these tests failed on other commits. If runs on earlier commits were not kept, the history starts here.
- Why `GET /orders` is stale. The cause is in the backend or its infrastructure, outside the test repository; the defect report carries the evidence to whoever owns it.
- For the cart test, whether the click was ever received. The trace of a failed run decides the class; until then "test timing" is the working hypothesis, not a finding.
