---
title: E2E tests fail inconsistently in CI
slug: e2e-tests-fail-inconsistently-in-ci
article_type: troubleshooting
product_area: Testing
audience: Developer
plan_availability: All plans
reading_time: 5 min
related_articles: [flaky-test-patterns, playwright-best-practices]
last_updated: 2026-10-28
---

# E2E tests fail inconsistently in CI

If the same e2e test passes on one CI run and fails on another without code changes, the test is flaky. On commit c0ffee1, four of your 120 e2e tests are flaky. One test is consistently broken, and one test is stable.

## cart > updates the total when the quantity changes

**Symptom:** Fails ~20% of the time. Expected "€58.00", received "€29.00".

**Cause:** The test uses a hard-coded 300ms `page.waitForTimeout()` and reads the total once. The server takes longer than 300ms on some runs, so the DOM still shows the old total.

**Fix:** Replace the hard-coded timeout with a web-first assertion that retries until the expected value appears. Use `expect(locator).toContainText('€58.00')` instead of a fixed wait and manual read.

## profile > saves a new avatar

**Symptom:** Fails 100% of the time. Avatar field is `undefined` instead of "avatar.png".

**Cause:** This test is not flaky; it is consistently broken. The avatar field either does not exist in the DOM, the test is using the wrong selector, or the avatar upload feature is broken.

**Action:** This is not a test quality issue; the feature under test may be broken. Debug the feature first, then verify the test uses the correct selector and waits for upload to complete before reading the field.

## search > filters results by tag

**Symptom:** Fails ~40% of the time. Expected 3 results, received 5.

**Cause:** The test depends on a seeded tag "summer". When this test runs, `tags.spec.ts` also runs in parallel on another worker. That spec renames "summer", leaving behind the old tag data. Running the search test alone passes 20/20 times because no other test renames the tag.

**Fix:** Isolate test data. Each test should use a unique tag name (e.g. `const tagName = 'summer-' + Date.now()`) or restore the tag after renaming it in `tags.spec.ts`. Alternatively, ensure search tests run after tags tests finish, or mock the tag data instead of seeding it in the database.

## orders > shows the latest order first

**Symptom:** Fails ~20% of the time. Expected "Order #1043", received "Order #1042".

**Cause:** The backend takes up to 2 seconds to return a newly created order in the GET /orders response. A fixed wait or one read is not enough. Even the standalone test fails 6% of the time (3 of 50) with the same timing issue.

**Fix:** Use Playwright's web-first assertions with a longer timeout. Change `textContent()` to `expect(locator).toContainText('Order #1043')`, which retries for up to 30 seconds. Or use `page.waitForSelector()` with a condition that checks for the new order, instead of a fixed wait time.

## login > signs in with valid credentials

**Symptom:** Passes consistently (10/10).

**Action:** No action needed. This test is stable.

## Next steps

1. **High priority:** Fix the cart and orders tests. Both fail because of race conditions with hard-coded waits. Replace every `waitForTimeout()` + single read with a web-first assertion (a selector with an expected value that Playwright retries until it matches or times out).

2. **Medium priority:** Fix the search test. Isolate the test data so parallel runs do not interfere. Start with a unique tag name per test run.

3. **Investigate:** The profile test. It is broken, not flaky; debug whether the feature works and whether the test selector is correct.

4. **Verify:** Run the cart, search, and orders tests 20 times each in isolation (`npx playwright test search.spec.ts --workers=1 --repeat-each=20`) to confirm each one passes reliably when no other tests run in parallel. If any fail, you have a feature bug or a test bug that is not a race condition.

---

## Updates

None: no related articles yet
