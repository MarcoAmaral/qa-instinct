# Flaky-test analysis: e2e suite, commit c0ffee1 (10 CI runs, 4 workers, retries 0)

What was read: the 10-run history, the four failure messages, and the two local repeat runs the team already did (search alone 20/20, orders alone 3/50). Nothing was run for this analysis; every "fails N of M" below is from those sources.

| Test | Fails / runs | Verdict | Cause class | What to do |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10 / 10 | Deterministic failure, not flaky | Not a flake class | Debug, then defect report (test or product). Not a quarantine candidate. |
| search > filters results by tag | 4 / 10 (R2, R4, R7, R10) | Flaky | Order or shared state | Fix the data isolation of `tags.spec.ts` and `search.spec.ts`. Known cause, fix now; quarantine only if the fix misses this sprint. |
| cart > updates the total when the quantity changes | 3 / 10 (R2, R5, R9) | Flaky | Test timing (provisional, see below) | Remove the sleep, wait for the UI to be ready, pull the trace of a failing run. Tag `@flaky` until the trace confirms the class. |
| orders > shows the latest order first | 2 / 10 (R3, R8); 3 / 50 alone | Flaky | Product intermittent defect | File a product defect with the observed frequency, link it, quarantine the test. |
| login > signs in with valid credentials | 0 / 10 | 0 failures in 10 runs | None | Nothing. Ten runs bound the rate; they do not prove zero. |

Assumption: the other 115 tests passed in all 10 runs; only these five rows were given. Assumption: 120 is also what `npx playwright test --list` reports.

Note for the team: with `retries: 0` and the profile test failing in all 10 runs, every one of these 10 builds was red. A permanently red build hides the flakes above, because nobody reads a red build for new signal. Fixing or reporting the profile failure is the first action, before any quarantine.

## Deterministic failure (listed apart)

**profile > saves a new avatar.** Same assertion every run: expected `"avatar.png"`, received `undefined`. Ten of ten is not flakiness; it is a failure that has been on `main` since at least the first of these runs. The message says the property the test reads is absent, which is consistent with either a test defect (wrong property name or wrong response object) or a product defect (upload response no longer returns the file name, or the upload silently fails). One debugging session decides it: open the trace, look at the upload request and its response body. If the response has the file name under another key, fix the test. If the response has no file name, or the upload fails, write the defect report with `/qa-defect` and record the frequency as 10 of 10. Either way, do not tag it `@flaky` or `@quarantine`; a quarantine is for verdicts that change on unchanged code, and this one does not.

What the history cannot show: whether this started at c0ffee1 or earlier. Check the last green run of this test to find the commit that broke it.

## Flaky tests, by cause

**search > filters results by tag.** Class: order or shared state, with direct evidence. Fails 4 of 10 in the suite under 4 workers and passes 20 of 20 alone with one worker, and the team already found the mechanism: `tags.spec.ts` renames the seeded tag "summer", and the search test filters by that same tag. When the two specs overlap on different workers, the search runs against a renamed or half-renamed tag and gets the wrong count. The fix is isolation, not serialisation:

- Each spec owns its data. `tags.spec.ts` creates the tag it renames (unique name per test, created through the API in `beforeEach`, removed in `afterEach`) and leaves the seed alone. `search.spec.ts` creates its own tag with its own three tagged items, so its expected count no longer depends on the seed.
- Do not fix it with `--workers=1`, `test.describe.serial`, or ordering the specs. Those hide the collision and slow the suite.
- Side observation for product: a filter on a tag that no longer exists returned 5 results, not 0. If a non-matching tag silently returns the unfiltered list, that is a separate product question. Not part of the flake.
- Exit proof: run both specs together, `npx playwright test search.spec.ts tags.spec.ts --workers=4 --repeat-each=50`, and record the output. Running `search.spec.ts` alone proves nothing, it already passes alone. Red-green: with a route stub that makes the filter return all items, the test must fail.

**cart > updates the total when the quantity changes.** Class: test timing, provisional. The evidence for it: the only synchronisation before the click is `page.waitForTimeout(300)`, a hard sleep, and the failure rate rises under 4 workers, where a slower page makes a fixed sleep land before the handler is attached. The evidence against stopping there: the failing assertion is `toHaveText`, which polled for a further 5 seconds and never saw "€58.00". So the sleep being too short is not the whole explanation. The likely race is that the "+" click fires before the page's click handler is bound, so the click is lost and the total never changes. That is still a test defect (wait on the page's own ready state, not on time), but a lost update in the product would look the same from the outside.

What decides it, in order:

1. The "Received string" from the three failing runs. Playwright includes it in the `toHaveText` timeout message; it was not pasted. "€29.00" (unchanged) points to a lost click; any other value points elsewhere.
2. The trace of a failing run (`trace: 'retain-on-failure'`, since retries are 0). If the click produced no request, the test clicked too early. If the request went out and the response carries the right total but the DOM did not update, that is a product defect and goes to `/qa-defect`.
3. Then the fix: delete the sleep, wait for the control to be actionable and the cart to be loaded (for example `await expect(total).toHaveText("€29.00")` before the click, which also proves the starting state), click, assert with `toHaveText`. Repeat run: `npx playwright test cart.spec.ts --workers=4 --repeat-each=50`. Red-green: stub the quantity endpoint to return the old total, the test must fail.

Until step 1 and 2 are done, the class stays provisional and the test is tagged `@flaky`, not `@quarantine`.

**orders > shows the latest order first.** Class: product intermittent defect. This is the one case where the test is already right: the team's repeat run used web-first assertions and a new user per run, which rules out timing in the test and shared data, and it still failed 3 of 50. The failing runs showed `GET /orders` returning the list without the just-created order for up to 2 seconds. The page fetches once, renders "#1042" first, and the assertion can poll the DOM as long as it likes; nothing refetches. That is a read-after-write consistency gap in the product (read replica lag, a list cache not invalidated on create, or similar). Actions:

- Write the defect report with `/qa-defect` as a product defect. Observed frequency: 2 of 10 CI runs and 3 of 50 isolated runs, so roughly 1 in 17. Evidence: the stale `GET /orders` response bodies and timestamps from the failing runs.
- Quarantine the test with the defect number in the ledger. Quarantining without the report is exactly the graveyard the protocol exists to prevent: the test is the only thing currently catching this.
- Do not "fix" the test with `expect.poll` around a page reload or a retry. That makes the suite green and leaves the user seeing a stale order list.
- One decision for product: if a stale window after creating an order is accepted behaviour, say so with a bound, in writing. Then it is not a defect, the requirement changes, and the test waits up to that bound by reloading. Without that decision it is a defect.
- Exit: when the product fix lands, the unchanged test must pass `--repeat-each=50` on the fix commit, and must still fail when a route stub serves the stale list. Both outputs go in the ledger row.

## Quarantine proposal and ledger

The team decides; this is a proposal. Rows without an owner and a deadline are not quarantines yet, so the table below is not valid until the team fills those two columns.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| orders > shows the latest order first | Product intermittent defect | DR to be filed via /qa-defect (pending) | to assign | 2026-10-26 | 2026-11-09 (placeholder) | proposed `@quarantine` |
| cart > updates the total when the quantity changes | Test timing (provisional) | none yet; opens only if the trace shows a product cause | to assign | not yet | not yet | `@flaky`, awaiting trace |
| search > filters results by tag | Order or shared state | none (test defect) | to assign | not yet | fix this sprint | `@flaky`, fix in progress |
| profile > saves a new avatar | deterministic, not a flake | DR via /qa-defect if product-side | to assign | n/a | n/a | not quarantined; broken build |

Deadline assumption: the quarantine rule's period could not be read (see below), so the orders row uses a placeholder of one two-week sprint from today. Replace it with the rule's figure.

Share: 1 of 120 tests quarantined now (0.8%), 3 of 120 (2.5%) if cart and search also go in. Whether that crosses the rule's escalation threshold, and who to escalate to, cannot be stated here because the rule is not loaded. Compute it again from `npx playwright test --list` when the tags are applied.

Exclusion: add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs, and add one separate, non-blocking job that runs `--grep @quarantine` on every build, so the orders test turns green on its own the day the product fix lands. Keep `retries: 0`; raising retries would hide the orders defect and the cart race rather than fix either.

What this history cannot show: the received values and traces for the failing runs (nobody kept them, or they were not pasted); which tests shared a worker slot with search or cart in each failing run; any run before these ten, including when the profile test last passed; whether the CI environment is shared with other pipelines; and the real `--list` count. Causes outside the repository, such as a database replica lag setting behind the orders defect, are the product team's to confirm.

Rules not applied: the `qa-rules` skill is not installed, so the `testing-guidelines` rule (quarantine period, escalation threshold and escalation target, exact tag protocol) and the `code-style-qa` rule could not be read. The deadline, the share verdict and the tag steps above follow the skill's description of the rule, not the rule's own text.
