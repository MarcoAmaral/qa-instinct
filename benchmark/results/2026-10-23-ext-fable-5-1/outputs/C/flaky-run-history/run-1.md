---
title: The e2e suite fails on and off on commit c0ffee1
slug: e2e-suite-fails-on-and-off-on-commit-c0ffee1
article_type: troubleshooting
product_area: CI
audience: Engineer
plan_availability: None: internal engineering note, not tied to a plan
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# The e2e suite fails on and off on commit c0ffee1

Three tests are flaky, one test is broken rather than flaky, and one is stable. Each needs a different fix.

## What the 10 runs show

| Test | Failed | Verdict | Do this |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Not flaky. It fails every time. | Treat as a red build. Fix today. |
| search > filters results by tag | 4 of 10 | Flaky. Another spec changes its data. | Give each spec its own tag. |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky. The test races the page. | Replace the fixed wait. |
| orders > shows the latest order first | 2 of 10 | Flaky. The product lags its own writes. | File a bug, then poll in the test. |
| login > signs in with valid credentials | 0 of 10 | Stable. | Nothing. |

The other 115 tests are not listed. Assumption: they passed 10 of 10.

## profile > saves a new avatar fails every run

This test is not flaky. It fails 10 times out of 10 with the same message, so the cause is fixed, not random. The assertion reads a value that is `undefined`.

Assumption: commit c0ffee1 renamed the field or test ID the test reads, or avatar upload is broken at this commit. Either way, main is red on every run.

1. Run the test once with a trace and look at the page after the upload.
2. If the avatar is shown, update the selector or field name in the test.
3. If the avatar is not shown, treat it as a regression. Fix the code or revert the commit.

Do not add retries and do not quarantine this test. A test that fails every time is a signal, not noise.

## search > filters results by tag shares a tag with tags.spec.ts

The test filters by the seeded tag "summer". With 4 workers, tags.spec.ts sometimes renames that tag before search.spec.ts reads it, so the filter matches the wrong rows. Alone, the test passed 20 of 20, which confirms the cause is shared data, not the test logic.

1. In search.spec.ts, create a tag with a unique name in `beforeEach` and delete it in `afterEach`.
2. In tags.spec.ts, rename a tag the spec created itself, never a seeded one.
3. Run both specs together with `--workers=4 --repeat-each=20` and confirm 0 failures.

Do not fix this by setting `--workers=1` or by marking the specs serial. That hides the shared data and slows the whole suite.

## cart > updates the total when the quantity changes races the page

The test selects **+**, sleeps 300 ms, then waits up to 5 s for the total to read "€58.00". The assertion already waits, so the sleep is not the problem by itself. The total never reaches "€58.00" within 5 s, which means the click did not take effect.

Assumption: under 4 workers the page is slower, and the click lands before the page's script attaches the handler. The click is lost.

1. Remove `page.waitForTimeout(300)`.
2. Before the click, assert the state that proves the page is ready, for example that the total shows the price for 1 item. Assumption: that is "€29.00".
3. Select **+**.
4. Assert that the quantity reads 2, then that the total reads "€58.00".

If the test still fails, open the trace and check whether the click registered. If the app drops clicks before it is ready, users lose them too. That is an app bug, and the test should stay red until it is fixed.

## orders > shows the latest order first reads a stale list

This test failed 2 of 10 in CI and 3 of 50 alone, with web-first assertions and a new user each run. So test order and worker count are not the cause. In the failing runs, `GET /orders` returned the list without the new order for up to 2 s after it was created.

Assumption: the list reads from a replica or cache that lags the write. A user who places an order and opens the orders page within 2 s sees the same stale list.

1. File a bug against the orders API for read-after-write consistency. The product owner decides whether a 2 s lag is acceptable.
2. Until the bug is fixed, make the test wait for the list to include the new order with `expect.poll` or `toPass`, with a 5 s limit. Add a comment with the bug link.
3. When the bug is fixed, remove the poll and confirm 50 of 50 with `--repeat-each=50`.

Do not skip or quarantine this test. It found a real product gap.

## login > signs in with valid credentials is stable

It passed 10 of 10. Nothing to do. A sample of 10 shows the failure rate is low, not that it is zero.

## For the whole suite

- Keep `retries: 0` on main. A retry hides the search and orders failures.
- Set `trace: 'retain-on-failure'` so a failed run leaves a trace without a retry.
- Give every spec its own data. Shared seed data is the usual cause of failures that only appear with several workers.
- Count a test as fixed only after 0 failures in 20 runs with 4 workers on the fix commit.

## Before you re-run or ask for help, collect

- The run number and the worker that ran the failing test.
- The trace file for the failing test.
- The list of specs that ran on the same worker just before it.

## Assumed labels

- **+** is the quantity button in the cart.
- The total for 1 item in the cart test is "€29.00".
- `cart-total` is the test ID the test reads.

## Related articles

- None: no related articles yet. No existing article needs to link here.
