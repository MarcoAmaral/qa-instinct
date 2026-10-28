# Flaky-test triage: e2e suite, commit c0ffee1, 10 CI runs

## Summary

| Test | CI failures | Verdict | Root cause | What to do |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10/10 | Not flaky. Deterministic failure | Avatar name missing from the saved profile, most likely a product or API-shape regression | Treat as a real break. Fix first, do not quarantine |
| search > filters results by tag | 4/10 | Flaky, test-suite problem | Shared seed data mutated by tags.spec.ts in a parallel worker | Isolate test data. Fix this week, no quarantine needed |
| cart > updates the total when the quantity changes | 3/10 | Flaky, test problem most likely | Click fires before the page is ready, or shared cart state. Sleep-based wait hides the real ordering assumption | Rewrite the waits and confirm with a trace. Quarantine only if the fix slips |
| orders > shows the latest order first | 2/10 in CI, 3/50 alone | Flaky, product problem | GET /orders returns a stale list for up to 2 s after an order is created | File a backend bug. Quarantine with the ticket linked, keep running nightly |
| login > signs in with valid credentials | 0/10 | Stable | None | None |

Assumptions used throughout: the other 115 tests passed in all ten runs; all four workers share one seeded database and backend; nothing changed in the CI environment between runs; "flaky" means the same commit produces different outcomes without a code change.

One suite-level number matters. If the profile test were fixed and nothing else changed, the chance of a fully green run would be about one in three.

| Scenario | Probability a run is green |
| --- | --- |
| Today | 0 % (profile fails every run) |
| Profile fixed, three flaky tests untouched | 0.7 × 0.6 × 0.8 ≈ 34 % |
| Search and cart fixed, orders quarantined | ≈ 100 % |

## Per-test findings

**profile > saves a new avatar. Not flaky.** Ten failures in ten runs with an identical message is a consistent failure, not flakiness, and it should leave the flaky-test discussion immediately. "Received: undefined" means the field the test reads is absent from the response or page model, not wrong. The usual causes are a renamed or nested field in the profile API, a serializer that drops the avatar when the upload is handled asynchronously, or a missing upload fixture file in CI. I cannot tell which from the data. Assumption: this test passed on the parent commit, so c0ffee1 or its environment introduced it. Actions: run it locally against c0ffee1 and the parent commit, inspect the actual profile response in the trace, and either fix the product or update the test's field path. Do not add retries or quarantine; a deterministic failure on main is a blocker.

**search > filters results by tag. Flaky, caused by test interference.** Four failures in ten runs, zero in twenty isolated repeats, and a known writer of the same seed row point squarely at order-dependent data corruption. The spec expects three results tagged "summer". When tags.spec.ts runs in another worker and renames "summer" first, the search sees a different tag set and returns five. The failure rate reflects how often the two specs overlap in time, not anything about the product. The culprit is tags.spec.ts mutating shared seed data, so the fix belongs there as well as in search.spec.ts. Actions:

- Change tags.spec.ts to create its own tag with a unique name and rename that, instead of touching the seed.
- Change search.spec.ts to create its own tag and items inside the test, or give each worker its own seed namespace keyed on the worker index.
- Grep the suite for every other reader of "summer" and fix them the same way.
- Do not "fix" this by setting workers to 1 or by serializing the two files. That hides the dependency and slows the suite.

No quarantine. The cause is known, the fix is a few lines, and the test is useful.

**cart > updates the total when the quantity changes. Flaky, cause not yet proven.** Three failures in ten runs, always the same timeout. One detail matters: the failing assertion is already a web-first expectation that retries for five seconds, so the 300 ms sleep is not what fails. The sleep is evidence that the author was papering over an ordering problem, and it is not covering it reliably. Two explanations fit the data and the trace from any failed run will distinguish them:

- The "+" click lands before the component's handler is attached, so the quantity never changes. Under four workers the app loads slower and this window opens more often. In the trace the quantity will still read 1 and the total will be unchanged.
- The cart is shared with another test or worker, so the real total is some other value. In the trace the total will show a different, non-expected amount.

Assumption: the first explanation, because the sleep was clearly added to wait for something after navigation. Actions:

- Remove the sleep. Before clicking, wait for the page to be interactive, for example by asserting the quantity control is enabled and the initial total is rendered.
- After clicking, assert the quantity field first, then the total. This separates "click lost" from "total wrong" in future failures.
- Ensure the test uses a fresh cart per test via a fixture.
- Verify with a repeat run of at least 30 iterations at four workers before closing.

Fix it this week. If the fix slips, quarantine it with a ticket so it stops masking the orders signal.

**orders > shows the latest order first. Flaky, and the product is the cause.** This one fails with a brand-new user, with web-first assertions, and with the spec run alone, so test isolation and synchronization are ruled out. The backend returns the order list without the newly created order for up to two seconds. That is a read-after-write consistency gap, typically a read replica, a response cache, or an asynchronous indexing step behind the list endpoint. The web-first assertion cannot help here because the page fetches once and renders a stale list; retrying on the DOM never triggers a refetch. The suite is reporting a real behaviour users can hit: place an order, open the orders page, see the previous order on top.

The decision belongs to product and backend, not to QA. If read-your-own-writes is a requirement, this is a bug and the test is correct as written. If eventual consistency is accepted, the UI should handle it, for example by polling or by using the creation response to render optimistically, and the test should then assert that behaviour. Actions:

- File a backend ticket with the measured window of up to 2 s and the 3-in-50 isolated rate. Ask for the consistency guarantee of GET /orders in writing.
- Quarantine the test on main with the ticket in the annotation, and keep it running in a nightly job so the fix is verified automatically.
- Do not loosen the test with reload-and-retry loops on main. That would convert a product defect into a permanently hidden one.

**login > signs in with valid credentials. Stable.** Ten passes, no action. Treat ten clean runs as a bound rather than a certification: at 95 % confidence it only tells us the true failure rate is below roughly 26 %. Any test that matters more than average should get a repeat-each run before being declared reliable.

## Suite-level recommendations

- Keep retries at 0 on main. It is what made this analysis possible. Enabling retries would have hidden all three flaky tests and the orders bug.
- Enable trace on first failure in CI so the cart question above can be answered from the next failed run rather than by reproduction.
- Require a repeat-each run, at the normal worker count, for every new or modified spec in pull requests. Both interference and timing problems only appear under parallel load.
- Add a lint or review rule against page.waitForTimeout and against tests that mutate seed rows in place. Both patterns produced failures in this sample.
- Quarantine means a test is skipped on main with a linked ticket and still runs nightly. Quarantine without a ticket and an owner is deletion with extra steps.
