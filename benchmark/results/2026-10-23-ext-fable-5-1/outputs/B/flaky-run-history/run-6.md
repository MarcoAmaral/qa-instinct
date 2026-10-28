## Flakiness analysis: e2e suite, commit c0ffee1, 10 runs

**Bottom line.** Two tests are genuinely flaky because of test design (cart, search). One test is not flaky at all but a deterministic failure that should block the build (profile). One test is non-deterministic because of a product defect, not the test (orders). Login is stable and serves as the control.

Assumptions, since the history does not say: the seeded database is shared across all four workers within a run, the ten runs used the same CI runner class, the default expect timeout of 5 s is in effect, and nothing other than test code and seed data differs between runs.

### Summary

| Test | Failed runs | Classification | Root cause | Owner | Action |
| --- | --- | --- | --- | --- | --- |
| cart > updates the total | 3 / 10 | Flaky, test timing | Fixed sleep instead of a readiness condition; click is lost under load | Test author | Fix test this sprint, keep in gate |
| profile > saves a new avatar | 10 / 10 | Not flaky, deterministic failure | Field missing from response or DOM on this commit | Profile feature owner | Treat as red build, fix or revert now |
| search > filters results by tag | 4 / 10 | Flaky, test isolation | Shared seed tag mutated by a parallel spec | Test author plus tags.spec owner | Fix both specs, keep in gate |
| orders > shows the latest order first | 2 / 10 | Non-deterministic, product bug | Read-after-write lag on GET /orders up to 2 s | Backend | File bug, quarantine with ticket link |
| login > signs in | 0 / 10 | Stable | None | None | No action |

Ten runs is a small sample. A test seen failing twice in ten runs could plausibly fail anywhere from a few percent to half the time, so treat the rates above as rough, not as targets.

### cart > updates the total when the quantity changes

**What happened.** The assertion waits up to 5 s for the total to read €58.00, and in the failing runs the total never got there. This is not a rendering race that a slightly longer wait would cover. The value never changed, so the click itself was lost or applied to stale state.

**Why.** The 300 ms sleep before the click is a readiness guess. Under four workers the page is slower to become interactive, and some fraction of the time the click fires before the handler is attached or before the cart data has loaded. The sleep happens to be long enough on a quiet machine, which is why it looks random.

**What to do.**
- Replace the sleep with a deterministic precondition. Assert the initial total or quantity is visible and correct before clicking, or wait for the cart API response. The existing toHaveText assertion already auto-waits and needs no sleep after it.
- Enable trace on failure for this spec so the next failure shows whether the click was dispatched before hydration or whether the recalculation request was slow or failed.
- If the fixed test still fails, that is an application bug: the button is rendered interactive before it works. Hand it to the frontend owner at that point, not before.
- Do not raise the timeout and do not add retries. Both hide the lost click.

### profile > saves a new avatar

**What happened.** The test failed in every run with the identical assertion: expected the string avatar.png, received undefined. That is deterministic behaviour on this commit.

**Why.** Received undefined means the test is reading a property that does not exist, most often a renamed or dropped field in an API response or a removed data attribute. Either the application regressed on c0ffee1 or an upstream contract changed and the test was not updated. Both are legitimate failures.

**What to do.**
- Stop calling this flaky. It must not be retried, quarantined, or skipped. A ten-for-ten failure is a red build.
- The profile feature owner should check the avatar save path and the field name the test reads, then fix the app or update the test today. If the fix is not quick, revert the change that introduced it.
- Confirm the test passed on the parent commit. If it also failed there, the breakage predates c0ffee1 and the team has been shipping over a red test.

### search > filters results by tag

**What happened.** Fails roughly four runs in ten under four workers, passes twenty of twenty when run alone. The failing assertion sees five results instead of three.

**Why.** Classic cross-test pollution. This spec relies on the seeded tag named summer, and tags.spec.ts renames that same tag during its own run. Whenever the scheduler happens to run tags.spec alongside or before search.spec on another worker, the filter no longer matches what the test expects. The outcome depends on worker scheduling, which is why it looks random.

**What to do.**
- Make each spec own its data. search.spec should create its own uniquely named tag and products in a beforeEach or fixture, and tags.spec should rename a tag it created itself rather than a shared seed row.
- Add a rule to the test guidelines: seed data is read-only in tests. Any test that mutates shared data must create its own copy first.
- Audit the suite for other specs that write to seed rows. This pair is unlikely to be the only one.
- Do not fix this with a single worker or with serial mode. That hides the coupling, slows CI, and breaks again the next time someone adds a parallel spec.

### orders > shows the latest order first

**What happened.** Fails two runs in ten in CI. More importantly, the isolated repeat run with web-first assertions and a fresh user per iteration still failed three times in fifty, and the network log shows GET /orders returning the list without the new order for up to 2 s after creation.

**Why.** This is a product defect, not test flakiness. The orders read path does not guarantee read-your-writes. Likely causes are a read replica lagging behind the primary, a response cache keyed on the user, or an async indexing step between order creation and listing. The test is doing the right thing and is reporting a real bug a user would see: place an order, open the orders page, the order is not there.

**What to do.**
- File a backend bug with the repro command, the failure rate, and the 2 s lag window. Suggest a severity of high, since it is user-visible on the core purchase flow.
- Get a product decision on whether the orders list must be read-your-writes consistent. If yes, the fix is in the backend, for example reading from the primary after a write or invalidating the cache on order creation. If the product accepts eventual consistency, the backend must document the bound, and only then should the test poll within that bound using expect.poll or toPass.
- Until the backend fix lands, quarantine the test with a reference to the bug ticket so it still runs and reports but does not block merges. Set a review date. Do not add a sleep and do not delete the test.

### login > signs in with valid credentials

Stable across all ten runs. No action. Keep it as the sanity check when validating any change to the test infrastructure.

### Suite-level recommendations

- Keep retries at zero on main. This history is only visible because retries were off. If the team wants retries anywhere, enable them on pull request runs only and treat a pass-on-retry as a flake report, not a success.
- Add trace retention on failure across the suite. The cart investigation would already be finished with a trace.
- Introduce a quarantine mechanism, such as a separate Playwright project or a tag, with a mandatory ticket link and expiry date. Orders goes in it. Profile does not.
- Record per-test pass rates over the last N runs on main so flaky tests are identified by data rather than by someone noticing a pattern in ten runs.
- Re-run these five tests ten more times after the cart and search fixes to confirm the rates drop to zero before closing the work.
