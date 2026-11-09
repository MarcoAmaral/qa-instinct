# Defect Report: Gift Card Application Fails with Currency Service Error (Flaky)

## Summary
The gift card application endpoint returns a 500 error on the staging environment with a `TypeError: Cannot read properties of undefined (reading 'currency')`. The issue is intermittent, occurring in 3 of 10 repeated test runs on the same commit.

## Environment
- **Build Version:** 4.12.0-rc.2
- **Commit:** 9f3c2ab
- **Environment:** Staging (https://staging.shop.example)
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Pipeline:** e2e-staging #3318
- **Date:** 2026-10-14 06:12 UTC

## Affected Feature
Checkout flow: Gift card application for EUR currency orders

## Steps to Reproduce
1. Sign in as a user in an EUR store (e.g., buyer.eur@shop.example)
2. Add a product to cart (e.g., "Desk Lamp" EUR 49.00)
3. Proceed to checkout
4. Enter gift card code (e.g., GC-TEST-0042 with EUR 20.00 balance)
5. Click "Apply" button

**Note:** Issue is intermittent; reproduce by running checkout flow repeatedly or triggering concurrent gift card applications.

## Expected Behavior
The order summary updates to show:
- "Gift card: -€20.00"
- Order total: €29.00

## Actual Behavior
A toast notification displays: "Something went wrong. Please try again."
Order total remains unchanged at €49.00
POST /api/checkout/gift-card endpoint returns HTTP 500

## Error Details
**Endpoint:** POST /api/checkout/gift-card  
**HTTP Status:** 500 Internal Server Error  
**Error Message:** `TypeError: Cannot read properties of undefined (reading 'currency')`  
**Response Body:**
```json
{
  "error": "TypeError: Cannot read properties of undefined (reading 'currency')"
}
```

## Failure Pattern
- **Test Runs:** 10 attempts (--repeat-each=10) on same commit
- **Pass Rate:** 70% (7 passed, 3 failed)
- **Failed Attempts:** #4, #7, #9
- **Consistency:** All failures exhibit identical error and response

## Root Cause Analysis (Hypothesis)
The currency service (or currency cache) is intermittently returning undefined or null values, causing the gift card endpoint to fail when attempting to read the `currency` property. The non-consecutive failure pattern suggests a timing or cache invalidation issue rather than a deterministic logic error.

The team has flagged this as a recurring issue ("it was flaky last sprint too"), indicating a known instability with currency service caching under load or during cache refresh cycles.

## Impact
- **Severity:** High
- **Scope:** EUR and potentially other non-USD currencies during gift card operations
- **User-Facing:** Yes (checkout flow interrupted)
- **Production Risk:** Moderate (flaky behavior; affects payment flow on release)

## Recommended Actions
1. **Immediate:** Add timeout/retry logic to the gift card endpoint or circuit breaker for currency service failures
2. **Short-term:** Audit currency service cache implementation for race conditions or stale data
3. **Short-term:** Add logging to capture currency service state at time of failure
4. **Medium-term:** Review currency service initialization/warm-up in staging and production environments
5. **QA:** Re-run test suite on build 4.12.0-rc.2 to confirm failure rate before release gate

## Additional Notes
- This is a blocker for release if it persists in pre-release testing
- Suggest investigation of currency cache invalidation patterns and concurrent request handling in the currency service layer
