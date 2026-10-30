I notice you've loaded the help-articles skill, but your request is for technical analysis of CI test flakiness for your dev team, not an end-user help article. I'll provide the analysis you need in the format you requested instead.

---

# E2E Test Flakiness Analysis

## Cart: Updates the Total When the Quantity Changes

**Flakiness:** 30% failure rate (3 of 10 runs)

**Root cause:** Race condition in the UI. The test waits 300ms after clicking "+", then reads the total once. This hard-coded wait is shorter than the backend processing time in some runs. When the server takes longer to process the quantity change, the UI hasn't updated yet and still shows €29.00.

**What to do:** Replace the timeout with a web-first assertion. Wait for the total text to contain "€58.00" instead of guessing a duration. This makes the test resilient to variable backend latency.

```javascript
// Instead of: page.waitForTimeout(300); const total = await page.textContent(...)
// Use: await expect(page.locator('[data-testid=total]')).toContainText('€58.00');
```

---

## Profile: Saves a New Avatar

**Flakiness:** 100% failure rate (consistently failing, not flaky—broken)

**Root cause:** The element expected to contain "avatar.png" is undefined, meaning either the upload didn't complete, the element doesn't exist, or the test is selecting the wrong element. This fails every run, so it's not a timing issue.

**What to do:** This test is broken, not flaky. Debug locally with `npx playwright test profile.spec.ts --debug` to find why the avatar filename is not set. Likely causes: the upload endpoint is failing silently, or the test is reading from the wrong DOM node.

---

## Search: Filters Results by Tag

**Flakiness:** 40% failure rate (4 of 10 runs)

**Root cause:** Test isolation failure, not a flaky feature. The test uses a seeded tag "summer", but `tags.spec.ts` runs in parallel and renames "summer" during its own run. When these tests overlap, the "summer" tag disappears mid-run. Running the search test alone shows 100% pass rate, confirming the tag filter itself works.

**What to do:** Use unique test data per run. Instead of seeding a shared "summer" tag, have each test create its own tag with a unique name like `summer-${Date.now()}`, or use database transactions to isolate test data between runs. Alternatively, run tags.spec.ts serially with `--workers=1` if it must not run in parallel.

---

## Orders: Shows the Latest Order First

**Flakiness:** 20% failure rate (2 of 10 runs)

**Root cause:** Backend race condition. GET /orders is returning the list before the new order is flushed to the database. The test creates an order and immediately fetches it, but the backend's write is not yet visible to reads in some runs (up to 2 seconds lag observed). This is a real system issue, not a test problem.

**What to do:** Add a retry or wait-for assertion in the test. Use web-first assertions to retry the check: `await expect(page.locator('text=Order #1043')).toBeVisible()` rather than a single read. The test's existing web-first assertions suggest it's on the right path. Also investigate backend write consistency—if the database uses eventual consistency or replication lag, the service should confirm the write was replicated before returning the 201 response.

---

## Login: Signs in with Valid Credentials

**Status:** Reliable (0% failure rate across 10 runs)

**Action:** None. This test is stable and should stay as is.
