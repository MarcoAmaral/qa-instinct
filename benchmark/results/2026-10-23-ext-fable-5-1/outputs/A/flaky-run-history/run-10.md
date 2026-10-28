# E2E flakiness analysis for c0ffee1 on main

## Summary

| Test | Fails | Verdict | Root cause | Owner of the fix |
| --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 / 10 | Flaky, test defect | Fixed sleep instead of waiting for the state the click produces | Test |
| profile > saves a new avatar | 10 / 10 | Not flaky, broken | Deterministic failure on this commit | Product or test, needs bisect |
| search > filters results by tag | 4 / 10 | Flaky, test pollution | tags.spec.ts mutates shared seed data that search depends on | Test, in tags.spec.ts |
| orders > shows the latest order first | 2 / 10 | Flaky, product defect | GET /orders is stale for up to 2 s after a write | Product, with a test workaround |
| login > signs in with valid credentials | 0 / 10 | Stable | None | None |

Assumptions: the other 115 tests passed in all ten runs. Spec files are distributed across the 4 workers in a different order each run. The three flaky tests fail independently of each other. Under those assumptions the chance that a run is green is about one in three, which matches the two runs out of ten that had no flaky failure. Every run was red regardless, because of the profile test.

## cart > updates the total when the quantity changes

**What the data says.** Three failures out of ten, no pattern across runs, identical message every time. The assertion is web-first, so it retried for five seconds and the total never became €58.00. That rules out the assertion being slightly early. The page genuinely did not reach the expected state within five seconds.

**Why.** The test sleeps for a fixed time rather than waiting for a condition, so it carries no information about whether the click took effect. The most likely failure path is that the click landed before the quantity control was interactive, for example before hydration or before the initial cart fetch finished, so the click was dropped and the total stayed at its starting value. A slower CI worker under four-way parallel load makes that window wider, which fits the roughly one in three rate.

**What to do.**
- Fix now rather than quarantine. A test that fails one run in three is the biggest single cause of red pipelines after the profile test.
- Delete the fixed wait. Before clicking, assert the starting state, for example that the total shows the single-item price and the "+" button is enabled. After clicking, wait for the thing the click causes, such as the quantity field reading 2 or the response to the update request, then assert the total.
- Open the trace from a failed run to confirm whether the quantity changed. If the quantity did change and only the total lagged, the issue is a slow or lost recalculation in the product and should be filed as a bug instead.

## profile > saves a new avatar

**What the data says.** Ten failures out of ten with the same message. This is not flaky. It is deterministically broken on this commit.

**Why.** The field the test reads is undefined after the save. Either the upload response or the profile state no longer carries the avatar filename, or the test reads a property that was renamed. Both explanations point to a change that landed on or before c0ffee1.

**What to do.**
- Do not label it flaky and do not quarantine it as a flake. Treating a consistent failure as flaky hides a regression.
- Bisect to the commit that first broke it. If the product changed, fix or revert the product. If the API shape changed intentionally, update the test.
- Until that is resolved, mark it with test.fixme pointing at a ticket, so the suite can go green on the other 119 tests and real flakes become visible.

## search > filters results by tag

**What the data says.** Four failures out of ten in the parallel suite, zero failures in twenty isolated runs. The failure is two extra results, not a timeout. That combination is the signature of cross-test interference, not timing inside the test.

**Why.** search.spec.ts filters by the seeded tag "summer" and expects three hits. tags.spec.ts renames that same tag as part of its own flow. With four workers the two files sometimes run concurrently or in the wrong order, and whether search sees three or five results depends on which side of the rename it lands on. The test that fails is the victim. The test that causes it is tags.spec.ts.

**What to do.**
- Fix tags.spec.ts first. It should create its own tag to rename and never touch shared seed data. That stops it from polluting any other spec, not just search.
- Also make search.spec.ts self-sufficient. Have it create its own uniquely named tag and the items that carry it, so it does not depend on seed state at all.
- Do not fix this by forcing a file order or dropping to one worker. That hides the dependency and will come back the next time someone adds a test that touches tags.

## orders > shows the latest order first

**What the data says.** Two failures out of ten in CI and three out of fifty in isolation. The isolated run already used web-first assertions and a fresh user per iteration, so neither assertion style nor data pollution explains it. In the failed iterations the list endpoint returned the old list for up to two seconds after the order was created.

**Why.** This is a product-side read-after-write gap. The order is written, the client requests the list, and the list is served from something that has not caught up yet, such as a read replica, a cache, or an asynchronous index. The page loads once with the stale list, so a retrying DOM assertion cannot help. The test is correctly detecting real behaviour that a user would see as a missing order right after checkout.

**What to do.**
- File a product bug with the observation from the fifty-run experiment. The decision the team has to make is whether read-your-own-writes is a requirement for this endpoint. I assume it is, since a user who lands on the orders page after checkout should see the order.
- While the bug is open, make the test wait for the write to become visible before it navigates. Use expect.poll against GET /orders with a bounded timeout of a few seconds, and leave a comment linking to the bug. This keeps the test running and keeps it meaningful without being red for a known cause.
- When the product fix lands, remove the poll so the test goes back to guarding the consistency guarantee.

## login > signs in with valid credentials

Ten passes out of ten. Nothing to do. It is useful as a control showing the environment itself was healthy across all ten runs.

## Suite-level recommendations

- **Keep retries at 0 on main.** Retries would have turned the cart, search, and orders failures into green runs and nobody would have seen them. If retries are enabled later, use a reporter that records a retried pass as flaky and treats it as a defect to fix.
- **Separate consistent failures from flaky ones in reporting.** The profile test fails every time and was masking how often the three real flakes were hitting. A test that is red in every run of a ten-run sample should be routed to the regression process, not the flake process.
- **Ban shared mutable seed data.** The search failure is the symptom of a general rule being broken. Each spec should own the data it mutates. A short lint or review checklist item catches this cheaply.
- **Ban fixed waits in specs.** The cart test is the only one here using page.waitForTimeout, and it is also the one with the highest flake rate. Treat any new use of it as a review blocker.
