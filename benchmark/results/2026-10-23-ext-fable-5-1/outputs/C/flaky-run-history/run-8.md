---
title: The e2e suite fails on main without code changes
slug: e2e-suite-fails-on-main-without-code-changes
article_type: troubleshooting
product_area: CI
audience: Engineering team
plan_availability: None: internal engineering article, no plans apply
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# The e2e suite fails on main without code changes

Ten runs of the e2e suite on commit c0ffee1 failed for 4 different reasons, and only 1 of the 4 failing tests is a plain timing flake. This article tells you which test is which, why it fails, and who should do what.

## What the 10 runs show

All 10 runs failed. Even with the broken profile test removed, only 2 of 10 runs would have passed.

| Test | Failed | Verdict | Owner action |
| --- | --- | --- | --- |
| **profile > saves a new avatar** | 10 of 10 | Broken, not flaky | Fix or revert today |
| **search > filters results by tag** | 4 of 10 | Flaky: shared test data | Isolate the data in tags.spec.ts |
| **cart > updates the total when the quantity changes** | 3 of 10 | Flaky: timing | Replace the fixed wait |
| **orders > shows the latest order first** | 2 of 10 | Flaky: product behaviour | Decide if the 2 s lag is a bug |
| **login > signs in with valid credentials** | 0 of 10 | Stable | None |

Assumption: the other 115 tests in the suite passed in all 10 runs, and every failure in the table used the message shown below.

## profile > saves a new avatar fails every time

**What you see.** Expected "avatar.png", received undefined.

**Why.** A test that fails 10 of 10 times on the same commit is not flaky. It is broken, and so is main. The test reads a value that is no longer there. Assumption: the test reads the file name from the save response, and the field was renamed or dropped on or before c0ffee1.

**What to do.**

1. Assign an owner today and treat main as red until it passes.
2. Bisect to the commit that first failed, then fix the product or the test, whichever changed.
3. Do not tag this test as flaky and do not add retries to it. Retries cannot fix a test that fails every time.

## search > filters results by tag fails when tags.spec.ts runs beside it

**What you see.** Expected 3 results, received 5. Alone, with 1 worker, it passes 20 of 20.

**Why.** Both specs use the seeded tag "summer". tags.spec.ts renames that tag during its own run. With 4 workers, the rename sometimes lands before search.spec.ts filters, so the filter no longer matches and the page shows more results. Assumption: when the tag does not exist, the search ignores the filter and returns all 5 seeded items. This is an order problem, not a timing problem, so no amount of waiting fixes it.

**What to do.**

1. Change tags.spec.ts to create its own tag with a unique name, for example the test title plus the worker index, and rename only that tag.
2. Leave search.spec.ts unchanged. It is the victim, not the cause.
3. Add a rule for the suite: a test never changes seeded data that another test reads. Each test creates what it changes.

## cart > updates the total when the quantity changes times out

**What you see.** Timeout 5000ms exceeded waiting for the cart total to have the text "€58.00".

**Why.** The test selects **+** and then waits 300 ms with a fixed pause before it reads the total. A fixed pause does not wait for anything real. Under 4 workers the page is slower to become interactive, and the click sometimes lands before the page handles it, so the total never changes. Assumption: in the failed runs the received text was the total from before the click, which means the click was lost rather than slow.

**What to do.**

1. Remove the fixed 300 ms wait.
2. Before you select **+**, wait for something that proves the page is ready, such as the control being enabled or the current total being visible.
3. Keep the web-first assertion on the total. It already waits up to 5 s on its own.
4. Run the spec alone 50 times after the change. If it still fails, record the received text and reopen the issue.

```
npx playwright test cart.spec.ts --workers=4 --repeat-each=50
```

## orders > shows the latest order first shows the previous order

**What you see.** Expected "Order #1043", received "Order #1042". Alone, with web-first assertions and a fresh user each time, it still failed 3 of 50.

**Why.** The test is already written well, and it still fails. In the failed runs, GET /orders returned the list without the new order for up to 2 s after the order was created. The product, not the test, is behind. Assumption: the list reads from a cache or a read replica that lags the write.

**What to do.**

1. File a product bug with the backend owner. Ask one question: is a 2 s delay before a new order appears acceptable for a customer?
2. If the answer is no, fix the read-after-write path, for example read from the primary after a write or clear the cache on create. Leave the test as it is so it catches the regression.
3. If the answer is yes, change the test to poll the list for up to 5 s and write the accepted delay in a comment next to the assertion. Do not add a fixed wait.

## login > signs in with valid credentials needs no action

The test passed 10 of 10 times. Keep it as the control case when you compare future runs.

## What to do with the suite as a whole

- Keep retries at 0 until the 3 flaky tests above are fixed. Retries would hide the search and orders problems, and both point at real defects.
- After the fixes, run the whole suite 10 more times on one commit. The target is 10 of 10 passes.
- Collect this before you report a new flake: the run number, the test title, the full failure message, and a run of the spec alone with `--repeat-each=20`. That one run tells you whether the cause is timing, shared data, or the product.

## Assumptions

- The other 115 tests passed in every run.
- The profile test reads the file name from the save response.
- The search returns all items when the filtered tag does not exist.
- The received cart total in failed runs was the pre-click value.
- The orders list reads from a cache or replica that lags the write.

## Related articles

None: no related articles yet.

## Updates

None: first version.
