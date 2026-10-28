---
title: The e2e suite fails on main without a code change
slug: e2e-suite-fails-on-main-without-a-code-change
article_type: troubleshooting
product_area: CI
audience: Engineer on the e2e suite
plan_availability: None: internal engineering article, no plan applies
reading_time: 5 min
related_articles: None: no related articles in the help center yet, see suggestions at the end
last_updated: 2026-10-26
---

# The e2e suite fails on main without a code change

Ten runs of commit c0ffee1 show 1 broken test and 3 flaky tests. Fix the broken test first, then the 3 flaky tests in the order below.

| Test | Failed runs | Verdict | Cause |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Broken, not flaky | The test reads a field that is never set |
| search > filters results by tag | 4 of 10 | Flaky, shared test data | tags.spec.ts renames the seed tag the test depends on |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky, test timing | The click lands before the page is ready |
| orders > shows the latest order first | 2 of 10 | Flaky, product cause | GET /orders lags behind order creation |
| login > signs in with valid credentials | 0 of 10 | Stable | None |

Even after the profile test is fixed, the 3 flaky tests together would let about 1 run in 3 pass. Do not turn on retries to hide this. Each cause below has a known fix, and retries would hide the orders bug from the product team.

## profile > saves a new avatar fails in every run

This test is not flaky. It fails the same way in all 10 runs, so the feature or the test is broken. `Received: undefined` means the test reads a field that the page or the API no longer returns.

Assumption: the save response or the profile page renamed or moved the avatar file name, and the test still reads the old field.

1. Run the test locally and open the trace to see what the save request returns.
2. If the response has no file name, treat it as a product bug and fix the feature.
3. If the field moved, update the test to read the new field.
4. Find the first commit where this test failed. If it is older than c0ffee1, main has been red for longer than this table shows.

Do not quarantine this test. It is the only one of the 5 that reports a real failure on every run.

## search > filters results by tag fails only in the full suite

The test passes 20 of 20 alone and fails 4 of 10 in the full suite. It expects 3 results for the seeded tag "summer". tags.spec.ts renames that tag during its own run. With 4 workers the spec order changes between runs, so the search test sometimes runs after the rename and gets a different result.

Assumption: when the tag no longer exists, the filter has no effect and all 5 seeded results show.

Fix the spec that changes shared data, not the spec that reads it.

1. In tags.spec.ts, create a new tag in `beforeEach` and rename that tag instead of "summer".
2. Check tags.spec.ts for any other seed row it changes or deletes, and give each one its own created row.
3. Add a rule to the suite README: a spec may read seed data, but it must create any data it changes.
4. Confirm with the full suite at 4 workers, 10 times in a row.

Do not serialise the two specs or pin the worker order. That hides the shared-data problem and slows the suite.

## cart > updates the total when the quantity changes times out

The test selects **+**, waits 300 ms, then waits up to 5 s for the total to read €58.00. In 3 of 10 runs the total never changes. The fixed wait is not the cause, because the assertion already waits 5 s after it, and it is not a fix either.

Assumption: the test selects **+** before the page has attached its click handler, so the click is lost and the total stays at its starting value. Playwright checks that a button is visible, enabled and stable before clicking. It does not check that the page's script has run. Under 4 workers the page takes longer to become interactive.

1. Before you select **+**, assert something that only appears after the page's script has run, such as the starting total. Assumption: the starting total is €29.00.
2. Remove `page.waitForTimeout(300)`.
3. Keep the web-first assertion for €58.00.
4. If it still fails, open the trace and check whether the click sent a request. No request means the click was lost. A request slower than 5 s means the test found a slow endpoint, so file a product bug.
5. Confirm with the full suite at 4 workers, 10 times in a row.

## orders > shows the latest order first shows the previous order

This test fails 2 of 10 in CI and 3 of 50 alone, with a new user for every run and web-first assertions. Test isolation and timing are not the cause. In the failed runs, GET /orders did not include the new order for up to 2 s after it was created.

Assumption: the orders list is read from a replica or cache that lags the write, and the page fetches the list once on load. A web-first assertion then waits on a list that never changes.

This is product behaviour, not test behaviour. A customer who places an order and opens their orders page right away can see it missing.

1. File a product bug for the lag and attach the trace from a failed run.
2. Ask the backend owner whether the lag is accepted. If it is, the page should refetch or the API should read after write, and the test must then match the agreed behaviour.
3. Until the bug is fixed, poll GET /orders with `expect.poll` until it contains the new order, then open the page and assert the order. The test checks ordering, not freshness, so the poll keeps it honest. Put the bug number in a comment on the poll so it is removed with the fix.

## login > signs in with valid credentials

This test passed 10 of 10. Take no action. Use it as the control when you compare future runs.

## Before you call a test fixed

A fix counts when the full suite passes 10 times in a row on CI at 4 workers with retries still at 0. One local `--repeat-each` run is not enough, because the search and cart failures only appear under the full suite's load and ordering.

Quarantine with `test.fixme` and a ticket number only if a fix will take more than a day. The search and cart fixes are each under an hour, so neither needs it.

## Still failing?

Before you ask for help, collect the CI run ID, the worker index, the spec order in that worker from the HTML report, and the trace zip for the failed test.

## Assumptions

- The profile test reads a renamed or moved field. The trace will confirm this.
- The search filter returns all 5 seeded results when the tag does not exist.
- The cart's starting total is €29.00, and the click is lost before the page's script runs.
- The orders list is served from a lagging replica or cache, and the page fetches it once on load.
- Failure counts come only from the 10 runs in the table. Runs before c0ffee1 were not available.

## Related articles

None exist yet. Two articles are worth writing and linking from here:

- Create test data inside a spec instead of changing seed data
- Wait for a page to be interactive in Playwright before clicking

## Updates

- 2026-10-26: first version.
