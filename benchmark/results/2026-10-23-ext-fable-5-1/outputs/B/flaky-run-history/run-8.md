# Flaky-test analysis: e2e suite, commit c0ffee1, 10 runs

**Bottom line.** Of the five tests in the table, two are flaky because of test design (cart, search), one is intermittent because of a real backend bug (orders), one is a deterministic failure that is not flaky at all (profile), and one is stable (login). Not one of the ten runs was green. Even ignoring the profile test, only runs 1 and 6 passed, so main is effectively red and nobody can trust a failed run right now.

Assumptions, stated once: the other 115 tests passed in all ten runs. All four workers share one test database and one seeded data set. Spec files run in parallel across workers in non-deterministic order, which is Playwright's default. The cart failure message is from a web-first `toHaveText` assertion with the default 5 s timeout.

| Test | CI failures | Verdict | Root cause | Owner of the fix |
| --- | --- | --- | --- | --- |
| cart > updates the total | 3 / 10 | Flaky, timing or lost interaction | Total never reaches expected value within ~5.3 s; cause not yet proven | Test author, possibly frontend |
| profile > saves a new avatar | 10 / 10 | Not flaky, broken | Avatar field is undefined every time | Feature owner |
| search > filters results by tag | 4 / 10 | Flaky, test pollution | tags.spec.ts renames the shared seeded tag "summer" | Both spec authors |
| orders > shows the latest order first | 2 / 10 (3 / 50 isolated) | Intermittent, real product bug | GET /orders is stale for up to 2 s after creation | Backend |
| login > signs in | 0 / 10 | Stable | None | None |

## Per-test findings

**cart > updates the total when the quantity changes.** The assertion is a web-first `toHaveText`, so it already retries for 5 s. The fixed 300 ms sleep before it is a smell, but it is not why the test fails. The real finding is that the total never showed "€58.00" at any point in roughly 5.3 s, which in 3 of 10 runs is too long to be ordinary slowness. Three explanations fit, and the trace will separate them:

- The "+" click landed before the page was interactive, so the handler never ran and the quantity never changed. This is the most common cause of this exact signature and is more likely under 4-worker CPU contention, which slows hydration.
- The quantity did change but the total did not, which points at a frontend race such as a stale response overwriting a newer one. That would be an application bug, not a test bug.
- The backend recalculation was simply slow under load. Unlikely at this frequency, but cheap to rule out.

Actions: enable `trace: 'retain-on-failure'` for this spec and look at whether the quantity field changed in the failed runs. Remove the sleep. Assert the quantity updated before asserting the total, so the failure message tells you which step broke. If the click is being lost, wait for a signal that the page is interactive, such as the button being enabled by the app after hydration, rather than adding a longer sleep. If the quantity changes and the total does not, hand it to frontend as a bug. Until then, keep it in the blocking suite only if the trace work happens this week; otherwise quarantine it with a ticket.

**profile > saves a new avatar.** Ten failures out of ten is a deterministic failure, and calling it flaky would hide a regression. "Received: undefined" means the avatar property is absent from whatever object the test reads, not that it has the wrong value. Either the response shape changed, the upload is silently failing in CI, or the test reads a field that no longer exists. Actions: take it out of the flaky bucket entirely. Check whether it passes locally on c0ffee1. If it passes locally, the difference is the environment, most likely the fixture file or upload storage in CI. If it fails locally, bisect to the commit that broke it and fix or revert. This is a blocking defect on main and should be treated with that urgency.

**search > filters results by tag.** This is classic test pollution and the data proves it: 20 of 20 pass alone with one worker, 4 of 10 fail in the full suite. tags.spec.ts renames the seeded "summer" tag that search.spec.ts depends on. Whether search fails depends only on whether tags.spec ran first or concurrently on another worker, which is random. The "received 5" rather than "received 0" is worth a separate look: it suggests the search endpoint silently ignores an unknown tag and returns everything. That is a product behaviour question for the search owner, not a test problem, but it would also make a real customer-facing bug invisible to this test.

Actions: fix the polluter first. tags.spec.ts should create its own tag with a unique name per test and rename that, never a shared seeded record. Then make search.spec.ts self-sufficient as well, by creating the tag and tagged items it needs in a `beforeEach` so it has no dependency on seed state. Do not fix this with serial mode, a single worker, or test ordering. Those hide the dependency and cost you parallelism for every other test. Retries would also "fix" it, and that would be the wrong lesson.

**orders > shows the latest order first.** This one is different in kind. The isolated run already uses web-first assertions and a fresh user per run and still fails 3 of 50, and the recorded cause is that GET /orders returns a list without the new order for up to 2 s after creation. That is a read-after-write consistency gap in the backend, such as a read replica, a cache, or an async index. The test is doing its job: a real user who places an order and opens their order list can see it missing. The reason the CI rate is higher than the isolated rate is that the gap grows under load.

Actions: file a backend bug with the 3 of 50 evidence and the 2 s window, and have the backend owner decide whether this is a defect or accepted eventual consistency. If it is a defect, fix it there and leave the test alone. If it is accepted, the UI must handle it, for example by refreshing the list, and only then should the test be changed to poll with `expect.poll` or `toPass` across reloads. Do not weaken the test to a reload loop before that product decision, because it would mask the bug. Meanwhile, move this test to a non-blocking quarantine project linked to the ticket so it stops blocking merges without being forgotten.

**login > signs in with valid credentials.** Stable across all ten runs. No action. It is a useful control showing the environment itself is not the problem.

## Suite-level actions

- Keep `retries: 0` on main. These ten runs were only diagnosable because retries were off. If you need retries for merge throughput, add them in a separate project and report every retried test as a flake, not as a pass.
- Add a quarantine project that runs but does not block, with an expiry date per test and a linked ticket. Put orders in it now, and cart if the trace work does not land promptly. Search and profile should not be quarantined, because one has a known fix and the other is a real regression.
- Turn on `trace: 'retain-on-failure'` globally. Two of the four failures here would have been diagnosed from a single trace instead of ten reruns.
- Add a lint or review rule against `page.waitForTimeout` in specs. It did not cause the cart failure, but it is the pattern that produces the next one.
- Audit other specs for mutations of shared seed data. The search and tags collision is unlikely to be the only one in 120 tests, and it will surface again as a different pair the next time file order shuffles.
- Define "flaky" for the team as "different outcomes on the same commit with no environmental change". By that definition profile is not flaky and orders is a flaky product, not a flaky test. Labelling correctly decides who fixes it.
