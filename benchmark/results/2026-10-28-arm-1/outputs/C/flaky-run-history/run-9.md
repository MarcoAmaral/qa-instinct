---
title: Fix flaky tests in the e2e suite
slug: fix-flaky-e2e-tests
article_type: troubleshooting
product_area: Testing, CI
audience: Developer
plan_availability: All teams
reading_time: 5 min
related_articles: None: internal technical guide for test maintenance
last_updated: 2026-10-28
---

# Fix flaky tests in the e2e suite

Four tests in the e2e suite show inconsistent pass rates across repeated runs on the same commit. Three are flaky race conditions; one is consistently broken and needs investigation.

## cart > updates the total when the quantity changes

**Symptom:** Test fails 30% of the time. Assertion expects total of "€58.00" but reads "€29.00" (half the expected amount).

**Root cause:** The test uses `page.waitForTimeout(300)` then reads the total immediately. The UI updates asynchronously and 300ms is insufficient; the quantity increment request and price recalculation are racing the assertion.

**Fix:** Replace the fixed timeout with a web-first assertion. Use `page.locator('[data-testid="total"]').toContainText('€58.00')` or similar to wait for the actual value to appear. Playwright will poll until the condition is true or timeout.

## profile > saves a new avatar

**Symptom:** Test fails 100% of the time. Assertion expects "avatar.png" but receives `undefined`.

**Root cause:** This is not flaky; it is consistently broken. The element does not exist or is not populated. Likely causes: wrong selector, broken upload handler, missing fixture data, or the page structure changed since the test was written.

**Fix:** Do not treat as flaky. Investigate: inspect the page to find where the avatar appears, verify the upload handler works, confirm the test fixture includes an avatar file. This is a test or app bug that needs direct debugging.

## search > filters results by tag

**Symptom:** Test fails 40% of the time in the full suite. Assertion expects 3 results but receives 5.

**Root cause:** Test isolation issue, not an app bug. The test uses a seeded tag "summer" which `tags.spec.ts` renames during its own run. When tests run in parallel with 4 workers, the search test sometimes runs after or concurrently with the tag rename, reading stale data. Confirmed: running alone with `--workers=1 --repeat-each=20` passes 20/20.

**Fix:** Reset the "summer" tag to its seeded state before the search test runs, or create a fresh tag per test run. Use a test fixture or `beforeEach` hook to ensure tag state. Alternatively, ensure tag-renaming tests run in isolation or complete before the search suite begins.

## orders > shows the latest order first

**Symptom:** Test fails ~2% of the time. Assertion expects "Order #1043" but receives "Order #1042". When run alone with a new user per run, fails 3/50 (~6%).

**Root cause:** Backend race condition. The test creates a new order and expects it to appear in the list immediately. In ~2–6% of runs, `GET /orders` returns the previous list for up to 2 seconds after order creation, suggesting eventual consistency or replication lag in the database.

**Fix:** Add a wait-for assertion that polls the orders list until the new order appears, with a timeout of 5–10 seconds:

```javascript
await page.locator('[data-testid="order-list"]').getByText('Order #1043').waitFor();
```

Alternatively, investigate the backend: confirm the create endpoint returns only after the order is visible in queries, or add read-after-write consistency guarantees.

## Summary

| Test | Type | Action | Priority |
| --- | --- | --- | --- |
| cart total | Flaky—async race | Replace timeout with web-first assertion | High |
| profile avatar | Broken—not flaky | Debug test/app; fix directly | High |
| search tag | Flaky—test isolation | Reset tag state between runs | Medium |
| orders list | Flaky—backend race | Add poll-wait assertion or backend consistency fix | High |

---

## Updates

None: created 2026-10-28.
