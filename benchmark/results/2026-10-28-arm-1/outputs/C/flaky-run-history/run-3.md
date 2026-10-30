---
title: E2e tests fail intermittently in CI
slug: e2e-tests-fail-intermittently-in-ci
article_type: troubleshooting
product_area: QA
audience: Developer
plan_availability: All plans
reading_time: 4 min
related_articles: []
last_updated: 2026-10-28
---

# E2e tests fail intermittently in CI

When you run the e2e test suite multiple times on the same commit, some tests pass sometimes and fail other times. This flakiness makes it hard to trust the results. The causes differ for each test; each has a different fix.

## Test data isolation (affects: search > filters results by tag)

**Symptom:** The test fails 40% of the time in full suite runs, but passes 20 of 20 times when run alone.

**Why it happens:** The test uses a seeded tag named "summer". The tags.spec.ts test renames this tag during its run. With 4 workers in CI, both tests run in parallel; the rename interferes with the search test's expectation.

**Fix:** Stop reusing seeded data. Create a unique tag per test run using a timestamp or random string. This prevents one test from changing data another test depends on.

## Timing race condition (affects: cart > updates the total when the quantity changes)

**Symptom:** The test fails 30% of the time. After clicking the quantity button, it reads the total as €29.00 instead of €58.00.

**Why it happens:** The test waits 300ms then reads the DOM once. That delay is not always enough for the browser to finish updating.

**Fix:** Replace the hard-coded delay with a web-first assertion. Remove `page.waitForTimeout(300);` and let Playwright retry the assertion until the DOM updates. Playwright respects the page's actual timing, not a guessed delay.

## Backend consistency (affects: orders > shows the latest order first)

**Symptom:** The test fails ~20% of the time. It expects Order #1043 but sees Order #1042. Detailed testing found that GET /orders sometimes omits the newly created order for up to 2 seconds.

**Why it happens:** The backend has a race condition or cache lag. The order is stored but the read endpoint does not immediately reflect it.

**Fix:** Add polling in the test. After creating an order, poll GET /orders every 500ms for up to 5 seconds until the new order appears. Alternatively, add an explicit backend check that the order is queryable before the creation endpoint returns.

## Feature is broken (affects: profile > saves a new avatar)

**Symptom:** This test fails 100% of the time, not intermittently. It reads the avatar field as `undefined` instead of `avatar.png`.

**Why it happens:** This is not flakiness. The feature does not work or the element is not where the test expects it.

**Fix:** Verify the feature works in a browser. Check that the file input exists, the upload completes, and the DOM shows the new avatar. Once the feature works, the test will pass. Do not skip this test; file a ticket to fix the feature.

## Test is healthy (no action needed: login > signs in with valid credentials)

This test passes 10 of 10 runs.

## To confirm a test is flaky

Run it 20 times locally to see if it fails:

```
npx playwright test <test-name> --repeat-each=20
```

If it passes every time locally but fails in CI, the flake is environmental (machine load, database latency, or network timing, not the test itself).

## When to skip a test

Never skip a test as a permanent fix. Skipped tests hide bugs. Use `test.skip()` only when the feature is known broken and you have filed a ticket.
