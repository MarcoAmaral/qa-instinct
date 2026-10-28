---
title: E2E tests fail on some CI runs of the same commit
slug: e2e-tests-fail-on-some-ci-runs-of-the-same-commit
article_type: troubleshooting
product_area: CI
audience: Team member
plan_availability: None: internal engineering article
reading_time: 4 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# E2E tests fail on some CI runs of the same commit

Of the 5 tests that failed on commit c0ffee1, 3 are flaky and need a test fix, 1 is always broken and needs a product or test fix today, and 1 is stable.

A test is flaky when it both passes and fails on the same commit with no code change. All 10 runs below are on c0ffee1 with 4 workers and retries set to 0.

| Test | Failed | Verdict | Owner of the fix |
| --- | --- | --- | --- |
| search > filters results by tag | 4 of 10 | Flaky, shared test data | Test |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky, fixed wait instead of a condition | Test |
| orders > shows the latest order first | 2 of 10 | Flaky, stale read in the product | Test now, product ticket |
| profile > saves a new avatar | 10 of 10 | Not flaky, always broken | Product or test |
| login > signs in with valid credentials | 0 of 10 | Stable | None |

## search: another spec renames the tag this test filters by

The test filters by the seeded tag `summer`. `tags.spec.ts` renames that tag during its own run. With 4 workers the two specs overlap, so the result count depends on which spec reaches the tag first. Alone, with 1 worker, the test passed 20 of 20, which confirms the cause is the shared data and not the search code.

Assumption: the rename in `tags.spec.ts` makes 2 extra items match `summer`, which is why the test receives 5 results instead of 3.

Fix: give each spec its own tag.

1. In `search.spec.ts`, create a tag with a unique name in `beforeEach`, for example `summer-${testInfo.testId}`, and tag 3 items with it.
2. In `tags.spec.ts`, do the same instead of renaming the seeded tag.
3. Delete both tags in `afterEach`.

Do not move the two specs to a serial project. That hides the problem and slows the suite.

## cart: the test waits a fixed 300 ms instead of waiting for the page

The test selects **+** and then waits 300 ms with `page.waitForTimeout(300)`. The 5000 ms assertion timeout on `cart-total` then expires, so the total never became €58.00 at all. A fixed wait cannot cause that on its own, so the click itself is lost on slow runs.

Assumption: on a loaded runner the page has rendered **+** before its handler is attached, so the click does nothing and the total stays unchanged.

Fix: wait for a condition, not for time.

1. Remove `page.waitForTimeout(300)`.
2. Before selecting **+**, wait for the quantity field to show its starting value with `expect(quantity).toHaveValue('1')`.
3. Select **+** and wait for the cart request with `page.waitForResponse` on the cart endpoint.
4. Keep the `toHaveText('€58.00')` assertion as it is.

If the test still fails after this change, the lost click is a product bug and needs a ticket with a trace.

## orders: GET /orders returns the list without the new order for up to 2 seconds

This is the only case where the product causes the flake. Run alone, with web-first assertions and a new user every time, the spec failed 3 of 50. In those runs the orders list did not include the order just created for up to 2 seconds.

Assumption: the list is served from a cache or a read replica that lags behind writes.

Fix in the test now:

1. Wrap the check in `expect(async () => { await page.reload(); await expect(firstRow).toHaveText('Order #1043'); }).toPass({ timeout: 5000 })`.
2. Keep the timeout at 5 seconds so a real regression still fails quickly.

Open a product ticket as well. A user who places an order and opens their list sees the same stale result, so the test is reporting a real problem.

## profile: the field the test reads does not exist

This test failed 10 of 10 and is not flaky. It expects `avatar.png` and receives `undefined`, so the value it reads is missing, not wrong. A test that always fails on main should block merges until it is fixed.

Assumption: the response or page object no longer has the property the test reads, because the avatar save changed shape or was never finished on this commit.

Fix today:

1. Run the test alone with a trace and check where `undefined` comes from.
2. If the product no longer returns the field, fix the product or update the test to the new field name.
3. Do not mark this test as flaky and do not add retries to it.

## login: stable

This test passed 10 of 10. No action.

## Before you re-run the suite

- Keep retries at 0 on main so flakes stay visible.
- Do not quarantine any of the 3 flaky tests. Each has a known fix that takes under an hour.
- Collect a Playwright trace for any new failure before re-running, so the team is not guessing from a message alone.

Assumption: the other 115 tests passed in all 10 runs and need no action.

## Updates

- None: first version.
