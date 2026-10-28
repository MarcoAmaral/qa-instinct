---
title: The e2e suite fails on repeated runs of one commit
slug: e2e-suite-fails-on-repeated-runs-of-one-commit
article_type: troubleshooting
product_area: CI
audience: Engineering team
plan_availability: None: internal pipeline, no plan tiers
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# The e2e suite fails on repeated runs of one commit

If the e2e suite fails on some runs of commit c0ffee1 and passes on others, 3 tests are flaky, 1 test is broken on every run, and 1 is stable. This article says why each one fails and what to do with it.

| Test | Failed | Verdict | What to do |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Not flaky. Broken on this commit | Find the regression today. Fix it or skip it with a ticket |
| search > filters results by tag | 4 of 10 | Flaky. Shared test data | Give each spec its own tag |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky. Fixed wait hides a race | Wait for the page to be ready, then assert |
| orders > shows the latest order first | 2 of 10 | Flaky. Product lag | File an API bug. Wait for the API in the test until it is fixed |
| login > signs in with valid credentials | 0 of 10 | Stable | Nothing |

The 3 flaky tests matter more than their counts suggest. Even after the avatar test is fixed, only runs R1 and R6 would have been green. With retries set to 0, 8 of 10 runs stay red because of flakes alone.

## profile > saves a new avatar fails on every run

A test that fails 10 times out of 10 on one commit is not flaky. It is broken. The message says the test expected **avatar.png** and received **undefined**. The field the test reads no longer holds the file name. Either the upload no longer saves it, or the field was renamed. The message cannot tell you which.

1. Run the spec on c0ffee1 on your machine. If it fails there too, the cause is in the code, not in CI.
2. Find the last green run of this test on main and compare the commits in between. If you cannot see it by reading, bisect.
3. If the product is wrong, file a bug and mark the test with `test.fixme` and the ticket link. The pipeline then reports the other tests again.
4. If the test is wrong, update the field or selector it reads.

Do not turn on retries for this test. A retry cannot pass a test that fails every time.

## search > filters results by tag fails when tags.spec.ts runs near it

The test expects 3 results and gets 5. Run alone with 1 worker it passes 20 of 20. The cause is shared seed data. The test filters by the seeded tag **summer**, and tags.spec.ts renames that tag during its own run. With 4 workers the two specs run at the same time or in a different order each run. When the rename lands first, the search returns the wrong list.

1. In search.spec.ts, create a tag with a unique name in `beforeEach`, for example the test id, and tag 3 items with it.
2. In tags.spec.ts, do the same. Rename a tag the spec created, not the seeded one.
3. Remove every use of the seeded **summer** tag from both specs.

Do not fix this by setting workers to 1. That hides the dependency and makes the suite 4 times slower.

## cart > updates the total when the quantity changes times out

The test selects **+**, waits a fixed 300 ms, then expects the total to read **€58.00**. The assertion already retries for 5 s and still times out. So the total never changed. It was not merely slow.

The most likely cause is that the click lands before the page's script has attached its handler, so the click does nothing. This is an assumption. A fixed wait cannot fix that race. It only makes it rarer. The second possible cause is that the server takes more than 5 s to recalculate under 4 workers.

1. Set `trace: 'retain-on-failure'` in the Playwright config and open the trace from the next failure.
2. Check whether the quantity field changed after the click.
3. If the quantity did not change, wait for the page to be ready before the click. For example, wait for the cart's first request to finish, or expect the quantity control to be enabled. Then select **+** and assert the total with `toHaveText`. Delete the `waitForTimeout` call.
4. If the quantity changed but the total did not arrive within 5 s, file a performance bug. Do not raise the timeout beyond what a shopper would wait.

## orders > shows the latest order first shows the previous order

The test expects **Order #1043** and gets **Order #1042**. Run alone 50 times, with a new user per run and web-first assertions, it still fails 3 of 50. So test isolation and the assertions are not the cause.

The cause is in the product. GET /orders returns the list without the new order for up to 2 s after the order is created. A customer who places an order and opens the orders page at once sees the same stale list.

1. File a bug against the orders API. Title it "GET /orders omits a new order for up to 2 s after creation" and attach the repeat-each output.
2. Ask the API owners whether the lag is accepted behaviour or a defect.
3. Until it is fixed, make the test wait for the API before it opens the page. Use `expect.poll` on a request to `/orders` with a 5 s timeout, and assert that the first order is the new one. Then load the page and keep the strict UI assertion as it is.
4. Add a comment with the bug link next to the poll, and remove the poll when the bug closes.

A web-first assertion on the page does not help here. The page fetched the list once and does not fetch it again.

## login > signs in with valid credentials

Passed 10 of 10. Nothing to do.

## Before you change the CI config

Retries would mask the 3 flaky tests and do nothing for the avatar test. At these failure rates, 1 retry still leaves about 1 run in 10 red from the search test alone. Fix the causes above instead, then keep retries at 0 so new flakes surface at once.

## Assumptions

- The other 115 tests passed in all 10 runs.
- The quoted failure messages are complete. The cart message does not show the received text, so the cause is inferred.
- All 4 workers run against one shared environment and one seeded database per run.
- Test names, test ids and the tag name **summer** are used exactly as given.
- No CI runbook or e2e README exists in the help center yet. When one does, it should link to this article, and this article should link back from **Related articles**.
