# CI Flakiness Analysis: e2e Suite on c0ffee1

## Summary
- **Total tests analyzed:** 5 representative tests across 10 runs
- **Flaky tests:** 3
- **Consistently failing (broken):** 1
- **Stable:** 1

---

## Flaky Tests

### 1. cart > updates the total when the quantity changes
**Flakiness rate:** 30% (3 failures / 10 runs)  
**Failure pattern:** Received value is exactly 50% of expected (€29.00 vs €58.00)

**Root cause:** Race condition in wait strategy. The test uses a fixed 300ms timeout followed by a single read, which is insufficient for:
- Server-side price recalculation 
- Network latency for the response
- DOM rendering of the new value

The consistent 50% error (half the expected price) suggests the quantity increment is sometimes still in-flight when the assertion runs.

**Recommendation:**
- Replace `page.waitForTimeout(300)` with web-first assertions: `expect(locator).toContainText('€58.00')`, which will poll until the value appears or timeout
- Alternatively, explicitly wait for the price change: `await page.waitForFunction(() => parseFloat(totalEl.textContent) === 58.00, { timeout: 5000 })`
- Increase timeout to 5-10 seconds to accommodate worst-case latency

---

### 2. search > filters results by tag
**Flakiness rate:** 40% (4 failures / 10 runs)  
**Failure pattern:** Returns 5 results instead of expected 3  
**Key observation:** Passes 20/20 times when run in isolation with `--workers=1 --repeat-each=20`

**Root cause:** Test isolation failure. The "summer" tag used by this test is being mutated by `tags.spec.ts`, which renames tags during its own run. Multi-worker parallelism amplifies this: when tests run concurrently, tag renames from one worker affect queries in another, or the tag state gets corrupted between runs.

**Recommendation:**
- **Fix test data isolation:** Use unique, worker-scoped tag identifiers (e.g., `summer-${workerIndex}`) or UUIDs
- **Reset between runs:** Add a test hook to reset the tags table / reseed the "summer" tag before each search test
- **Isolate tags.spec.ts:** Mark it as `[serial]` to run before other tests, not during, or remove its side effects (don't persist tag mutations)
- Monitor for other inter-test dependencies in the suite

---

### 3. orders > shows the latest order first
**Flakiness rate:** 20% (2 failures / 10 runs; 6% in targeted repeat of 50)  
**Failure pattern:** New order does not appear in the list immediately after creation  
**Key observation:** Targeted repeat showed GET /orders lacks the new order for up to 2 seconds post-creation

**Root cause:** Backend latency, not a test defect. This is a real—if acceptable—timing lag in the order service. The app has eventual consistency behavior: order creation succeeds, but the order list index updates asynchronously.

**Recommendation:**
- **Short term:** Use web-first assertions with higher timeout (10+ seconds) to poll for the new order: `await expect(orderList).toContainText('Order #1043', { timeout: 10000 })`
- **Long term:** Investigate backend order service:
  - Is the orders list backed by a cache that isn't invalidated on create?
  - Is there a queue/async job that delays list updates?
  - Can you return the newly created order in the create response, and prepend it to the UI without a re-fetch?
- If the 2-second lag is inherent (e.g., an external service SLA), document it and accept it as an environmental constraint

---

## Consistently Failing Test

### 4. profile > saves a new avatar
**Flakiness rate:** 0% failure consistency (10 failures / 10 runs)  
**Failure pattern:** Avatar filename expected "avatar.png", received `undefined`

**Root cause:** This is **not flaky**—it is a persistent defect in either the feature or the test:
- Avatar upload or file selection is broken in the app
- The test's element selector is wrong (pointing to the wrong DOM node)
- File upload is not being triggered by the test action
- The endpoint does not return the filename in the expected location

**Recommendation:**
- **Immediate action:** Block this test or skip it (`test.skip()`) until root cause is determined
- **Investigation:** Check:
  - Does avatar upload work in manual testing?
  - What does the POST endpoint return after upload? Is the filename in the response body?
  - Is the test clicking the right element? (Use `page.screenshot()` to debug)
  - Is the avatar input handling file uploads correctly? (Check for async delays, missing event handlers)
- Fix the feature or the test, then re-enable

---

## Stable Test

### 5. login > signs in with valid credentials
**Flakiness rate:** 0% (0 failures / 10 runs)  
**Status:** Fully stable

**Recommendation:** No action. Use as a control test to validate CI stability.

---

## Assumptions Made
- Playwright's default assertion timeout is < 300ms (justifying the cart test recommendation)
- Database seeding is not reset between test runs (supporting the tag isolation diagnosis)
- The backend order lag is reproducible and not caused by occasional timeouts
