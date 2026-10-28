## Summary

| Test | Failed | Verdict | Action |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Not flaky. Consistently broken. | Treat as a red build. Fix or revert today. |
| search > filters results by tag | 4 of 10 | Flaky. Shared seed data mutated by another spec. | Give each spec its own tag. No quarantine. |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky. Timing race in the test. | Replace the sleep with real readiness waits. |
| orders > shows the latest order first | 2 of 10 | Flaky. Product bug: stale reads after write. | File a backend bug. Bounded wait in the test meanwhile. |
| login > signs in with valid credentials | 0 of 10 | Stable. | Nothing. |

Only runs 1 and 6 had all three flaky tests pass together. Even with the profile test fixed, main would have been red in 8 of these 10 runs. Retries are off, so every one of those flakes blocked the pipeline.

## Findings per test

**profile > saves a new avatar is not flaky.** Flaky means non-deterministic, and this fails identically every time. Received undefined means the test reads a field that is not on the object it got back. Either the save response or profile model changed shape, for example the field was renamed or nested, or the save never completes before the read. Find the first commit on main where it started failing. If the product changed the field, update the test. If not, it is a regression on main and should be reverted or fixed before anything else. Do not quarantine it and do not add retries, because both would hide a real break.

**search > filters results by tag fails because of test pollution.** The test and tags.spec.ts both depend on the seeded tag "summer", and tags.spec.ts renames it. With 4 workers the two specs land in different orders on different runs, so the search test sometimes runs after the rename. The isolated 20 of 20 pass confirms the order dependence rather than clearing the test. One side observation: after the rename, the filter returned all 5 products instead of 0 or 3. That suggests filtering by an unknown tag silently returns the unfiltered list, which is worth a separate product check.

Fix: neither spec should touch the shared seed. Each spec creates its own uniquely named tag and products through the API in a beforeEach and deletes them afterwards. Do not fix it by using one worker, serial mode, or ordering the spec files. Those only hide the coupling and slow the suite. Verify with both specs running together under load:

```
npx playwright test search.spec.ts tags.spec.ts --workers=4 --repeat-each=20
```

**cart > updates the total has a readiness race, and the sleep is a symptom, not the cause.** The error text comes from a web-first assertion that already auto-waits 5 seconds. So the total never reached €58.00 for about 5.3 seconds after the click, and lengthening the sleep or the timeout will not help. The likely cause is a dropped click: the "+" is clicked before its handler is attached, or while a previous cart update is still in flight and the stepper ignores it. Both get worse under CPU contention from 4 workers. The other candidate is a cart shared with another worker, in which case the received value would be a different number rather than the old total. The trace from a failed run tells you which. Keep traces on failure since retries are off.

Fix: delete the fixed wait. Before clicking, wait for a real readiness signal such as the stepper being enabled or the hydration marker your app exposes. Wrap the click in a wait for the cart update response, then keep the existing text assertion. If the cart belongs to a shared user, give the test its own user. Fix it within a day. If that cannot happen, mark it as fixme with a ticket so it stops blocking main, but keep the ticket visible.

**orders > shows the latest order first exposes a product bug, and the test is correct.** The isolated run used web-first assertions and a fresh user per run and still failed 3 of 50. The API itself returned the order list without the new order for up to 2 seconds after creation. That is a read-after-write consistency gap, most likely replica lag, a stale cache, or an asynchronous projection. It is user-facing: a customer who places an order and opens their order list within 2 seconds will not see it. The web-first assertion did not save the test because it retries the DOM, not the fetch. The page loaded a stale list once and the DOM stayed stale.

Action: file a bug against the orders backend. After a POST, a GET for the same user must reflect the write, by reading from the primary, invalidating the cache on write, or returning the created order so the UI can use it directly. Until the fix lands, poll the orders API after creation until the new order appears, capped at 5 seconds, with a comment linking the ticket, and only then open the page. The cap matters: a bigger regression in lag will still fail the test instead of being absorbed. Do not quarantine and do not add retries. If product decides the lag is acceptable, write that SLA down and keep the bounded wait permanently.

## Assumptions and process notes

- The other 115 tests passed in all 10 runs and are omitted from the table.
- 10 runs only reliably catch flake rates above roughly 25 percent. The 115 omitted tests are presumed stable, not proven stable. Run new or changed specs with repeat-each 20 and 4 workers before merge.
- Keep retries at 0 on main. If retries are ever enabled, have the reporter surface Playwright's flaky status separately so a pass on retry never counts as green.
- The 5 results received in the search failure are assumed to be the full seeded product count.
- The profile test is assumed to have passed on an earlier commit. If it has never passed, it is a broken test rather than a regression, and the fix is the same: correct it before merging anything else.
