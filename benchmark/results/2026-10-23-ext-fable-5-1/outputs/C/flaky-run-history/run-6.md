---
title: The e2e suite fails on every run of main
slug: e2e-suite-fails-on-every-run-of-main
article_type: troubleshooting
product_area: CI
audience: Engineering team
plan_availability: None: internal article, not plan-dependent
reading_time: 4 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# The e2e suite fails on every run of main

Of the 5 tests in the report, 3 are flaky, 1 is broken on every run, and 1 is healthy. The suite is red on all 10 runs because of the broken test, so fix that one first to get a signal back.

| Test | Failed | Verdict | Who owns the fix |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Not flaky. Broken test or real bug. | Profile feature owner |
| search > filters results by tag | 4 of 10 | Flaky. Shared test data. | Test author of tags.spec.ts |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky. Timing in the test. | Test author of cart.spec.ts |
| orders > shows the latest order first | 2 of 10 | Flaky. Real backend lag. | Backend owner of /orders |
| login > signs in with valid credentials | 0 of 10 | Healthy. No action. | None |

Do not turn on retries to fix any of these. Retries would hide the avatar bug and the orders bug, and both are real.

## profile > saves a new avatar fails on every run

A test that fails 10 of 10 times with the same message on the same commit is not flaky. It is deterministic. The assertion reads the file name and gets `undefined`, so either the avatar is not saved or the test reads a field that no longer exists.

1. Check whether the avatar saves when you do it by hand on c0ffee1.
2. If it does not save, open a bug and treat c0ffee1 as a broken build.
3. If it does save, the test reads the wrong field or the wrong response. Fix the test.
4. Until it is fixed, mark it with `test.fixme` and link the ticket in the annotation. Do not delete it.

## search > filters results by tag fails when tags.spec.ts runs first

The test expects 3 results for the tag "summer", but tags.spec.ts renames that tag during its own run. With 4 workers, the two specs run in parallel and the order changes from run to run. That is why it passes 20 of 20 alone and fails 4 of 10 in CI.

1. Change tags.spec.ts to create its own tag with a unique name, rename that one, and delete it at the end.
2. Keep the search test on the seeded "summer" tag, since nothing else should change seeded data.
3. Add a team rule: a test that changes shared seeded data must create its own copy first.
4. Do not fix this by setting workers to 1. It hides the problem and slows every run.

## cart > updates the total when the quantity changes times out

The test selects **+**, waits a fixed 300 ms, then waits up to 5 s for the total to show €58.00. The total never arrives in 5.3 s, so the update is not slow, it is lost. The most likely cause is that the test selects **+** before the page is ready to handle it, so the click does nothing. Under 4 workers the machine is slower, which makes the gap wider.

Assumption: the trace is not available, so the lost click is the working theory until a trace confirms it.

1. Remove the fixed 300 ms wait. It does not make the test safer, it only makes it slower.
2. Before selecting **+**, wait for a sign that the cart is ready, such as the quantity showing the starting value.
3. After selecting **+**, assert that the quantity shows the new value before asserting the total.
4. Set trace to `retain-on-failure` in the Playwright config so the next failure shows what happened.
5. If the trace shows the click landed and the total still did not update, treat it as a product bug.

## orders > shows the latest order first shows the previous order

The test is correct and the product is wrong. In 3 of 50 isolated runs, GET /orders returned the list without the new order for up to 2 s after it was created. A user who places an order and opens the orders page can see a list without it. Web-first assertions do not help because the page fetches the list once and does not fetch again.

Assumption: /orders reads from a cache or a read replica that lags behind writes. The backend owner should confirm.

1. Open a backend bug: "GET /orders can omit an order for up to 2 s after it is created."
2. Mark the test with `test.fixme` and link the bug. Keep the assertion as it is.
3. Do not add a reload loop or a sleep to the test. That would hide the bug the test found.
4. Remove the `fixme` when the backend returns the new order on the first read after it is created.

## login > signs in with valid credentials is healthy

10 of 10 passed. No action.

## Assumptions

- The other 115 tests in the suite passed on all 10 runs. The report lists only these 5.
- All 4 workers share one database, which is why one spec can change data that another spec reads.
- No one has changed the CI machines between the runs, so the differences come from the tests and the product, not the environment.
