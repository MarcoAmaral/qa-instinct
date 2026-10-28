## Verdict

Flaky means it fails nondeterministically on the same commit. Three of the five tests are flaky, one is simply broken, and one is fine.

| Test | Failed runs | Classification | Action |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Not flaky. Deterministic failure | Fix now. It should block main |
| search > filters results by tag | 4 of 10 | Flaky. Test pollution between specs | Fix test data isolation |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky. Timing, root cause not yet confirmed | Fix the wait strategy and capture a trace |
| orders > shows the latest order first | 2 of 10 | Flaky. Exposes a real backend consistency gap | File a backend bug. Bound the wait in the test |
| login > signs in with valid credentials | 0 of 10 | Stable | Nothing |

With profile fixed and nothing else changed, the chance of a fully green run is still roughly one in three (0.7 × 0.6 × 0.8). The failures do not cluster by run, so they are independent problems rather than one bad CI machine.

## profile > saves a new avatar

**What is happening.** It fails identically every run, so this is not flakiness. The assertion reads a property that is undefined. Either the API response no longer carries the avatar filename, or the test reads a field that was renamed. Assumption: no retries, no network, and no shared state are involved, because the result never varies.

**What to do.** Treat it as a regression on main, not a flaky test. Check whether the product response changed or the test's field name is stale. Either way, fix it today. Do not quarantine it, because quarantining a deterministic failure hides a probable product bug.

## search > filters results by tag

**What is happening.** The test asserts on the seeded tag "summer", and tags.spec.ts renames that same tag during its own run. With four workers, whichever spec gets to the tag first decides the outcome. Twenty green runs in isolation confirm the test itself is correct. This is a shared-data race, not a product bug.

**What to do.** Make each spec own its data. tags.spec.ts should create a uniquely named tag in a fixture and rename that, never the seed. search.spec.ts should likewise create its own tag or assert on a tag no other spec touches. Do not fix this by forcing serial mode or a fixed spec order. That hides the coupling and slows the suite. Once the data is isolated, remove any quarantine the same day.

## cart > updates the total when the quantity changes

**What is happening.** The assertion is a proper web-first one with a five second timeout, and it still expires. So the fixed 300ms sleep is wasteful but not the cause. The total is never reaching the expected value within the window. Assumption, since the received text is not in the report: the most likely cause is the "+" click landing before the page's handlers are attached under four-worker load, so the click is dropped and the total never changes. A slower alternative is the recalculation request taking more than five seconds under contention.

**What to do.**

- Enable `trace: 'retain-on-failure'` so the next failure shows what the total actually said.
- Remove the sleep. Assert the quantity field shows the new value before asserting the total. That splits the diagnosis: if the quantity assertion fails, the click was lost and the test needs to wait for interactivity. If quantity updates but the total does not, the app's recalculation is the bug and it goes to the product team.
- Keep it in the blocking suite while you do this. It is a one-sitting change.

## orders > shows the latest order first

**What is happening.** The isolated run already used web-first assertions and a fresh user per repetition, and it still failed three of fifty. The orders endpoint returned a list without the just-created order for up to two seconds. The web-first assertion cannot help here because the page fetches the list once on load and the DOM never changes. This is a read-after-write gap in the backend, most likely a replica read or an uninvalidated cache. The test is doing its job by catching it.

**What to do.** Decide, as a product question, whether a two second lag after creating an order is acceptable. Assumption: it is not, since the customer sees the same stale list. File a backend bug for read-your-writes consistency on orders after creation. In the test, poll the orders API for the new order before navigating to the page, with a tight bound of around three seconds, so a regression beyond that still fails loudly. Do not add Playwright retries to this test. That would turn a real customer-visible defect into a green run.

## login > signs in with valid credentials

Stable across all ten runs. No action.

## General

Keep retries at zero for now. The data above was only possible because retries were off, and turning them on would have masked search and orders entirely. Revisit a retries setting of one only after the three fixes above have landed and you have another ten clean runs on the same commit.
