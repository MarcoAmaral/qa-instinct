---
title: e2e tests fail on some runs of the same commit
slug: e2e-tests-fail-on-some-runs-of-the-same-commit
article_type: troubleshooting
product_area: CI
audience: Engineer
plan_availability: None: internal engineering article, no plan applies
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# e2e tests fail on some runs of the same commit

Of the 5 tests that failed in 10 runs of commit c0ffee1, 3 are flaky, 1 is broken on every run, and 1 is healthy.

| Test | Failed | Verdict | Cause | What to do |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Broken, not flaky | The saved file name is never returned | Fix the test or the product now; do not retry or skip |
| search > filters results by tag | 4 of 10 | Flaky | tags.spec.ts renames the seeded tag while this spec runs | Give tags.spec.ts its own tag |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky | The click lands before the page is ready; a fixed wait hides it | Replace the fixed wait with a readiness check |
| orders > shows the latest order first | 2 of 10 | Flaky | The orders API returns a stale list for up to 2 s | Raise a backend bug; reload until the order appears |
| login > signs in with valid credentials | 0 of 10 | Healthy | None | None |

The sections below are in order of how often each test fails.

## profile > saves a new avatar fails on every run

A test that fails 10 of 10 times with the same message is not flaky. It is broken. The received value is undefined, so the test reads a property that the page or the save response no longer has. Either the product stopped returning the file name after a save, or the field was renamed and the test was not updated.

1. Treat this as a red build on main, not as a flaky test. Do not add a retry and do not skip it.
2. Run the spec alone with tracing on and check what the save request returns.
3. If the product no longer returns the file name, fix the product. If the field was renamed, update the test.
4. If the test also fails on earlier commits, find the first failing commit with `git bisect`.

## search > filters results by tag fails when tags.spec.ts runs at the same time

This test passes 20 of 20 times alone with 1 worker and fails 4 of 10 times in the suite. That pattern means another test changes shared data. Both specs use the same seeded database, and with 4 workers the two files run side by side in a different order each run. When tags.spec.ts renames the "summer" tag first, the filter finds no tag with that name and the page shows all 5 unfiltered results.

1. Change tags.spec.ts so it creates its own tag and renames that one. It must never change seeded data.
2. Optionally, have search.spec.ts create its own tag with a unique suffix and tag 3 items with it, so the test owns everything it reads.
3. Do not fix this by dropping to 1 worker or by restoring the name in an afterEach hook. Restoring still leaves a window where both specs overlap.
4. Confirm the fix with the full suite at 4 workers, repeated 10 times.

## cart > updates the total when the quantity changes times out

The assertion is already web-first and waits up to 5 s, so the fixed 300 ms wait is not what causes the timeout. It only hides the real problem. In the failing runs the total never reaches €58.00 within 5 s of the click, which means the click was lost or the update stalled. The most likely reason is that the "+" control is visible before the page has attached its handler, so Playwright clicks too early. Load from 4 workers widens that window.

1. Remove `page.waitForTimeout(300)`.
2. Before clicking "+", wait for a signal that the page is interactive. If the app has no such signal, add one, for example a disabled state on the quantity control until the page is ready, or a data attribute set after hydration.
3. Keep the web-first assertion on the total.
4. Run the spec with `--repeat-each=50 --workers=4` and check the trace of any remaining failure. If the trace shows the click registered and the total still stalled, the cause is a slow price update, and the fix moves to the product.

## orders > shows the latest order first shows the previous order

This test still fails 3 of 50 times alone, with a new user per run and web-first assertions, so neither test interference nor the assertion style is the cause. The orders API returns the list without the new order for up to 2 s after the order is created. That is read-after-write lag in the backend, most likely a cache or a read replica. A web-first assertion cannot help, because the page fetches the list once on load and the DOM never changes.

This is a product behaviour as well as a test problem. A customer who places an order and opens their orders page can see the old list for 2 s.

1. Raise a backend issue for the stale read and decide with the product owner whether a 2 s delay is acceptable.
2. Until the backend is fixed, make the test reload the page until the order appears, with a bounded timeout:

```ts
await expect(async () => {
  await page.reload();
  await expect(page.getByTestId('order-row').first()).toHaveText('Order #1043');
}).toPass({ timeout: 10_000 });
```

3. Do not widen a fixed timeout instead. It makes every run slower and still fails when the lag is longer.
4. When the backend is fixed, remove the reload loop and return to a plain assertion.

## login > signs in with valid credentials is healthy

This test passed 10 of 10 times. No action is needed.

## While you fix them

- Keep the 3 flaky tests running. Tag them so the team can track them, and fix them within the sprint. Skipping them hides regressions in cart, search and orders.
- Set `retries: 1` with `trace: 'on-first-retry'` on main so each flake leaves a trace. Playwright reports a pass on retry as flaky, not as passed, so the count stays visible.
- Before closing any of the 4 tickets, run the spec with `--repeat-each=50 --workers=4`. This reproduces the suite conditions better than a run with 1 worker.

## Assumptions

- All 10 runs used the same seeded database, shared by all 4 workers.
- The differences between runs come from worker scheduling and machine load, not from code or infrastructure changes.
- The other 115 tests passed in all 10 runs.
- The cart page renders the "+" control before its handler is attached.
- The search page shows the unfiltered list when the requested tag does not exist.
- The avatar test fails the same way on every machine, not only in CI.
