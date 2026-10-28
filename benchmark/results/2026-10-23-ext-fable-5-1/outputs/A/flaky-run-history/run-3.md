# Flaky-test analysis: e2e suite on c0ffee1 (10 runs, 4 workers, retries 0)

## Summary

| Test | Pass rate | Verdict | Root cause | Action |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 0/10 | **Broken, not flaky** | Avatar not persisted or not returned (`undefined`) | Fix forward or revert today; main is red |
| search > filters results by tag | 6/10 | **Flaky: test isolation** | tags.spec.ts renames the shared seeded tag "summer" while search.spec.ts runs in a parallel worker | Fix the data coupling in the tests; no quarantine |
| cart > updates the total when the quantity changes | 7/10 | **Flaky: race in the test (probably)** | Fixed `waitForTimeout(300)` plus an assertion that still times out at 5 s; the click or the state is being lost | Rewrite the test; escalate to product bug if quantity itself never updates |
| orders > shows the latest order first | 8/10 CI, 47/50 isolated | **Flaky: product bug (read-after-write)** | `GET /orders` returns stale data for up to 2 s after creation | File a backend bug; make the test tolerate it only as a stopgap |
| login > signs in with valid credentials | 10/10 | Stable | n/a | None, keep as control |

Assumptions used throughout: one shared seeded database across all four workers (not a DB per worker), spec files are scheduled onto workers in a non-deterministic order, and the "received" text for the cart failure was not captured.

## Per-test detail

### profile > saves a new avatar — not flaky, deterministic failure

It fails 10 of 10 with the same message. Flakiness means intermittent; this is a straight failure on this commit. `Received: undefined` means the field the test reads does not exist on the object it reads it from. Two candidates:

- **Product regression in c0ffee1**: the save endpoint stopped returning or storing the avatar filename (e.g. a renamed response field or a dropped column in a serializer).
- **Test bug**: the test reads the wrong property path after a legitimate API shape change.

What to do: treat it as a blocking red build, not a flake. Diff c0ffee1 against the last green commit for the profile save path and the response shape. Do not quarantine; quarantining a 100 % failure hides a regression. If it is a product bug, revert or hotfix. If the API shape changed intentionally, update the test in the same PR that changed the shape.

### search > filters results by tag — flaky, cross-spec data coupling

Passes 20/20 alone with one worker, fails about 40 % in CI with four workers. That pattern is the signature of a shared-state collision, and the mechanism is already identified: tags.spec.ts renames the seeded tag "summer" while search.spec.ts is filtering by it. Whether it fails depends on which spec gets scheduled first, which varies run to run. "Expected 3, received 5" is consistent with the filter matching nothing or a different tag and falling through to a broader result set.

What to do, in priority order:

1. **Give each spec its own data.** Both specs should create their own tag with a unique name (for example `summer-${testInfo.testId}`) in a fixture and delete it in teardown. Neither spec should touch the global seed.
2. **tags.spec.ts is the offender, not search.spec.ts.** A test that mutates shared seed data is a bug regardless of who it breaks. Fix the mutation there even if search is also made self-contained.
3. **Do not** mark search.spec.ts serial or move it to a separate project as the fix. That hides the coupling and will resurface the next time anyone adds a test that uses "summer".
4. Add a lint rule or review checklist item: no spec may rename or delete seeded fixtures.

No quarantine needed; the fix is small and the cause is known.

### cart > updates the total when the quantity changes — flaky, race in the test

Fails 30 %. Note the failure message: "Timeout 5000ms exceeded waiting for getByTestId('cart-total') to have text". That is a web-first assertion that already auto-retries for 5 s. So the 300 ms sleep is a smell, but it is not by itself the reason the test fails; the total never reaches €58.00 in roughly 5.3 s. Something upstream of the assertion is wrong. Most likely explanations:

- **Click is swallowed.** The "+" button is rendered before its handler is attached (hydration or a late-bound listener), so the click lands on a dead element and nothing updates. The 300 ms sleep is a tell that someone saw this before and papered over it.
- **Wrong starting state.** If the cart belongs to a shared seeded user, another worker's test can add or remove items, so the correct total is sometimes not €58.00. This would be the same class of bug as the search failure.
- Least likely: the update genuinely takes more than 5 s under four-worker load.

What to do:

1. Remove `page.waitForTimeout(300)`. Fixed sleeps are never correct in Playwright and this one is masking the real cause.
2. Before clicking, wait for the control to be actionable in a meaningful sense: assert the initial quantity and initial total, then click, then `await expect(quantity).toHaveText('2')` **before** asserting the total. This splits the failure: if the quantity assertion fails, the click was lost and it is a product hydration bug; if the quantity passes and the total fails, it is a pricing or network problem.
3. Capture `trace: 'retain-on-failure'` and the received text; the current report does not say what the total actually showed.
4. Use a per-test cart (fresh user or cleared cart in a fixture) so the expected total does not depend on other workers.

Keep it running while this is done; 30 % is tolerable for a few days with the trace capture turned on because the trace is the diagnostic you need.

### orders > shows the latest order first — flaky, but the bug is in the product

This one is different and the team should not file it with the others. It was already re-run with web-first assertions and a fresh user per run, which eliminates test timing and test isolation, and it still failed 3 of 50 (6 %). The observation is precise: after creating an order, `GET /orders` returns the pre-creation list for up to 2 s. That is a read-after-write consistency gap in the backend. Candidates: reads served from a replica that lags the primary, a response cache or CDN TTL on `GET /orders`, or async indexing between the write store and the read model.

This is user-visible behaviour, not just a test artefact. A real user who places an order and lands on the order list can see it missing for two seconds.

What to do:

1. **File a backend bug** with the 2 s window and the 6 % reproduction rate. The right fix is read-your-writes: route the read after a write to the primary, bypass or invalidate the cache for that user on write, or have the order-creation response return the order and have the UI use that without re-fetching.
2. **Stopgap in the test only if the team accepts the 2 s window as product behaviour.** In that case wrap the read in `await expect(async () => { ... }).toPass({ timeout: 5_000 })` or `expect.poll`, and leave a comment linking the bug so the tolerance is removed once the backend is fixed.
3. Do not quarantine. At 6 % with retries 0 it will keep hurting, but it is a real signal and quarantining it would turn a product bug into noise.

### login > signs in with valid credentials — stable

10/10. No action. Useful as a control: it shows the infrastructure and auth path are healthy, which rules out an environment-wide cause for the others.

## Suite-level recommendations

- **Turn on `retries: 1` in CI** but configure the reporter to flag "flaky" (passed on retry) separately from "passed". Retries should make the build green while fixes land; they should not hide that a test needed retrying. Keep `retries: 0` locally and for the repeat-each investigations.
- **Enable `trace: 'retain-on-failure'`** suite-wide. Two of the four failures could have been diagnosed from the first failing run with a trace.
- **Stop sharing mutable seed data across workers.** Two of the four problem tests trace to shared state or likely do. Either seed per worker (`workerIndex`-scoped data) or make every test create and clean up what it touches.
- **Ban `page.waitForTimeout` by lint.** It appears in the cart test and there are probably others.
- **Separate "always fails" from "sometimes fails" in triage.** profile was listed alongside the flaky tests, but a 0/10 result is a broken build and needs a different response (revert or fix now) from a 70 % test (fix this week).
