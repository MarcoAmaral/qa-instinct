# Flaky Test Analysis Report

## Summary
Of the 5 tests reviewed, **3 are flaky**, 1 is consistently broken, and 1 is stable.

---

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Flakiness:** 70% pass rate (7/10 runs)  
**Root Cause:** Fixed timeout inadequacy  
The test uses `page.waitForTimeout(300)` before reading the cart total—a hardcoded 300ms wait that assumes the cart update DOM will be complete by that point. This is a race condition: the quantity increment is still in flight 30% of the time.

**Recommendation:**  
Replace the fixed timeout with a **web-first assertion**. Instead of sleeping then reading once, wait for the final total value to appear:
```
await page.waitForSelector('text=€58.00'); // or use locator().toContainText()
```
This eliminates the arbitrary timing assumption and makes the test deterministic.

---

### 2. search > filters results by tag
**Flakiness:** 60% pass rate (6/10 runs)  
**Root Cause:** Test data pollution from parallel execution  
This test expects 3 results when filtering by the "summer" tag, but gets 5 when run with the full suite. Running it solo 20 times passes 100%. The culprit is `tags.spec.ts`, which **renames the "summer" tag** during its own test run. When both run in parallel (Playwright's 4 workers), the tag state is corrupted mid-test.

**Recommendation:**  
Implement **test data isolation**:
- Use a unique, randomly-named tag per test run (e.g., `summer_${uuid()}`)
- Or reset the "summer" tag state in a `beforeEach` hook
- Or separate tag mutations into their own isolated worker

This is a critical issue: **tests must not modify shared reference data** that other tests depend on.

---

### 3. orders > shows the latest order first
**Flakiness:** 80% pass rate (8/10 runs); ~6% failure rate when repeated 50 times solo  
**Root Cause:** Backend eventual consistency / race condition  
The test creates an order and immediately checks if it appears first in the list. The GET /orders endpoint occasionally returns a stale list (missing the new order for up to 2 seconds). This is a real backend issue: the order write and the subsequent read are not synchronized.

**Recommendation:**  
Two options:
1. **Short term:** Upgrade the test to use **web-first assertions with retry logic**. Replace single `textContent()` reads with:
   ```
   await page.waitForSelector('text=Order #1043'); // implicit 30s retry with backoff
   ```
2. **Long term:** Fix the backend. The orders API should either use a consistent write-read pattern, add a `createdAt` sort guarantee, or include a version/ETag to detect staleness. File a backend ticket.

For now, adopt option 1—it's a pattern that tolerates normal API latency.

---

## Non-Flaky Tests

### profile > saves a new avatar
**Status:** Consistently broken (0/10 passes)  
**Root Cause:** Real bug, not flakiness  
The avatar is not being saved or returned (receives `undefined`). This is a legitimate failure, not a race condition.

**Recommendation:**  
File a bug against the avatar upload feature. This test is correct; the feature is broken. **Do not mark as flaky or skip**—keep it running to catch when it's fixed.

---

### login > signs in with valid credentials
**Status:** Stable (10/10 passes)  
**Root Cause:** N/A  
No action needed.

---

## Action Summary by Priority

| Test | Category | Action | Effort |
|------|----------|--------|--------|
| cart > updates total | Flaky | Replace `waitForTimeout(300)` with web-first assertion | Low |
| search > filters by tag | Flaky | Isolate test data; unique or reset tags per run | Medium |
| orders > latest first | Flaky | Add retry logic to assertions; file backend ticket | Medium |
| profile > saves avatar | Broken | File bug; do not skip or workaround | — |
| login > signs in | Stable | No action | — |
