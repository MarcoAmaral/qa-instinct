---
title: E2E tests failing intermittently
slug: e2e-tests-failing-intermittently
article_type: troubleshooting
product_area: Testing
audience: Developer
plan_availability: All plans
reading_time: 5 min
related_articles: None: no related articles yet
last_updated: 2026-10-28
---

# E2E tests failing intermittently

Several e2e tests fail unpredictably on the same commit (c0ffee1), indicating timing issues, test isolation problems, or race conditions in the application.

## cart > updates the total when the quantity changes

**Symptom:** Expected total is €58.00 but the test receives €29.00. This happens in 3 of 10 runs.

**Cause:** The test waits for a hard-coded 300ms with `page.waitForTimeout(300)` before reading the total. Under load, 300ms is not enough time for the application to recalculate and render the new total.

**Fix:**

1. Replace the hard-coded delay with a web-first assertion.
2. Use `page.locator('[data-testid="total"]').toContainText('€58.00')` or equivalent; Playwright polls until the condition is true (default timeout 30 seconds).
3. Remove `page.waitForTimeout(300)`.

## profile > saves a new avatar

**Symptom:** Expected avatar filename "avatar.png" but received `undefined` in all 10 runs.

**Cause:** The avatar upload is failing completely. This is not a flaky test—the feature is broken.

**Fix:**

1. Verify the file upload endpoint returns the filename in the response.
2. Check that the form field name and file path in the test match the upload handler.
3. Test the upload manually in the browser to confirm the bug exists outside the test harness.
4. Fix the application code, not the test.

## search > filters results by tag

**Symptom:** Expected 3 results but received 5. The test passes every time when run alone with 20 repeats, but fails in 4 of 10 full suite runs.

**Cause:** Test isolation issue. The `tags.spec.ts` file renames the seeded "summer" tag during its run. If `search.spec.ts` runs after `tags.spec.ts`, it finds 5 results (the tag is renamed, so the filter behaves differently).

**Fix:**

1. Add a cleanup hook to `tags.spec.ts` that resets the "summer" tag to its original name after each test.
2. Or assign each test its own unique seed tag so they do not interfere with each other.
3. Or enforce test order by renaming files (`0-search.spec.ts`, `1-tags.spec.ts`).

## orders > shows the latest order first

**Symptom:** Expected "Order #1043" but received "Order #1042". In a 50-repeat run of this test alone, it fails 3 times. In those failures, GET /orders omits the new order for up to 2 seconds after POST /orders succeeds.

**Cause:** Race condition. The POST /orders succeeds, but the order is not yet queryable via GET /orders. The test reads the list too soon.

**Fix:**

1. Add a web-first assertion after creating the order: `page.locator('[data-testid="order-list"]').getByText('Order #1043').waitFor({ state: 'visible' })`.
2. Or use a loop in the test to poll GET /orders until the new order appears, with a maximum wait of 5 seconds.
3. If possible, add a server-side check: wait for the order to be persisted and indexed before responding to POST /orders.

## login > signs in with valid credentials

**Symptom:** This test passes in all 10 runs.

**Cause:** No issue.

**Fix:** None.

---

**Assumption:** The failure messages shown are the same across all runs of each test, indicating deterministic bugs triggered by timing or test order, not truly random flakiness.

## Related articles

None: no related articles yet
