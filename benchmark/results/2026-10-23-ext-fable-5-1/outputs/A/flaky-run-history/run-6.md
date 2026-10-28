# Flaky test triage, e2e suite on c0ffee1

**Summary.** Three of the five tests are genuinely flaky, each for a different reason. One is not flaky at all but broken outright. One is stable and only in the table for comparison. Flaky here means pass and fail on the same commit with no code change.

| Test | Fails / 10 | Verdict | Where the fault is |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 | Flaky, timing race | Test |
| profile > saves a new avatar | 10 | Not flaky, deterministic failure | Test or product, needs a bisect |
| search > filters results by tag | 4 | Flaky, shared test data | Test |
| orders > shows the latest order first | 2 | Flaky, real product bug | Product |
| login > signs in with valid credentials | 0 | Stable | None |

## cart > updates the total when the quantity changes

**What happens.** The test clicks "+", sleeps 300 ms, then asserts the total reads "€58.00". The assertion is web-first and waits a further 5 s. The total still never arrives in 3 of 10 runs. A 5 s window is far longer than any normal cart update, so the update is not slow. It is not happening at all in the failed runs.

**Why.** The most likely cause is that the click lands before the "+" button has a handler attached, so it is swallowed. Under 4 workers the page hydrates later than on a quiet machine. The fixed 300 ms sleep does nothing to protect against this and only hides the race on fast runs. Assumption: the trace will show the click registered on a button with no listener yet. If the trace instead shows the quantity changed but the total did not, this becomes a product bug and should move to the same handling as the orders test.

**Do this.**
- Remove the `page.waitForTimeout(300)` call. Fixed sleeps are never a correct synchronisation point.
- Before clicking, wait for a signal that the cart is interactive, for example an enabled button or a rendered line-item quantity.
- After clicking, first assert the quantity field shows the new value, then assert the total. That splits "click was lost" from "total did not recompute".
- Check the Playwright trace for one failed run to confirm the assumption above before closing it.

## profile > saves a new avatar

**What happens.** Fails on every run with the same message. Expected "avatar.png", received undefined.

**Why.** This is not flakiness and should not be in a flaky-test list. A 10 of 10 failure on one commit is a regression. Received undefined means the test reads a property or field that no longer exists at the point it is read. Assumption: a response shape or field name changed in this commit or a recent one, and either the product stopped returning the filename or the test reads it from the wrong place. Retries, quarantine, or reruns will not change the outcome.

**Do this.**
- Treat main as red for this test. Do not tag it flaky and do not add retries.
- Bisect against the last commit where it passed to find whether the product or the test changed.
- Fix whichever side regressed. If the product dropped the field, that is a user-facing bug and takes priority.

## search > filters results by tag

**What happens.** Fails 4 of 10 in CI with 5 results instead of 3. Passes 20 of 20 when run alone with one worker.

**Why.** Classic test-pollution flake. The test depends on the seeded tag "summer". A different spec, tags.spec.ts, renames that same tag as part of its own run. With 4 workers the two specs sometimes overlap, and whether search sees 3 or 5 results depends on which test got there first. The 60 percent pass rate is just the scheduling luck of the draw.

**Do this.**
- Stop sharing mutable seed data between specs. Each spec should create the tag it needs with a unique name, for example suffixed with the worker index or a random id, and clean it up afterwards.
- Apply the same rule to tags.spec.ts so it renames a tag it created rather than a shared fixture.
- Do not fix this by forcing one worker or serial mode. That hides the coupling and slows every run.
- Audit for other specs that mutate shared seed rows. Where one exists, there are usually more.

## orders > shows the latest order first

**What happens.** Fails 2 of 10 in CI and 3 of 50 in isolation. Isolation already used web-first assertions and a fresh user per run, so the usual test-side causes are ruled out. In the failed runs the orders endpoint returned the list without the just-created order for up to 2 s.

**Why.** This is a read-after-write consistency bug in the product, not a test problem. The test is doing its job and reporting it. Assumption: the orders list is served from a cache, a read replica, or an asynchronously updated index, and the create path does not invalidate or wait for it. A user who places an order and lands on the order list can see it missing for the same 2 s.

**Do this.**
- File a product bug with the trace and the 3 of 50 reproduction. Decide explicitly whether the product promises read-your-writes on this page.
- If it does, fix the product. Read from the primary after a write, invalidate the cache on create, or return the new order in the create response and render from that. Leave the test unchanged so it keeps guarding the contract.
- If the team accepts eventual consistency here, the test must say so. Replace the single assertion with a bounded poll, for example `expect.poll` or `toPass` with a 3 s timeout, and annotate it with the ticket number so the slack is removed when the product changes.
- Do not quarantine it silently and do not add global retries. Either option would hide a bug that real users hit.

## login > signs in with valid credentials

Stable across all 10 runs. No action. It is useful as a control showing the environment itself is not the problem, which supports the test-side and product-side diagnoses above.

## Suite-wide notes

- **Keep retries at 0.** It is the reason these four surfaced with clean data. Turning retries on would have masked cart, search, and orders and left only profile visible.
- **Each flake has a different fix.** Timing race, shared data, and a product consistency bug look identical in a pass/fail table. Only the failure message and an isolated rerun separate them, so keep collecting both for any new flake.
- **Order of work.** Profile first because main is red. Search second because the fix is mechanical and removes a whole class of failures. Orders third because it needs a product decision. Cart last, pending the trace check.
