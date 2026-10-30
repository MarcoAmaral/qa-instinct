# Flaky Test Analysis Report

## Executive Summary
3 of 5 tests are flaky (60% of analyzed tests). 1 test is consistently broken (real bug). 1 test is reliable.

---

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Failure rate:** 3/10 (30%)

**Root cause:** Race condition. The test uses a fixed `waitForTimeout(300)` before reading the total, but the UI update takes longer than 300ms in ~30% of runs.

**Recommendation:** Replace fixed wait with a web-first assertion. Use `expect(locator).toContainText()` with built-in retries (defaults to 5s timeout), or `waitForFunction()` that polls the total until it matches the expected value. Remove `textContent()` snapshot approach entirely—Playwright's assertions retry automatically.

---

### 2. search > filters results by tag
**Failure rate:** 4/10 (40%)

**Root cause:** Test pollution / isolation failure. The test relies on a seeded "summer" tag, but `tags.spec.ts` modifies it during parallel runs. Passes 20/20 when run alone because no other test mutates the tag.

**Recommendation:** 
- *Preferred:* Isolate test data—assign a unique tag name per test run (UUID or timestamp) and create it fresh in setup.
- *Alternative:* Reset the "summer" tag state in beforeEach; add a test.describe.serial() block if tag state must be predictable across tests.
- *Verify:* Run with `--workers=1` to confirm test ordering dependency, then implement data isolation to restore parallel safety.

---

### 3. orders > shows the latest order first
**Failure rate:** 2/10 (20%) in CI; 3/50 (6%) in isolated repeat

**Root cause:** Backend timing issue. GET /orders returns the list without the newly created order for up to 2 seconds after POST /orders completes. The test's single read is too early.

**Recommendation:**
- *Immediate fix:* Use `expect(page).toContainText('Order #1043')` with retries instead of a single read. This naturally polls for the order to appear within Playwright's default 5s timeout.
- *Underlying fix:* Have backend ensure order appears in GET response within 100ms of POST response, or add a sync barrier (e.g., return order ID and poll until it's in the list).
- *Test approach:* Avoid "read once" patterns in distributed systems; assume propagation delay and retry.

---

## Non-Flaky Tests

### 4. profile > saves a new avatar
**Failure rate:** 10/10 (100%) — **Not flaky, consistently broken**

**Root cause:** Real bug. The avatar field is undefined after upload in every run (same error message each time). Likely causes:
- Avatar upload endpoint is broken or not persisting.
- DOM selector is wrong (element doesn't exist after upload).
- Test setup is incomplete (missing auth, storage, or fixture).

**Recommendation:** File a bug and block this test until fixed. Do *not* skip or ignore—this is a product bug, not a test issue. Debugging steps:
1. Verify the upload request reaches the backend (check network tab in a manual run).
2. Confirm the backend stores the avatar and returns it on GET /profile.
3. Inspect the DOM—is the img/avatar element being rendered and populated?

---

### 5. login > signs in with valid credentials
**Failure rate:** 0/10 (0%) — **Reliable**

**Recommendation:** No action. Use as a control/canary test to verify CI health.

---

## Action Backlog

| Test | Action | Priority | Effort |
|------|--------|----------|--------|
| cart | Replace waitForTimeout + textContent with expect().toContainText() | High | 30 min |
| search | Isolate test data (unique tag per run) or reset state in beforeEach | High | 1 hour |
| orders | Add polling/retries with expect() web-first assertions | High | 45 min |
| profile | File bug, debug avatar upload endpoint + DOM rendering | Blocking | 2 hours |
| login | Monitor (no change) | — | — |
