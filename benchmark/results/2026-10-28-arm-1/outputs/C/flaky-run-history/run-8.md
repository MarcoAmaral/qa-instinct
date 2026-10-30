---
title: Fix failing e2e tests in the test suite
slug: fix-failing-e2e-tests
article_type: troubleshooting
product_area: Testing
audience: QA, Developer
plan_availability: None: internal engineering team
reading_time: 4 min
related_articles: None: no related articles yet
last_updated: 2026-10-28
---

# Fix failing e2e tests in the test suite

Some e2e tests fail inconsistently. Find your test below to see what causes it and what to fix.

## Cart: updates the total when the quantity changes

**Symptom:** The test fails 30% of the time. After clicking the quantity increase button, the total shows €29.00 instead of €58.00—exactly half.

**Cause:** The test waits 300 milliseconds with `page.waitForTimeout(300)`, then reads the total once and compares it. The UI update takes longer than 300 milliseconds sometimes.

**Fix:**

1. Replace `page.waitForTimeout(300)` with a web-first assertion.
2. Change `textContent()` to `expect(cartTotal).toContainText('€58.00')`.

Web-first assertions wait for the condition (up to 30 seconds by default) instead of assuming a fixed time is enough.

## Profile: saves a new avatar

**Symptom:** The test fails 100% of the time. After saving, the avatar field reads `undefined` instead of "avatar.png".

**Cause:** This is not flakiness—the feature is broken or the test is wrong. Consistent failure across all 10 runs points to a product issue or incorrect test setup.

**Fix:**

1. Manually test the avatar upload feature in the app right now.
2. If the upload works, check the test setup: does the mock file exist, and does the upload endpoint return the filename?
3. If the feature is broken, create a bug ticket and skip the test until the fix merges.

## Search: filters results by tag

**Symptom:** The test fails 40% of the time in the full suite, but passes all 20 times when run alone with `--workers=1 --repeat-each=20`.

**Cause:** Test isolation failure. The search test seeds a tag named "summer", but tags.spec.ts renames that tag during its own run. When tags.spec.ts runs first, "summer" no longer exists, and the search returns 5 unrelated results instead of 3.

**Fix:**

1. Generate a unique tag name in the test instead of relying on the seeded "summer" tag (for example, `tag_${Date.now()}`).
2. Or isolate the two specs into separate test suites so they do not share seed data.
3. Verify by running `npx playwright test search.spec.ts orders.spec.ts --workers=4 --repeat-each=5` to simulate parallel execution.

## Orders: shows the latest order first

**Symptom:** The test fails 20% of the time. It expects "Order #1043" but receives "Order #1042". When run alone 50 times with a new user each time, it still failed 3 of 50. GET /orders returns the list without the new order for up to 2 seconds after creation.

**Cause:** Backend race condition. The order is created but does not appear in the list endpoint immediately. The lag is longer than the test's default wait time.

**Fix:**

1. Replace the single read with a web-first assertion: `expect(orderList).toContainText('Order #1043')`.
2. If that still fails, the backend needs fixing. Orders should appear in the list endpoint within 100 milliseconds of creation. Create a backend ticket to add synchronous consistency or increase the test timeout while the backend is fixed.

## Next steps

Prioritize fixes in this order:

1. **Profile avatar** (100% failure)—blocks the suite.
2. **Search tag** (40% failure)—isolate test data.
3. **Cart timing** (30% failure)—add web-first assertions.
4. **Orders consistency** (20% failure)—add web-first assertion or fix the backend.

After each fix, run the full e2e suite 5 times on the same commit to confirm the failure rate drops.
