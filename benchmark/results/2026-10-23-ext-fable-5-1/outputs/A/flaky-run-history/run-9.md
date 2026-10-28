**Summary**

| Test | Fails | Verdict | Root cause | Owner action |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10/10 | Not flaky, broken | Avatar name never comes back (received `undefined`) | Fix the regression on c0ffee1 |
| search > filters results by tag | 4/10 | Flaky, test pollution | tags.spec.ts renames the shared "summer" seed tag | Fix tags.spec.ts to use its own data |
| cart > updates the total when the quantity changes | 3/10 | Flaky, test bug | Fixed sleep plus a click that is sometimes lost or not reflected within 5 s | Rewrite the wait, add trace on failure |
| orders > shows the latest order first | 2/10 | Flaky, product bug | GET /orders is stale for up to 2 s after creating an order | File backend bug, poll in the test meanwhile |
| login > signs in with valid credentials | 0/10 | Stable | None | None |

Assumptions: the table shows only the tests that failed at least once, plus login as a control, and the other 115 tests passed in all ten runs. All four workers share one seeded database. The cart failure message does not include the received text, so I assume the total never changed from its original value rather than showing a wrong number.

## Per-test findings

**profile > saves a new avatar is not flaky.** It failed in every run with the same assertion, so it is deterministic. A test that fails ten out of ten times on the same commit is a broken feature or a broken test, and either way it must not be labelled flaky, retried, or quarantined. `undefined` means the avatar field is missing entirely from whatever the test reads, which points at a renamed response field, a changed data-testid, or an upload that silently fails. Bisect main to the commit that introduced it and fix it there. Until then it is a legitimate red build.

**search > filters results by tag is flaky because of test pollution, and the culprit is tags.spec.ts.** The evidence is clean: 20 of 20 passes alone, 4 of 10 failures under 4 workers, and a known writer of the "summer" tag running concurrently. When tags.spec.ts renames the tag mid-run, the search returns results that no longer match, and the count drifts from 3 to 5. Whether it fails depends only on worker scheduling. Fix the writer, not the reader: tags.spec.ts should create its own uniquely named tag to rename and should never touch shared seed rows. As defence in depth, search.spec.ts should also create its own tag and products in a `beforeEach` so it does not depend on the seed at all. Do not solve this with `--workers=1` or retries. Serial mode hides the coupling and slows the suite, and retries pass as soon as the scheduling changes, which teaches nothing.

**cart > updates the total when the quantity changes is flaky because the test is racy by construction.** The 300 ms `waitForTimeout` is never a correct synchronisation point, but note that the failure is a 5 s `toHaveText` timeout, so the sleep is not what is timing out. The total is not reaching €58.00 within 5.3 s at all. The two likely causes are a click dispatched before the page has hydrated, so the handler never runs, or a recalculation that is slow when four workers load the backend. Rewrite the step so each wait is on a real state change: wait for the "+" button to be enabled, click it, assert that the quantity field shows the new quantity, then assert the total. Remove the sleep. Turn on `trace: 'on-first-retry'` or `'retain-on-failure'` for this spec so the next failure shows whether the click landed and what the network did. Do not raise the assertion timeout. If the trace shows the backend genuinely takes more than 5 s to recompute a cart total, that is a performance regression to report, not a timeout to widen.

**orders > shows the latest order first is flaky because of the application, not the test.** The test already uses web-first assertions and a fresh user per run, and it still fails 6 percent of the time in isolation. The isolated run shows the cause directly: GET /orders omits a just-created order for up to 2 s. That pattern is read-after-write inconsistency, typically a read replica, a cache in front of the list endpoint, or an asynchronous indexing step. A real user who places an order and lands on the orders page can hit the same gap, so this is a product bug. File it against the backend with the 2 s figure and the repro command. In the test, decide which contract you are asserting. If the product promises read-your-writes, keep the assertion strict and quarantine the test with a link to the ticket until the backend is fixed. If a short delay is accepted, wrap the check in `expect.poll` or `toPass` with a bound equal to the agreed SLA and reference the ticket in a comment, so the tolerance is explicit rather than accidental. My recommendation is the first option, because silently polling converts a product defect into permanent test slack.

**login > signs in with valid credentials needs no action.** Ten passes is modest evidence, since a test with a 10 percent failure rate still passes ten in a row about a third of the time, but there is no signal here to act on.

## Suite-wide actions

- Keep `retries: 0` on main. It is the reason this data is readable. Enabling retries would have hidden search and orders entirely and softened cart to an occasional yellow.
- Adopt a rule that spec files only mutate data they created. Audit the other specs for writes to seed rows, since tags.spec.ts is unlikely to be the only one.
- Ban `page.waitForTimeout` in the e2e suite with a lint rule and a one-time sweep.
- Record a trace on failure globally. Three of these four diagnoses would have taken minutes with a trace instead of a 50-iteration repro.
- Run this same ten-iteration experiment on main after the fixes land. A flaky test is only fixed when it passes repeatedly under the same parallel load that broke it.
