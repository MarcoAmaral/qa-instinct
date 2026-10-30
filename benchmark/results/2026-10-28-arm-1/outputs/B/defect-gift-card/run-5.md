# Defect Report: Gift Card Application Fails with Currency Service Error

**Report Date:** 2026-10-14  
**Severity:** High  
**Status:** New  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)

## Summary
Gift card application to EUR orders fails intermittently in staging during checkout, returning a 500 error with a currency object reference error. The feature exhibits non-deterministic behavior with a 30% failure rate on repeated test runs against the same build.

## Environment
- **Base URL:** https://staging.shop.example
- **Test Framework:** Playwright 1.48.1 with Chromium 129.0.6668.29
- **OS:** Ubuntu 22.04
- **Currency:** EUR
- **Test User:** buyer.eur@shop.example

## Reproduction Steps
1. Sign in as buyer.eur@shop.example (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (balance: EUR 20.00)
5. Click "Apply" button

## Expected Result
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00 (EUR 49.00 - EUR 20.00)

## Actual Result
- Toast notification: "Something went wrong. Please try again."
- Order total remains at €49.00 (gift card not applied)
- API endpoint `/api/checkout/gift-card` returns HTTP 500
- Error response: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

## Reproducibility
- **Test Method:** Repeated test execution (--repeat-each=10)
- **Pass Rate:** 7/10 attempts (70%)
- **Failure Rate:** 3/10 attempts (30%)
- **Failed Attempts:** Attempts 4, 7, and 9
- **Pattern:** No correlation with attempt order; failures appear random

## Root Cause Analysis
The server-side error indicates that the currency object is undefined when the gift card API handler attempts to access the `.currency` property. This suggests:

1. **Primary Hypothesis:** Currency service cache is inconsistent or intermittently stale, causing the gift card endpoint to fail when it queries cached currency data
2. **Supporting Evidence:** Developer team note indicates known flakiness with the currency service cache in the previous sprint
3. **Scope:** Issue is isolated to the backend gift card API; only EUR orders appear to be tested

## Impact
- Gift card functionality is unusable in staging for EUR currency orders
- Non-deterministic failures block reliable testing of payment flows in RC builds
- May affect go-live confidence for regions using EUR pricing

## Logs/Evidence
- **API Endpoint:** `POST /api/checkout/gift-card`
- **Response Code:** 500
- **Error Stack:** TypeError indicates undefined currency object reference
- **Test Spec File:** checkout.spec.ts > gift card > applies a gift card to an order in EUR

## Recommendations for Development
1. Investigate currency service cache initialization and refresh logic
2. Add null/undefined checks for currency object in gift card handler
3. Implement circuit breaker or fallback for currency service failures
4. Review cache invalidation timing, especially for EUR pricing data
5. Add server-side logging to track cache state during gift card processing

## Recommendations for QA
1. Verify whether other currencies (USD, GBP, etc.) exhibit the same failure pattern
2. Correlate failure timing with currency cache refresh cycles in staging
3. Run regression tests against other payment methods (non-gift-card) to confirm isolation
4. Retest with manual cache invalidation between attempts

---
**Assignee:** Backend/Payments Team  
**Blocked:** RC release gate for EUR markets pending fix verification
