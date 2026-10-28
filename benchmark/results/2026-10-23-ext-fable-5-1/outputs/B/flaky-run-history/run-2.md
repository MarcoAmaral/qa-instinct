# Flaky test analysis: e2e suite, commit c0ffee1, 10 runs

## Verdict

| Test | Failed runs | Verdict | Root cause lives in | Action |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10 / 10 | Not flaky. Deterministic failure | Product or test, undetermined | Treat as a real failure. Fix before anything else |
| search > filters results by tag | 4 / 10 | Flaky. Cross-spec state pollution | tags.spec.ts | Stop tags.spec.ts mutating seed data. Give each spec its own tag |
| cart > updates the total when the quantity changes | 3 / 10 | Flaky. Timing race in the test | Test | Replace the fixed sleep with state-based waits. Capture the received value |
| orders > shows the latest order first | 2 / 10 | Flaky in CI, but a genuine product defect | Product. Read-after-write lag on GET /orders | File a product bug. Keep the test. Do not loosen the assertion |
| login > signs in with valid credentials | 0 / 10 | Stable | None | No action |

Flakiness here means different outcomes on the same commit. By that definition three tests are flaky and one is simply broken. Only one of the three flaky tests has its cause inside the test itself.

Even with the profile test fixed, main would still have been red in 8 of the 10 runs, because at least one of the three flaky tests failed in every run except R1 and R6. That is the cost of leaving these as they are with retries set to 0.

## profile > saves a new avatar

**What the data shows.** It failed in every run with the same message. The expected value is the filename and the received value is undefined. There is no variance, so this is not flakiness and should not be labelled or quarantined as such.

**Likely cause.** Undefined rather than a wrong value usually means the property the test reads no longer exists. Either the API response or page object stopped exposing the avatar field, or the upload now completes asynchronously and the test reads before the field is populated. Both would be deterministic.

**Assumption.** I do not have the result for the previous commit. I assume the test passed before c0ffee1 and this is a regression introduced by the commit or by an environment change that landed with it.

**Action.** Bisect against the previous green commit. If the product changed, it is a blocking bug for main. If the test is reading a removed field, update the test. Do not add retries. Retrying a deterministic failure only costs CI time.

## search > filters results by tag

**What the data shows.** It failed in 4 of 10 runs in CI with 4 workers, and passed 20 of 20 in isolation. The failure is a count mismatch, not a timeout. The combination of isolation stability and parallel instability is the signature of shared-state pollution.

**Root cause.** The test depends on the seeded tag named summer. tags.spec.ts renames that tag during its own run. With 4 workers the two specs sometimes overlap, and whichever runs second sees the other's state. The search test is the victim. tags.spec.ts is the offender. The expected count of 3 against a received 5 suggests the filter falls back to an unfiltered or broader list once the tag no longer matches. That detail is worth confirming when the fix is tested.

**Action.**

- Change tags.spec.ts so it creates its own tag with a unique name and renames that one. Seed data should be treated as read-only by every spec.
- Change search.spec.ts to create its own tagged items in a fixture, so it no longer depends on seed data either. This protects it from the next spec that touches tags.
- Do not fix this by forcing the suite to one worker or by marking the two specs serial. That hides the pollution and will resurface when a third spec touches tags.
- Audit the remaining specs for other writes to seed data. Where one spec mutates shared seed data, there are usually others.

## cart > updates the total when the quantity changes

**What the data shows.** It failed in 3 of 10 runs, always with a timeout waiting for the cart total to show the expected text. The test clicks the increment button, sleeps for a fixed 300 ms, then asserts.

**Root cause.** The fixed sleep is a defect but it is not the direct cause. The assertion itself auto-waits for 5 seconds, so a 300 ms sleep cannot explain a 5 second timeout. Something prevents the total from ever reaching the expected value within 5 seconds in the failing runs. The two plausible explanations are:

- **The click is lost.** The button is visible before its handler is attached, so under 4-worker load the click lands before hydration and the total never changes.
- **The update is slow.** The cart recalculation takes more than 5 seconds under load, which would itself be a performance problem worth knowing about.

The failure message was summarised without the received text, so I cannot distinguish these. If the received value is the original total, the click was lost. If it is an intermediate value, the update is slow.

**Action.**

- Remove the fixed sleep. It adds latency to every run and protects against nothing.
- Wait for a state change that proves the click registered before asserting on the total, for example the quantity field showing the new value, or the response to the cart update request.
- If the click is being lost, wait for the button to be enabled or for a hydration marker before clicking. That is the actual fix for the lost-click case.
- Enable trace on first retry for this spec and keep the received value in the report so the next failure is diagnosable.
- Fix now rather than quarantine. At a 30 percent failure rate it blocks main more than any other test here, and the fix is contained to one spec.

## orders > shows the latest order first

**What the data shows.** It failed in 2 of 10 CI runs. The team already did the right diagnostic work. Run alone 50 times with web-first assertions and a fresh user per run, it still failed 3 times. In those runs the orders list did not include the new order for up to 2 seconds after creation.

**Root cause.** This is not a test problem. The test is correctly detecting that GET /orders can return a stale list after a successful write. That pattern points at a read replica, a cache that is not invalidated on write, or an asynchronous indexing step. If a user places an order and immediately opens their orders page, they can see it missing. That is user-visible.

**Assumption.** I assume the 2 second staleness is not a documented, intended consistency guarantee. If it is, the UI still needs to handle it rather than show an incomplete list.

**Action.**

- File a product bug against the orders API with the 3 of 50 reproduction and the 2 second window. The test output is the evidence.
- Keep the test enabled and keep the assertion strict. Extending the assertion timeout would make CI green by codifying the defect.
- If the team decides the staleness is acceptable, the product should change, not the test. The order confirmation flow should navigate once the order is readable, or the list should refetch until it appears. Then the test can wait on that explicit behaviour.
- Only if the product fix is scheduled and the team wants main green in the meantime, quarantine this test with a link to the bug and a removal date. Do not quarantine it silently.

## login > signs in with valid credentials

Passed 10 of 10. No action. Note that 10 runs can only rule out failure rates above roughly a quarter, so this is evidence of stability, not proof. It is listed here only because it was in the sample.

## Suite-level recommendations

- **Do not turn on global retries.** Every failure in this sample has an identifiable cause. Retries would hide the orders defect and the tags pollution while adding CI time to the deterministic profile failure.
- **Make seed data read-only by convention.** Add a lint or review rule that specs create what they mutate. The search failure is a symptom of a missing convention, not a one-off.
- **Report received values and traces on failure.** The cart failure could have been diagnosed from a single run if the received text and a trace were available.
- **Track flakiness per test across runs on the same commit.** This sample was useful precisely because it was 10 runs on one commit. Keep doing that for suspected flakes before touching the test.

## Assumptions

- The other 115 tests passed in all 10 runs. Only the five tests shown were analysed.
- The profile test passed on the commit before c0ffee1.
- The cart failure message was reported without the received text. The diagnosis above would be narrowed by seeing it.
- The 2 second staleness on GET /orders is unintended.
