---
title: CI Test Flakiness Analysis — e2e Suite
slug: ci-test-flakiness-analysis-e2e
article_type: reference
product_area: Testing & CI
audience: Engineering team
plan_availability: Internal
reading_time: 4 min
related_articles: None: this is an internal test analysis report
last_updated: 2026-10-28
---

# CI Test Flakiness Analysis — e2e Suite

Analysis of 10 CI runs of the e2e test suite (120 tests, 4 workers, no retries) on commit c0ffee1.

## Tests by Status

| Test | Pass Rate | Status | Action |
| --- | --- | --- | --- |
| login > signs in with valid credentials | 10/10 (100%) | Stable | Monitor; no action needed. |
| cart > updates the total when the quantity changes | 7/10 (70%) | Flaky | Fix: replace hard wait with web-first assertion. |
| search > filters results by tag | 6/10 (60%) | Flaky | Fix: isolate test data; do not share seeded tags. |
| orders > shows the latest order first | 8/10 (80%) | Flaky | Fix: wait for expected order in results, not wall-clock time. |
| profile > saves a new avatar | 0/10 (0%) | Broken | Investigate: not flaky; consistently fails. Real bug. |

## Flaky Tests: Details and Fixes

### cart > updates the total when the quantity changes (7/10 pass)

**Why it fails:** The test clicks "+", waits exactly 300 ms with `page.waitForTimeout(300)`, then reads the total once. The 300 ms timeout is arbitrary and shorter than the time required for the DOM to update on a slow run or under load.

**What to do:**  
Replace the hard wait with a web-first assertion that waits for the expected value to appear:

```javascript
// Before (flaky):
await page.waitForTimeout(300);
const total = await page.locator('total-selector').textContent();
expect(total).toBe('€58.00');

// After (stable):
await expect(page.locator('total-selector')).toContainText('€58.00');
```

Web-first assertions wait up to 30 seconds (configurable) for the element to match, so they absorb small variations in DOM update timing.

---

### search > filters results by tag (6/10 pass)

**Why it fails:** The test uses a seeded tag named "summer". When `tags.spec.ts` runs before `search.spec.ts` in the same CI run, it renames or deletes "summer", causing the search to return unfiltered results (5 items) instead of the tagged subset (3 items). The test passes 20/20 when run alone because no other test pollutes the tag data.

**What to do:**  
Use unique tag names per test run to avoid collisions:

```javascript
// Before (flaky):
const tag = 'summer'; // shared state

// After (stable):
const tag = `summer-${Date.now()}-${Math.random()}`;
```

Alternatively: clean up test data (delete all tags) at the start of `tags.spec.ts`, or mock the tag API so one test's changes do not affect another's.

---

### orders > shows the latest order first (8/10 pass)

**Why it fails:** The test creates an order, then immediately reads the order list and expects the new order to appear first. In 3 of 50 runs (when repeated alone with a new user each time), the GET `/orders` endpoint returned the list without the newly created order for up to 2 seconds. This is a backend eventual-consistency or write-propagation delay.

**What to do:**  
Replace immediate assertion with a web-first assertion that waits for the expected order to appear in the list:

```javascript
// Before (flaky):
const firstOrder = await page.locator('order-list').first().textContent();
expect(firstOrder).toContainText('Order #1043');

// After (stable):
await expect(page.locator('order-list').first()).toContainText('Order #1043', { timeout: 5000 });
```

Set timeout to at least 3 seconds to account for backend latency (observed up to 2 seconds, plus margin).

---

## Broken Test: Not Flaky

### profile > saves a new avatar (0/10 pass)

**Status:** Consistently fails in every run. Not flaky.

**Failure:** The test expects the avatar field to contain "avatar.png", but it is undefined.

**What to do:**  
This is a real bug, not a test instability. Investigate:

1. Does the avatar upload API return the file name in the response?
2. Is the avatar file stored in the database after upload?
3. Is the test waiting long enough for the file to be written?

Check recent changes to the avatar upload endpoint and profile schema. This test failure should be treated as a blocker, not a flakiness issue.

---

## Summary and Next Steps

- **Immediately:** Fix the three flaky tests by adding web-first assertions (cart, orders) and test data isolation (search). These fixes are low-risk and will stabilize CI.
- **In parallel:** Investigate and fix the avatar upload bug (profile test). This is a real defect, not a test issue.
- **Monitor:** The login test is stable and requires no changes.
