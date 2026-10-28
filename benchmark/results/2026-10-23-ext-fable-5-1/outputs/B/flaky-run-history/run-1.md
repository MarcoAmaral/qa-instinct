## Summary

Four of the five tests fail intermittently or always on c0ffee1. Only one of the four is a plain test-code problem. One is a deterministic regression that the noise has been hiding, one is test pollution between spec files, and one is a genuine product race that the test is correctly catching.

| Test | Failed runs | Verdict | Root cause | Action |
| --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky, test bug | Fixed sleep instead of a readiness wait; the "+" click races page readiness | Rewrite the wait, keep the test |
| profile > saves a new avatar | 10 of 10 | Not flaky, real failure | Avatar is never persisted or returned; fails identically every run | Treat as a blocking defect on main |
| search > filters results by tag | 4 of 10 | Flaky, test pollution | tags.spec.ts renames the shared seeded tag "summer" that this test depends on | Give each spec its own data |
| orders > shows the latest order first | 2 of 10 in CI, 3 of 50 alone | Flaky, product bug | GET /orders returns a stale list for up to 2 s after creation | File a product bug, quarantine with a ticket link |
| login > signs in with valid credentials | 0 of 10 | Stable | None | None, keep as a control |

Even with the profile regression fixed, only runs 1 and 6 would have been green. Retries are off, so nobody has been seeing a green main for this commit, which is how the profile failure was able to blend in.

Assumptions: all workers share one seeded database. The orders page fetches the list once on load and does not poll. The cart failure message does not state the received text, and I assume the total simply stayed at its previous value rather than landing on an intermediate one. Ten runs give a rough rate only, so the percentages below are indicative, not precise.

## Findings

**profile > saves a new avatar is not flaky.** It fails in every run with the same assertion: expected "avatar.png", received undefined. A test that fails deterministically with identical output across ten runs is a broken feature or a broken test, not an intermittent one. Received undefined means the field is missing from the response or page model, so either the save path no longer writes the avatar or the read path no longer returns it. Do not quarantine and do not retry. Find the commit that introduced it by bisecting backwards from c0ffee1, assign it to the owning team, and treat main as broken until it passes. If investigation shows the test is reading a renamed field rather than a real regression, fix the test, but the product should be the first suspect.

**cart > updates the total when the quantity changes is a test-side timing bug.** The test clicks "+", sleeps a fixed 300 ms, then asserts the total. The assertion itself has a 5 s window and still timed out, so the total never changed at all, which points to the click being lost rather than the recalculation being slow. The most common reason is clicking a button before its handler is attached while the page is still hydrating, and the sleep is a sign someone already tried to paper over that race. Under four workers CI is slower, so the 300 ms guess fails more often. Remove the fixed sleep. Before clicking, wait on a real readiness signal such as the button being enabled or the initial cart request having completed. After clicking, assert the quantity field first with a web-first assertion, then the total. That split also makes a future failure tell you whether the click or the calculation was lost. Verify with:

```
npx playwright test cart.spec.ts --workers=4 --repeat-each=50
```

**search > filters results by tag is test pollution, not a product problem.** It passes 20 of 20 alone and fails only when run alongside the rest of the suite. tags.spec.ts renames the seeded "summer" tag, so the result depends on which worker reaches which spec first. The fact that it returns more results than expected rather than fewer suggests the rename makes extra items match or drops the filter entirely, which is worth a glance but does not change the fix. The fix belongs in both specs. tags.spec.ts should create its own tag and rename that, never a shared seed. search.spec.ts should create its own uniquely named tag and the records that carry it, so it cannot be affected by any other test. Do not fix this by forcing serial execution or dependency ordering, since that hides the coupling and slows the suite. Verify by running both specs together under parallelism:

```
npx playwright test search.spec.ts tags.spec.ts --workers=4 --repeat-each=20
```

**orders > shows the latest order first is a real product bug that the test is catching.** This test is already written the way we want: web-first assertions and a fresh user per run. It still fails alone at a lower rate, and the failing runs show GET /orders omitting an order for up to 2 s after it was created. That is a read-after-write consistency gap, most likely a read replica, a cache, or an asynchronous index. The failure rate roughly triples under four workers, which fits a lag that grows under load. A user who places an order and lands on the orders page would hit the same thing. File a product bug against the orders service and the orders page. The right product fix is either to serve the list from the primary for the creating user immediately after a write or to have the page refetch or optimistically insert the new order. Until that lands, quarantine the test with an annotation that links the ticket so main can be green without losing the record. Do not loosen the assertion or add a longer timeout, because that would hide the bug. If product decides eventual consistency is the intended contract, the page must refetch and the test should poll up to the agreed bound, but that is a product decision to record, not a test shortcut.

**login > signs in with valid credentials is stable.** It passed in all ten runs and nothing needs to change. It is useful as the control that confirms the environment itself was healthy during every run.

## Suite-level recommendations

- **Fix the ordering.** Profile first, because main is red and may be shipping a broken feature. Then search and cart, since both are test-only fixes and remove 70% of the noise. Then orders, which is blocked on a product change.
- **Add a pollution guard.** Any spec that mutates seeded data should create its own records. A short lint or review rule for "never rename or delete a seeded fixture" would have prevented the search failure.
- **Ban fixed sleeps.** Replace page.waitForTimeout in tests with web-first assertions or explicit readiness waits. A grep across the suite will find other copies of the cart pattern.
- **Make quarantine visible.** Use a tagged annotation with a ticket link rather than skip, and review the quarantine list weekly so it does not become a graveyard.
- **Retries are a safety net, not a cure.** Keeping retries at 0 was the right call for diagnosis. After the fixes above, one retry on CI with Playwright's flaky status reported in the dashboard is reasonable so that new flakes surface without blocking merges. Turning retries on before fixing these four would have hidden the profile regression and the orders consistency bug.
- **Track pass rate per test.** The tool that produced this table should run on every main commit. A test that drops below 100% over a rolling window gets a ticket automatically, before the team learns to ignore red.
