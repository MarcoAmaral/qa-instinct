---
title: Which e2e tests are flaky on main and what to do with each
slug: flaky-e2e-tests-on-main
article_type: troubleshooting
product_area: CI / e2e suite
audience: Engineers who own the Playwright suite
plan_availability: None: internal engineering article, no plan applies
reading_time: 4 min
related_articles: None: no related articles yet; link from the CI runbook when one exists
last_updated: 2026-10-26
---

# Which e2e tests are flaky on main and what to do with each

Of the 120 e2e tests run 10 times on commit c0ffee1, 3 are flaky, 1 is broken outright, and the rest are stable.

Assumptions: the 5 tests listed are the only ones that failed in any run, so the other 115 passed 10 of 10. The runs used the same CI image and the same seed data. "Flaky" here means the test fails sometimes on an unchanged commit.

## Summary

| Test | Failed | Verdict | Owner of the fix |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky: test timing | Test |
| profile > saves a new avatar | 10 of 10 | Broken, not flaky | App or test |
| search > filters results by tag | 4 of 10 | Flaky: shared test data | Test |
| orders > shows the latest order first | 2 of 10 | Flaky: real app bug | Backend |
| login > signs in with valid credentials | 0 of 10 | Stable | None |

## cart > updates the total: the test asserts before the click has taken effect

The test selects **+**, waits a fixed 300 ms, then waits up to 5 s for the total to read **€58.00**. The total never changes in the failing runs. The most likely cause is that the click lands before the page has attached its handlers, so the click is lost. The fixed wait hides this on a fast machine and fails under 4 workers.

Fix, in the test:

1. Remove the `page.waitForTimeout(300)` call.
2. Before selecting **+**, wait for the control to be enabled, or wait for the cart's first load request to finish.
3. Assert the quantity field shows the new value, then assert the total.

If the click is still lost after step 2, the app should disable **+** until the cart is interactive. Open an app ticket in that case.

## profile > saves a new avatar: this is a failing test, not a flaky one

It failed in all 10 runs with the same message: expected `"avatar.png"`, received `undefined`. The value the test reads does not exist in the response or on the page. Either the upload stopped working or the field was renamed and the test was not updated.

Do not label it flaky and do not add retries. Treat it as a red build:

1. Run the avatar upload by hand on c0ffee1 and check whether the file name appears.
2. If the app is wrong, fix the app. If the field moved, update the test.
3. If neither can happen today, skip the test with a ticket link and a date, so the suite is green for real reasons.

## search > filters results by tag: another spec changes its data

The test expects 3 results for the seeded tag "summer" and gets 5 when `tags.spec.ts` renames that tag in a parallel worker. Alone, with 1 worker, it passed 20 of 20. This is test pollution, not a product problem.

Fix, in the tests:

1. Change `tags.spec.ts` to create its own tag and rename that one. Seed data should be read-only to every spec.
2. If that is not possible this week, make the search test create a unique tag per run and search for it.

Do not fix this by running the whole suite with 1 worker. That hides the next data clash and slows CI for everyone.

## orders > shows the latest order first: the API returns stale data

The test creates an order and expects **Order #1043** at the top but sees **Order #1042**. Run alone 50 times, with web-first assertions and a fresh user each time, it still failed 3 times. In those runs `GET /orders` omitted the new order for up to 2 s after it was created. The test is sound. The API does not guarantee read-your-writes, most likely because the list reads from a replica or a cache.

A customer who places an order and opens the order list within 2 s hits the same problem.

Fix, in two places:

1. Open a backend bug: `GET /orders` must include an order the same user just created. Link it from the test.
2. Until that ships, keep the test enabled and poll the list for up to 3 s using `expect.poll` or `toPass`. Add a comment that the poll exists only for the bug above and must be removed when it is fixed.

## login > signs in with valid credentials: stable

Passed 10 of 10. No action. Keep it as the reference for what a stable test looks like in this history.

## Keep retries at 0

Retries at 0 are what made this analysis possible. Turning retries on would have hidden all 3 flaky tests and the stale orders bug. Leave retries off on main and fix the causes above.

## What to collect before asking for help

- The commit hash and run IDs for the failing runs.
- The full failure message and the trace file for one failed run.
- Whether the test passes alone with `--workers=1 --repeat-each=20`.

## Updates

- 2026-10-26: first version, based on 10 runs of commit c0ffee1.
