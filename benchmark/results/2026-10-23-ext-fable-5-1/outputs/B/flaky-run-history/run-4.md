# Flakiness analysis: e2e suite on c0ffee1 (10 runs, 4 workers, retries 0)

## Summary

| Test | Failures | Verdict | Root cause | Owner | Action |
| --- | --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10/10 | **Not flaky. Consistent failure.** | Regression or broken contract in avatar save | Profile feature team | Treat as a real bug. Block on it. |
| search > filters results by tag | 4/10 | **Flaky. Test defect.** | Shared seed data mutated by tags.spec.ts on another worker | QA / test authors | Fix test isolation. No product bug. |
| cart > updates the total when the quantity changes | 3/10 | **Flaky. Test defect, product issue not ruled out.** | Race between click and app readiness, plus a fixed sleep | QA, then cart team if traces show the app | Rewrite waits, collect traces, decide. |
| orders > shows the latest order first | 2/10 | **Flaky. Real product bug.** | Read-after-write lag in GET /orders of up to 2 s | Orders backend team | File bug. Quarantine with ticket. Do not mask with polling. |
| login > signs in with valid credentials | 0/10 | Stable | None | None | Keep as the control case. |

Assumptions made throughout:
- The other 115 tests passed in all 10 runs. Only these five were reported.
- All 10 runs used the same runner class and the same seeded database snapshot.
- tags.spec.ts belongs to the same Playwright project and can be scheduled on any worker at any time.
- Failure messages were identical per test, so each test has a single dominant failure mode.

Overall health: even with the profile failure fixed, only 2 of 10 runs (R1 and R6) would have been green. The suite is red roughly 80 percent of the time from the three flaky tests alone. That is the number the team should care about, more than any single test's rate.

## Test by test

### profile > saves a new avatar (10/10 failed)

This is not flaky and must not be treated as flaky. Ten of ten identical failures on one commit is a deterministic defect. Received `undefined` where "avatar.png" was expected means the field the test reads no longer exists on the object it reads it from. That is either a product regression in c0ffee1 (avatar not persisted, or response shape changed) or a test that was never updated after an API or DOM change.

What to do:
1. Check whether c0ffee1 or its recent ancestors touched the profile or upload code. If yes, it is a regression and the commit should not ship.
2. If the product code did not change, the test's selector or field name is stale. Fix the test, but confirm manually that avatar save actually works first.
3. Do not add this to any flaky list, do not retry it, and do not quarantine it. A consistently failing test is a signal, not noise.

### search > filters results by tag (4/10 failed)

Root cause is confirmed: test interdependence through shared mutable state. The test expects 3 results tagged "summer". tags.spec.ts renames that tag during its own run. With 4 workers, whether search.spec.ts runs before, during, or after the rename depends on scheduling, which explains 4/10 in CI and 20/20 when run alone with one worker. "Expected 3, received 5" fits: once "summer" is gone the filter likely falls through to an unfiltered or default result set.

This is a test defect. The product is behaving correctly.

What to do:
1. Give each spec its own data. search.spec.ts should create a tag with a unique name (for example a UUID suffix) in `beforeEach`, tag its own fixtures, and delete them in `afterEach`.
2. tags.spec.ts should rename a tag it created itself, never a shared seed.
3. Add a lint or review rule: specs must not mutate seeded data. Mutation of shared seeds is the most common cause of worker-order flakes and this will recur elsewhere if it is not addressed as a policy.
4. Do not use `test.describe.configure({ mode: 'serial' })` or `--workers=1` as the fix. That hides the dependency and slows the suite.

### cart > updates the total when the quantity changes (3/10 failed)

The assertion is a web-first `toHaveText`, so it waited the full 5 s. The total never reached "€58.00" within 5.3 s of the click. The `waitForTimeout(300)` before it is a smell rather than the direct cause. It tells us the author already saw a race and papered over it.

Most likely cause (assumption, needs traces to confirm): the "+" click lands before the app has attached its handler, so the click is lost and the total never changes. Under 4 workers the runner is slower, hydration takes longer, and a 300 ms sleep is sometimes not enough. A second possibility is that the quantity update round-trip takes more than 5 s under load. A third is a genuine intermittent bug where the total does not recompute.

What to do:
1. Rerun this spec with `--repeat-each=50` under `--workers=4` and `trace: 'on'`. Look at the failing traces. If the click happened and no network request followed, it is a lost click. If a request went out and the response was slow, it is load. If the response came back and the DOM did not update, it is a product bug.
2. Remove `waitForTimeout(300)`. Replace it with a readiness condition: wait for the "+" button to be enabled, or wait for the specific response with `page.waitForResponse` after the click, then assert with `toHaveText`.
3. If the app ships a non-interactive button before hydration, that is a product defect too. Users can lose clicks in the same way. Raise it with the cart team.
4. Until the rewrite lands, tag it `@flaky` in a dedicated flaky project so it does not block merges, but keep running it so the rate is tracked.

### orders > shows the latest order first (2/10 failed)

The test is correct and the product is wrong. The team already did the right diagnostic: web-first assertions, a fresh user per run, and still 3 of 50 failures with evidence that GET /orders returned a stale list for up to 2 s after creation. That is read-after-write inconsistency in the backend, most likely a read replica, a cache, or an asynchronous index. The 2/10 CI rate matches the 6 percent standalone rate within noise.

This is customer-visible. A user who places an order and is redirected to their order list may not see it. Treat it as a bug, not a test problem.

What to do:
1. File a backend bug with the repro (`--repeat-each=50`, response payloads showing the missing order, timing). Severity: at least P2, since it affects the post-checkout flow.
2. Quarantine the test with `test.fixme` referencing the ticket, so CI goes green without losing the test.
3. Do not wrap the assertion in `expect.poll` or `toPass` to make it pass. That would mask the bug and turn a signal into permanent noise. If the product owner decides eventual consistency is the accepted contract, then and only then change the test to poll, and document the accepted lag.
4. Once the backend fix ships, remove the quarantine and run `--repeat-each=100` before declaring it stable.

### login > signs in with valid credentials (0/10 failed)

Stable. No action. It is useful as a control: it confirms the runner and the auth backend were healthy in every run, which rules out a whole-suite infrastructure cause for the other failures.

## Cross-cutting observations

**No common infrastructure cause.** The flaky failures cluster on different runs (cart on R2, R5, R9; search on R2, R4, R7, R10; orders on R3, R8). Only R2 shows two flakes together. If a slow runner were the cause, failures would pile up in the same runs. They do not. Each test has its own independent cause.

**Keep retries at 0 on main.** It is what made this analysis possible. Enabling retries globally would have hidden all three flakes and the orders bug with them. If the team wants retries, scope them to a quarantine project only.

**Priorities, in order:**
1. profile avatar: real failure, investigate today.
2. orders: file the backend bug and quarantine the test.
3. search: fix data isolation. Small change, removes 40 percent of noise.
4. cart: collect traces, then rewrite the waits.

**Follow-up policy.** Any test moved to the flaky project gets a ticket, an owner, and a two-week expiry. After that it is either fixed or deleted. Flaky lists without expiry only grow.
