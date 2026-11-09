# Flaky Test Analysis – e2e Suite

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Flakiness:** 30% (3/10 failures)  
**Root Cause:** Insufficient wait time before assertion. The test uses a hardcoded `page.waitForTimeout(300)` followed by a single `textContent()` read. The 300ms timeout is unreliable for async cart calculations.  
**Why It Happens:** Cart total updates are asynchronous (likely involving backend call + DOM update). 300ms is not guaranteed to be enough; timing depends on network latency and JavaScript execution.  
**Recommendation:** Replace hardcoded `waitForTimeout` with web-first assertion:
- Use `page.locator('[data-testid="cart-total"]').toContainText("€58.00")` which retries automatically
- Or poll with `page.waitForFunction()` to confirm the new total before reading

---

### 2. search > filters results by tag
**Flakiness:** 40% (4/10 failures)  
**Root Cause:** Test isolation failure. The test passes 20/20 when run alone, but fails 4/10 in the full suite. The seeded "summer" tag is being renamed by `tags.spec.ts` during parallel execution, contaminating the search results (expecting 3, getting 5).  
**Why It Happens:** Tests share a database with seeded data. Parallel workers run `tags.spec.ts` which modifies the "summer" tag, affecting this test's results. No cleanup or isolation between tests.  
**Recommendation:** Isolate test data:
- Use database setup/teardown per test to create isolated tag sets (not shared seeds)
- Or lock/mutex the "summer" tag state during tests that depend on it
- Or run `search.spec.ts` serially (`--workers=1`) or after tag mutations complete

---

### 3. orders > shows the latest order first
**Flakiness:** 20% (2/10 failures)  
**Root Cause:** Backend inconsistency. Even in a controlled --repeat-each=50 run with a fresh user per iteration, the order failed to appear in GET /orders for up to 2 seconds after creation. The test reads immediately; the backend hasn't replicated or indexed the new order yet.  
**Why It Happens:** Order creation endpoint returns success before the order is queryable. This suggests eventual consistency in the backend (database replication lag, search index lag, or cache invalidation delay).  
**Recommendation:** Add polling to the test:
- After creating an order, poll GET /orders with retries until the new order appears (use Playwright's web-first assertions)
- Or, if the backend can be fixed: ensure order is immediately queryable after creation response (synchronous writes or cache warmup)
- Assumption: Backend is the bottleneck, not test flakiness

---

## Broken Test (Not Flaky)

### 4. profile > saves a new avatar
**Status:** Consistently broken (0/10 passes)  
**Root Cause:** Likely a file upload/interaction issue or incorrect assertion target. The avatar value is `undefined` rather than "avatar.png" in every run.  
**Why It Happens:** Either the file upload interaction isn't working (input not filled, file not sent), or the assertion is reading the wrong property/element.  
**Recommendation:** Debug and fix:
- Verify file upload interaction works (check network tab, verify the file is POSTed)
- Verify the avatar property is correctly set in the response and page state
- Check test locators — make sure the assertion targets the actual rendered avatar value
- This is a blocking issue; ship a fix before worrying about flakiness

---

## Reliable Test

### 5. login > signs in with valid credentials
**Status:** Fully reliable (10/10 passes)  
**Action:** No changes needed.
