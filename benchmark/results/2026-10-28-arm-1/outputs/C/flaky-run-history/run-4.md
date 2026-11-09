---
title: Analysis and fixes for flaky e2e tests
slug: flaky-e2e-tests-analysis
article_type: troubleshooting
product_area: Testing
audience: Development team
plan_availability: All plans
reading_time: 4 min
related_articles: None: this is an internal engineering report
last_updated: 2026-10-28
---

# Flaky e2e tests in CI: analysis and fixes

The e2e suite on commit c0ffee1 shows 4 test behaviors across 10 runs: one rock-solid, one consistently broken, and two that fail unpredictably. Below are the tests that matter and what to do with each.

## Solid: "login > signs in with valid credentials"

This test passed all 10 runs. No action needed.

## Critical: "profile > saves a new avatar" (100% failure rate)

This is not a flaky test—it fails every time.

**What's happening:** The test expects to read `avatar.png` but receives `undefined`. This means the avatar upload feature does not work at all, or the test expectations do not match the actual behavior.

**Fix:** This is a product bug, not a test problem. Either fix the avatar upload feature or update the test to match current behavior. Until resolved, skip this test in CI to keep the suite running (`test.skip('saves a new avatar')`).

## High priority: "search > filters results by tag" (40% failure rate)

This test passes in isolation (20 of 20 runs alone) but fails inconsistently when the full suite runs with 4 workers.

**What's happening:** The test uses a seeded tag called "summer". When `tags.spec.ts` runs in parallel (4 workers), it renames the "summer" tag during its own test run. This breaks the search test's assumptions about what data exists.

**Fix:** Instead of relying on pre-seeded global data, create a unique tag within each test run:
- Add a timestamp or random string to tag names (e.g., "summer-1730142545").
- Or: Reset the database state before each test run.
- Or: Run tag-related tests serially (set `test.describe.serial()` or configure workers for that spec).

## Moderate: "cart > updates the total when the quantity changes" (30% failure rate)

The test expects €58.00 but receives €29.00 (half the price). The test waits 300 milliseconds with `page.waitForTimeout(300)`, then reads `textContent()` once.

**What's happening:** A fixed wait of 300ms is not enough. Sometimes the UI update finishes later, and the test reads stale content.

**Fix:** Replace the fixed timeout with Playwright's web-first assertions. Instead of:
```js
await page.waitForTimeout(300);
const total = await page.textContent('.total-price');
expect(total).toBe('€58.00');
```

Use:
```js
await expect(page.locator('.total-price')).toContainText('€58.00');
```

This waits (with a configurable timeout) for the element to contain the expected text, so it will not read stale DOM.

## Low-moderate: "orders > shows the latest order first" (20% failure rate)

The test expects to see "Order #1043" but gets "Order #1042" (the previous order). When this test ran 50 times in isolation, it failed 3 times. In those failures, the GET /orders API returned the list without the new order for 1–2 seconds after creation.

**What's happening:** A race condition. The test creates an order and immediately checks if it appears at the top of the list. The backend takes up to 2 seconds to return the new order (possibly cache invalidation, eventual consistency, or database replication).

**Fix:** Use Playwright's web-first assertions with explicit waits instead of assuming the order appears instantly:
```js
await expect(page.locator('[data-test-id=latest-order]')).toContainText('Order #1043');
```

Or add a retry loop if the assertion fails:
```js
await expect(page.locator('[data-test-id=latest-order]')).toContainText('Order #1043', { timeout: 5000 });
```

This gives the backend time to propagate the order to the read path.

---

**Summary:** One test is a real bug (avatar). One has test isolation issues (search—fix the data setup). Two need better wait strategies (cart and orders—use Playwright's built-in assertions instead of fixed timeouts).
