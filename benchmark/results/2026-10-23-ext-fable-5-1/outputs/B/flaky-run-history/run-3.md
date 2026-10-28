# Flaky test triage for c0ffee1 (10 runs, 4 workers, retries 0)

## Summary

| Test | Fails | Verdict | Owner of the fix |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10/10 | Not flaky. Deterministic failure. Main is red because of this test alone. | Feature team, today |
| search > filters results by tag | 4/10 | Flaky. Cross-spec data interference caused by tags.spec.ts. | Test author of tags.spec.ts |
| cart > updates the total when the quantity changes | 3/10 | Flaky. Test-side timing race, root cause not yet proven. | Test author, with a trace |
| orders > shows the latest order first | 2/10 | Not a flaky test. Intermittent product bug in read-after-write on GET /orders. | Backend team, bug ticket |
| login > signs in with valid credentials | 0/10 | Stable. No action. | None |

Only two of the four failing tests are flaky in the strict sense of "same code, non-deterministic result caused by the test or its environment". The other two are the suite doing its job. Treating all four as "flaky" and adding retries would hide one real regression and one real production bug.

## Per-test analysis

**profile > saves a new avatar. Not flaky.** It fails identically in all ten runs with the received value undefined. A 100% failure rate with a constant message is a deterministic defect, not flakiness, and no retry or quarantine policy applies. The undefined value means the property the test reads does not exist on the object it inspects. Two causes fit equally well, and the next step is the same for both: either the API or the page model renamed or dropped the avatar field, so the product regressed, or the test reads a field that was renamed on purpose, so the test is stale.

Assumption: this test passed on main before c0ffee1. Bisect from the last green run to find the commit. If the product regressed, revert or fix forward and keep the test unchanged. If the field was intentionally renamed, update the test and add the rename to the changelog of the same pull request. Until it is fixed, every CI run on main is red, which trains people to ignore CI and lets the genuinely flaky tests hide behind it. This is the first thing to do.

**search > filters results by tag. Flaky, caused by another spec.** The evidence is complete. It passes 20 of 20 when run alone in a single worker. It fails only in the parallel suite, and it fails when tags.spec.ts has already renamed the shared seeded tag "summer" on another worker. After the rename the filter no longer matches a real tag, the search falls back to an unfiltered list, and the test sees 5 results instead of 3. The failure rate of 40% is just the probability that tags.spec.ts gets scheduled before the search assertion under 4 workers.

The search test is the victim. The defect is in tags.spec.ts, which mutates shared seed data that other tests depend on. Fix it there:

- tags.spec.ts must create its own tag with a unique name, rename that, and delete it afterwards. It must never touch the seed.
- Treat seed data as read-only for the whole suite. Any test that needs to mutate an entity creates that entity itself, ideally through a fixture that generates a unique suffix per test and cleans up in teardown.
- Harden search.spec.ts the same way so it does not depend on the seed either. Creating its own three tagged items makes the expected count self-evident and removes the dependency entirely.

Do not fix this with serial mode or by pinning the two specs to the same worker. That hides the shared-state problem and slows the suite. Do not quarantine the search test; it will go green the moment tags.spec.ts stops mutating the seed.

**cart > updates the total when the quantity changes. Flaky, test-side, cause not yet proven.** The failure message is a retrying web-first assertion that waited the full five seconds and never saw the expected total. That matters because the fixed 300 ms sleep in the test is a smell but cannot be the cause of a five-second timeout; the assertion already retries far longer than the sleep. Something made the total never reach €58.00 at all, not merely reach it late.

Three candidate causes, in order of likelihood. The "+" button is clicked before the client-side handler is attached, so the click is swallowed and the quantity never changes; under four workers the browser and server are slower, hydration takes longer, and the race is lost about one time in three. Second, the cart belongs to a shared user and another spec running in parallel changes the cart contents, so the starting total differs and the expected value is wrong. Third, the cart update has the same read-after-write staleness seen in the orders test, so the page shows the old total after the update.

Assumption: the full report includes the received string. That one line decides it. If the received value is the original total, the click was lost or the update was stale. If it is a different non-starting value, the cart is shared and another test changed it. To confirm:

- Run it alone with `--repeat-each=50 --workers=1`. If it goes green alone, it is parallel interference and the fix is a unique user per test, as for search. If it still fails alone, it is a timing race inside the test or the app.
- Turn on trace retention on failure and look at whether the click produced a cart update request.
- Regardless of the result, delete the hard sleep, assert that the quantity control is enabled or hydrated before clicking, and assert the quantity field shows the new value before asserting the total. That turns one five-second timeout into a precise failure that names the step that broke.

Keep this test running. It is the only one of the four where the root cause is still open, so it goes on the flaky list with an owner and a deadline of one week to close out the investigation.

**orders > shows the latest order first. Not a flaky test; a real intermittent bug.** The team already did the right experiment. Alone, serial, with web-first assertions and a fresh user for every iteration, it still failed 3 of 50, and in those runs GET /orders omitted the order that was just created for up to two seconds. The test has no shared state, no fixed sleeps, and no parallel neighbours, and it still fails. Nothing on the test side remains to fix. The web-first assertion did not rescue it because the page fetches the list once on navigation; retrying the DOM assertion cannot refetch a stale list.

This is a read-after-write consistency gap. The most common sources are reads served from a replica that lags the primary, a response cache that is not invalidated on create, or an asynchronous indexing step. Real users hit exactly this: place an order, open the orders page, and the order is missing. The test caught a production defect.

Actions:

- File a backend bug with the 3-of-50 reproduction and the two-second window. Decide explicitly whether orders must be read-your-writes consistent. If yes, fix the read path, for example by reading from the primary after a write, invalidating the cache on create, or returning the created order in the response and having the page use it.
- Do not add a retry or poll to the test to make it green. That codifies the bug as acceptable behaviour with no one deciding so.
- If the product owner decides eventual consistency is acceptable, the product needs a visible pending state and the test should change to reflect the new spec: reload until the order appears within a bounded window and assert the pending state while waiting. That is a spec change, not a flake fix.
- Link the test to the bug ticket with an annotation. If it blocks merges while the bug is open, move it to a non-blocking quarantine project that still runs on every commit and reports, rather than skipping it. Reinstate it as blocking when the bug is fixed.

**login > signs in with valid credentials. Stable.** Ten of ten with no failures. Ten runs give only moderate confidence; a test with a 10% failure rate would pass all ten about a third of the time. No action is needed, but it should stay in the same ten-run rerun loop as the rest of the suite so that any later drift shows up.

## Suite-level actions

- **Fix profile first.** A permanently red main makes every other signal worthless. Nothing else in this list should wait for it, but it is the only item that is blocking today.
- **Keep retries at 0 on main.** Retries are what let the orders bug and the tags.spec.ts data mutation go undetected elsewhere. If merges need stability, retry only in the quarantine project and keep the blocking project strict.
- **Make seed data immutable and give every test its own data.** The search failure is one instance of a pattern that will recur. Add a fixture that creates a unique user and unique entities per test and tears them down. Audit the suite for other specs that mutate seeded rows.
- **Ban fixed sleeps.** Enable the Playwright ESLint rule that forbids waitForTimeout. It did not cause the cart failure, but it hides whatever did and it will cause others.
- **Retain traces on failure in CI.** The cart investigation is stalled only because there is no trace. One setting change fixes that for every future investigation.
- **Run a flakiness detector on every merge.** Run each changed spec ten times with repeat-each before it lands. Both flaky tests here would have been caught by that gate.
- **Separate the vocabulary.** "Flaky" should mean the test or its environment is wrong. Profile is a regression. Orders is a product bug. Calling all four flaky would have led to retries, and retries would have shipped the orders bug.
