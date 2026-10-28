# Defect Report: Gift Card Application Fails Intermittently with Currency Service Cache Bug

**Report Date:** 2026-10-28  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Status:** Open  
**Severity:** High

## Summary
Gift card application in EUR-denominated orders fails intermittently with a 500 error when the currency service cache is stale. The test suite shows a 30% failure rate (3 out of 10 attempts) for the same functionality, indicating a flaky but reproducible defect in pre-release testing.

## Environment
- **Pipeline:** e2e-staging #3318  
- **Test Date/Time:** 2026-10-14 06:12 UTC  
- **Base URL:** https://staging.shop.example  
- **Browser:** Chromium 129.0.6668.29  
- **Test Framework:** Playwright 1.48.1  
- **OS:** Ubuntu 22.04 (runner)

## Test Details
**Test Path:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

**Affected Functionality:**
- Applying a gift card (GC-TEST-0042, EUR 20.00 balance) to a cart containing "Desk Lamp" (EUR 49.00)
- EUR store context (test user: buyer.eur@shop.example)

## Reproduction Steps
1. Sign in with EUR-store test account
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Navigate to checkout
4. Enter gift card code "GC-TEST-0042"
5. Click "Apply" button

## Expected Behavior
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00 (€49.00 - €20.00)
- No error messages displayed

## Actual Behavior (Failure)
- Toast notification: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- Endpoint returns HTTP 500

## Technical Details

**Failing Endpoint:** `POST /api/checkout/gift-card`

**Error Response:**
```json
{
  "error": "TypeError: Cannot read properties of undefined (reading 'currency')"
}
```

**Root Cause (Preliminary):** Null/undefined reference error when accessing the `currency` property. The currency service appears to be returning `undefined`, suggesting a stale or missing cache entry for the EUR currency configuration.

## Flakiness Pattern
- **Pass Rate:** 7/10 attempts (70%)
- **Failure Rate:** 3/10 attempts (30%)
- **Failed Attempts:** 4, 7, 9 (same error and status code)
- **Pattern:** Non-deterministic; failures occur at different attempt numbers, indicating a race condition or cache expiration timing issue

## Impact
- **Severity:** High — Payment flow is blocked for EUR customers in staging
- **Scope:** Gift card functionality in multi-currency environments
- **User Impact:** If this exists in production, EUR store customers cannot apply gift cards

## Root Cause Analysis
The error message and developer note strongly suggest this is a **currency service cache coherency issue**:
1. The currency service or cache is returning `undefined` for the EUR currency configuration
2. The gift card validation/application logic attempts to access `undefined.currency`, triggering the TypeError
3. The issue is intermittent, pointing to a race condition between cache invalidation and request timing
4. This defect was previously noted as "flaky last sprint," indicating it is known but unresolved

## Recommended Investigation
1. **Verify currency cache initialization:** Confirm that the currency service cache is being populated before the gift card endpoint is called
2. **Review cache invalidation logic:** Check if cache expiration or refresh intervals are causing stale/missing entries
3. **Check concurrent request handling:** Confirm that parallel requests to the currency service don't cause race conditions
4. **Add cache fallback:** Implement a secondary lookup or reload mechanism if cache lookup fails
5. **Add logging:** Log currency cache hits/misses and `undefined` references to identify the exact failure point

## Assumptions
- This defect appears only in staging environment on this build
- The EUR currency configuration exists in the database/service but is not reliably available in cache
- No workaround is currently documented for test teams

## Next Steps
1. Assign to backend/services team (currency service owner)
2. Investigate cache coherency in preparation for production release
3. Consider adding cache warming or validation before the gift card endpoint processes requests
4. Re-run test suite after fix to confirm resolution
