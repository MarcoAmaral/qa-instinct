---
title: e2e suite fails on main with no code change
slug: e2e-suite-fails-on-main-with-no-code-change
article_type: troubleshooting
product_area: CI
audience: Developer
plan_availability: None: internal engineering article
reading_time: 4 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# e2e suite fails on main with no code change

If the e2e suite fails on a commit that already passed, 3 tests are flaky, 1 test is broken on every run, and the rest are stable.

This analysis covers 10 runs of commit c0ffee1 on main, with Playwright, 4 workers and retries set to 0. Assumption: the 115 tests not listed in the report passed in all 10 runs.

| Test | Failed | Verdict | Action |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Broken, not flaky | Fix the regression |
| search > filters results by tag | 4 of 10 | Flaky: shared test data | Give each spec its own tag |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky: fixed sleep before the click | Wait for the control, then assert |
| orders > shows the latest order first | 2 of 10 | Flaky: API returns stale data | File a product bug, poll in the test for now |
| login > signs in with valid credentials | 0 of 10 | Stable | None |

With 3 independent flaky tests at these rates, a run is fully green about 1 time in 3. The profile test alone made every one of the 10 runs red.

## profile > saves a new avatar fails every run

The test expects "avatar.png" and receives undefined in all 10 runs. A test that fails the same way every time is not flaky. Something on main returns no file name, in the app or in the test.

Assumption: a recent commit changed the field the test reads, and the test was not updated.

1. Find the last commit where this test passed, with `git bisect` or the CI history.
2. Fix the app if users lose the avatar name, or fix the test if only the field name changed.
3. Do not quarantine this test. It reports a real failure on main.

## search > filters results by tag fails with other specs running

The test passes 20 of 20 alone and fails 4 of 10 with 4 workers. It filters by the seeded tag "summer", and tags.spec.ts renames that tag during its own run. When the two specs overlap, the search finds 5 results instead of 3.

The cause is shared test data, not timing. Running with 1 worker would hide it and slow the suite.

1. In search.spec.ts, create a tag with a unique name in `beforeEach` and search for that tag.
2. In tags.spec.ts, rename a tag the spec creates itself, not a seeded one.
3. Search the suite for other specs that change seeded data and apply the same rule.

## cart > updates the total when the quantity changes times out

The test selects **+**, waits a fixed 300 ms, and then waits up to 5 s for the total to read "€58.00". The 5 s wait is already a web-first assertion, so the total never changed. The most likely reason is that the select lands before the page has attached its handlers, so the increment is lost.

Assumption: the page hydrates after load and the **+** control is visible before it works.

1. Remove the `page.waitForTimeout(300)` call.
2. Before the select, assert the starting total, for example `await expect(total).toHaveText("€29.00")`.
3. Assert that **+** is enabled, then select it.
4. Keep the `toHaveText("€58.00")` assertion as the only wait after the select.

If the test still fails after this change, record a trace with `--trace on` and check whether the select reached the handler.

## orders > shows the latest order first shows the previous order

The test creates an order, opens the list and expects "Order #1043" first. In 2 of 10 CI runs and 3 of 50 isolated runs, GET /orders returned the list without the new order for up to 2 s after creation. The test already uses web-first assertions and a fresh user, so the test is not the cause.

This is a product behaviour. A user who places an order and opens their orders page can see the same stale list.

1. File a bug against the orders API. Include the request IDs and the 2 s delay from the repeat run.
2. Until the API is fixed, poll GET /orders with `expect.poll` until the new order appears, then open the page.
3. Add a comment linking the bug so the poll is removed when the API is fixed.

Assumption: the delay comes from a read replica or a cache. The backend team can confirm.

## login > signs in with valid credentials

Stable in 10 of 10 runs. No action.

## Keep retries at 0 until these are fixed

Turning on retries would hide the 3 flaky tests and the broken profile test behind a green badge. Keep retries at 0 until the 4 fixes above land, then consider `retries: 1` on CI only, with the flaky status reported on the run.

## Before you mark any other test as flaky

Collect these before changing the test:

- The run IDs where it failed and passed on the same commit.
- The result of `npx playwright test <spec> --workers=1 --repeat-each=20`.
- The failure message, to check it is the same on every failure.

A test that fails alone with the same message every time is broken, not flaky.

## Labels assumed

- The quantity control in the cart is labelled **+**.
- The cart total uses the test id `cart-total`.
- Order titles appear as "Order #1043".
