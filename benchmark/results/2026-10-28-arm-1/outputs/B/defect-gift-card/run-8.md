# Defect Report: Gift Card Application Fails with 500 Error in EUR Checkout

**Report ID:** CI-2026-10-14-e2e-3318  
**Date Reported:** 2026-10-14  
**Environment:** e2e-staging  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  

## Summary
The gift card application flow fails intermittently during checkout when applying a valid gift card in EUR currency. The endpoint returns a 500 server error indicating an undefined currency property, causing the transaction to fail and preventing order completion.

## Severity
**High** — Gift card functionality (core checkout feature) is broken in production-like environment; 30% failure rate indicates data consistency or caching issue affecting paying customer path.

## Environment
- **Base URL:** https://staging.shop.example
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Test Repetition:** --repeat-each=10 (7 passed, 3 failed)

## Steps to Reproduce
1. Sign in to staging account: buyer.eur@shop.example (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to the cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (balance EUR 20.00)
5. Click "Apply" button
6. Observe the result

**Reproducibility:** Intermittent — occurs in attempts 4, 7, and 9 of repeated test runs on the same commit. Not consistently reproducible.

## Expected Behavior
- Gift card is validated and applied to the order
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00 (€49.00 - €20.00)
- Success confirmation is shown to user

## Actual Behavior
- API request fails with HTTP 500
- Toast notification appears: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- User is unable to complete checkout with gift card

## Technical Details
**Failing Endpoint:** `POST /api/checkout/gift-card`  
**HTTP Status:** 500 Internal Server Error  
**Error Response:**
```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

**Error Stack:** Currency property is being read from an undefined object in the gift card application logic.

## Observations
- **Flakiness Pattern:** 30% failure rate (3 of 10) suggests non-deterministic behavior, likely related to service state or caching
- **Consistency:** All three failures show identical error signature (attempts 4, 7, 9)
- **Scope:** Affects EUR currency; other currencies untested but likely at risk
- **Passing Runs:** 7 consecutive passing attempts on same commit indicate the code logic is correct but dependent state is inconsistent

## Root Cause Assessment
**Suspected Root Cause:** Currency service cache inconsistency or staleness. The error indicates that a currency object expected to be available is undefined, suggesting:
- Currency metadata cache may be expired or invalidated between test attempts
- Currency service initialization may be non-deterministic during concurrent requests
- Gift card validation depends on cached currency data that is not always hydrated before use

**Historical Context:** Developer note indicates this is a known recurring issue ("flaky last sprint too"), pointing to an existing system fragility with the currency caching layer.

## Impact
- **Feature Affected:** Gift card redemption in checkout
- **User Base:** EUR region customers attempting to use gift cards
- **Business Impact:** Checkout abandonment for customers with gift cards; blocked revenue
- **Release Blocker:** Yes — this is a regression in core purchase flow

## Recommendations
1. **Immediate:** Investigate currency service cache initialization and lifecycle in `/api/checkout/gift-card` endpoint
2. **Root Cause:** Review currency cache invalidation logic and ensure data consistency across requests
3. **Fix Verification:** Confirm the fix resolves the issue under load and concurrent request conditions
4. **Regression Testing:** Add deterministic tests that verify currency service availability before gift card operations
5. **Monitoring:** Add alerts for 500 errors on gift card endpoint to catch future regressions

---

**Assignee:** Backend — Checkout/Payments team  
**Target Resolution:** Before RC.2 release  
**Status:** Open
