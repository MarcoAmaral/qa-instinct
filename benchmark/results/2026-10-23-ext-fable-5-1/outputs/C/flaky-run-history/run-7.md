---
title: e2e tests fail on main with no code change
slug: e2e-tests-fail-on-main-with-no-code-change
article_type: troubleshooting
product_area: CI
audience: Developer
plan_availability: None: internal engineering article
reading_time: 4 min
related_articles: None: no related articles yet
last_updated: 2026-10-26
---

# e2e tests fail on main with no code change

Four of the 5 tests you asked about fail on commit c0ffee1 with no code change, but only 3 of them are flaky. One is a real, deterministic failure and one is a real backend bug that the test is reporting correctly.

The table shows the verdict for each test over the 10 runs.

| Test | Failures | Verdict | Owner of the fix |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Not flaky. Broken. | App or test code, today |
| search > filters results by tag | 4 of 10 | Flaky. Test pollution. | Test code |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky. Timing in the test. | Test code |
| orders > shows the latest order first | 2 of 10 | Not flaky. Real race in the API. | Backend |
| login > signs in with valid credentials | 0 of 10 | Stable. | Nobody |

Assumption: the other 115 tests in the suite passed in all 10 runs. If any did not, send their history and messages for the same treatment.

## profile > saves a new avatar fails every run

A test that fails 10 of 10 times on the same commit is not flaky. It is broken, and it should block merges the way any failing test does.

The message says the test expected the string "avatar.png" and received undefined. Assumption: the test reads a property or test ID that the product no longer returns, most likely the file name in the save response or in the avatar element. Either the product stopped returning it, which is a bug, or the test reads the wrong name, which is a test bug.

What to do:

1. Run the test once locally with the trace viewer on and look at the response or element the assertion reads.
2. If the file name is missing from the product, fix the product and keep the test unchanged.
3. If the product renamed the field, update the test to the new name.
4. Do not quarantine it. A quarantined test with a 100 percent failure rate hides a real regression.

## search > filters results by tag fails when another spec runs first

This test passes 20 of 20 times alone with 1 worker. In CI with 4 workers it fails 4 of 10 times. That is test pollution, not a product bug.

The test filters by the seeded tag "summer". The spec tags.spec.ts renames that tag during its own run. With 4 workers the order of the two specs changes from run to run. When tags.spec.ts gets there first, the filter no longer matches the 3 seeded items and the page shows all 5.

What to do:

1. Give each spec its own data. In search.spec.ts, create a tag with a unique name in a beforeEach, for example `search-<test id>`, and tag the 3 items with it.
2. In tags.spec.ts, create and rename a tag of its own instead of the seeded one.
3. Do not fix this by setting workers to 1 or by ordering the specs. Both hide the shared-state problem and slow every run.

## cart > updates the total when the quantity changes times out after a fixed sleep

This test fails 3 of 10 runs with a 5 second timeout waiting for the total to read "€58.00". The failure is in how the test waits, not in the product.

The test clicks "+" and then calls `page.waitForTimeout(300)` before asserting. The assertion itself already waits up to 5 seconds, so the sleep is not what makes it fail. The sleep hides the real race. Assumption: the click sometimes lands before the "+" button has its handler attached, so the click is lost and the total never changes. A fixed sleep neither prevents that nor detects it.

What to do:

1. Remove the `waitForTimeout(300)` call.
2. Before clicking, wait for the page to be ready in a way the product can show, for example wait for the quantity field to be enabled or for the cart's load request to finish.
3. After the click, assert the quantity first, for example `expect(quantity).toHaveText("2")`, then the total. The first assertion tells you if the click was lost; the second tells you if the price calculation is wrong.
4. If the quantity assertion still fails after these changes, the product is dropping early clicks and that becomes a bug for the cart team.

## orders > shows the latest order first finds a real race in the API

This test fails 2 of 10 runs in CI and 3 of 50 runs alone. Running alone with web-first assertions and a fresh user for each run rules out the test and rules out pollution. The product is the cause.

In the failing runs, GET /orders returned the list without the new order for up to 2 seconds after the order was created. The UI sorted what it got and showed "Order #1042" instead of "Order #1043". That is read-after-write inconsistency. Assumption: reads go to a replica or a cache that lags the write.

What to do:

1. File a backend bug with the 3 of 50 figure and the 2 second lag. The test is doing its job; do not rewrite it to retry until the order appears.
2. Have the backend return the new order on the next read, for example by reading from the primary for the user who just wrote, or by invalidating the cache on write.
3. Until the fix ships, mark the test with `test.fixme` and the bug link so the suite stays green and the test is not forgotten. Remove the mark when the bug closes.
4. If the orders team decides a 2 second lag is acceptable behaviour, write that down and then let the test poll for up to 3 seconds. Only do this with a written decision.

## login > signs in with valid credentials is stable

Ten passes out of 10. Leave it alone. It is listed here so nobody adds it to a quarantine list by mistake.

## Keep retries at 0

Retries 0 is what let you see these failure rates. Turning retries on would have turned the search and cart flakes into green runs and left the orders race undetected. Keep retries at 0 on main and treat each new intermittent failure with the same split: alone versus with workers, same message versus different message.

## Assumptions made in this article

- The 115 tests not listed passed in every run.
- The profile test reads a file name from a response or element that is now missing or renamed.
- The cart click is lost before the button handler is attached. The suggested assertions will confirm or refute this.
- The orders API reads from a replica or cache that lags the write.
- No team has yet written a flaky-test policy. If one exists, its quarantine rules win over the ones here.

## Updates

- 2026-10-26: first version.
