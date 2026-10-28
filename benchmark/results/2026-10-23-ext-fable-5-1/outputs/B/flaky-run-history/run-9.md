## Summary

| Test | Fails | Classification | Root cause | Action |
| --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3/10 | Flaky, test-caused (most likely) | Click sent before the page is ready, or shared cart state across workers; fixed sleep is a smell but not the cause | Quarantine, fix test, re-verify |
| profile > saves a new avatar | 10/10 | Not flaky, consistent failure | Avatar field missing from the saved profile or response | Treat as a bug on main, fix or revert today |
| search > filters results by tag | 4/10 | Flaky, test-caused | Cross-spec data pollution: tags.spec.ts renames the seeded tag the test depends on | Fix data isolation now, no quarantine needed |
| orders > shows the latest order first | 2/10 | Flaky, product-caused | Read-after-write inconsistency in GET /orders | File backend bug, quarantine with link, add API regression test |
| login > signs in with valid credentials | 0/10 | Stable | None | Keep, use in smoke suite |

Only two of the ten runs were green once the always-failing profile test is set aside. Together these four tests give the suite roughly a 20 percent chance of passing on a commit with no real regression, which is the number that matters for the team.

Assumptions, because the data does not say: the suite runs against one shared seeded database and one shared test account across all four workers. The CI version of the orders test uses a non-retrying assertion, based on the Expected/Received message format. The cart failure message's "received" text was not captured. Playwright file ordering is default, so spec execution order varies between runs.

## Test-by-test analysis

**cart > updates the total when the quantity changes.** The three failures are intermittent with no pattern across runs. The failure message is the key fact: a web-first `toHaveText` assertion already retries for five seconds, so the 300 ms sleep is dead weight rather than the cause. The total never reached €58.00 in over five seconds, which means the click did not take effect or the starting state was wrong. Two hypotheses fit a 30 percent rate with four workers. First, the click fires before the "+" button has its handler attached, so the click is swallowed. Second, another worker's test modifies the same cart because the account is shared, so the total lands on a different value. The received text distinguishes them: €29.00 means a lost click, any other amount means shared state. Actions:

- Quarantine with `test.fixme` and a ticket link. Thirty percent is too high to leave in the merge-blocking path.
- Enable `trace: 'retain-on-failure'`, since `on-first-retry` never fires with retries set to zero, and read the trace from the next failure.
- Assert the precondition before clicking: quantity reads 1 and total reads the starting amount. Then wait for the cart update response alongside the click rather than sleeping.
- If the cart is shared, give the test its own user via a fixture.
- Delete the `waitForTimeout` call regardless.
- Un-quarantine only after 50 consecutive passes with `--repeat-each=50 --workers=4`.

**profile > saves a new avatar.** Ten failures in ten runs is not flakiness. This is a deterministic failure on main at commit c0ffee1 and must not go into the flaky bucket, because that would hide a regression. The received value is `undefined` rather than a wrong filename, which points to the avatar field being absent from the response or the stored profile. Either the upload no longer persists the field, the API response shape changed, or the test reads a renamed property. Actions:

- Triage today as a blocking bug. Bisect to the commit that introduced it.
- If it is a product regression, fix forward or revert. If it is a test reading a renamed field, fix the test and confirm the rename was intentional.
- Check whether the main branch has been red on this test for several commits. If so, the team has been merging over a red suite, which is the process problem to address.

**search > filters results by tag.** This one is fully explained. The test filters by the seeded tag "summer" and tags.spec.ts renames that tag during its own run. With four workers, whichever spec runs first decides the outcome, which is why the rate looks random. Twenty clean passes in isolation confirm order dependence rather than a product fault. The received count deserves a second look: the filter returned five results, more than the expected three, when the tag no longer existed. That suggests the search silently drops an unknown tag filter and returns everything. Actions:

- Fix now rather than quarantine. The fix is small and the cause is known.
- Never mutate seed data in a test. tags.spec.ts should create its own tag to rename, and search.spec.ts should create its own uniquely named tag per test via a fixture.
- Open a separate low-priority product question: should filtering by a nonexistent tag return zero results instead of all of them?
- Audit the other specs for writes to seeded rows, since this pattern rarely exists in just one place.

**orders > shows the latest order first.** This is a genuine product defect surfacing as a flaky test, and the isolation run proves it. A fresh user per run rules out shared state. Web-first assertions rule out assertion timing. The backend still returned the list without the new order for up to two seconds after creation in three of fifty runs. The page most likely fetches orders once on load, so if that single fetch gets a stale list, the DOM never updates and no amount of auto-waiting helps. Likely causes are a read replica lagging behind the primary, a cache not invalidated on write, or an asynchronous indexing step. Actions:

- File a backend bug for read-after-write consistency on GET /orders. A user who places an order and does not see it is the same defect the test found.
- Do not paper over it with a sleep or a page reload loop. That would hide the bug from the only check that catches it.
- Switch the CI version to `toHaveText` anyway, so the test fails for the right reason.
- Quarantine with a link to the backend bug until the fix lands.
- Add an API-level test that asserts the order appears in GET /orders immediately after POST returns created. That becomes the regression test for the backend fix and is faster than the UI path.
- If product decides a short stale window is acceptable, the test should encode that explicit tolerance with `expect.poll` and a documented upper bound. That is a product decision, not a test decision.

**login > signs in with valid credentials.** Ten of ten passes. Keep it and use it as a smoke test. Ten runs cannot prove a low failure rate, since a test failing five percent of the time would still pass all ten runs more often than not. Treat it as stable until the flakiness dashboard says otherwise.

## Suite-level actions

- Keep retries at zero on main. It is what made this analysis possible. If retries are introduced for pull requests, report retried passes as flaky in the dashboard rather than as green.
- Introduce per-test data fixtures that create a fresh user and fresh records, and stop sharing the seeded account across workers. Three of the four problem tests are affected by or suspected of shared state.
- Add a quarantine project in the Playwright config that runs quarantined tests without blocking merges, with an owner and an expiry date on every entry. Quarantined tests with no owner after two weeks get deleted.
- Set a rule that a consistently failing test is never labelled flaky. Flaky means intermittent on the same commit with no code change.
- Rerun this same ten-run experiment after the fixes. The target is zero intermittent failures across ten runs on one commit before declaring the suite trustworthy again.
