# Defect Report

## Summary
Gift card application fails intermittently with 500 error during EUR checkout, returning "TypeError: Cannot read properties of undefined (reading 'currency')" from the gift-card API endpoint.

## Environment
- **Build Version**: 4.12.0-rc.2 (commit 9f3c2ab)
- **Test Environment**: e2e-staging
- **Browser**: Chromium 129.0.6668.29
- **Test Framework**: Playwright 1.48.1
- **OS**: Ubuntu 22.04
- **Base URL**: https://staging.shop.example
- **Execution Date**: 2026-10-14 06:12 UTC
- **Pipeline**: e2e-staging #3318

## Test Case
**Spec**: `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

**Test Scenario**:
1. Sign in as buyer.eur@shop.example (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card GC-TEST-0042 (balance EUR 20.00)
5. Press "Apply" button

## Expected Behavior
Order summary displays "Gift card: -€20.00" and order total updates to €29.00.

## Actual Behavior
Toast notification displays "Something went wrong. Please try again." and order total remains €49.00. Network request fails with HTTP 500.

## Error Details
- **Endpoint**: POST /api/checkout/gift-card
- **HTTP Status**: 500
- **Error Type**: TypeError
- **Error Message**: "Cannot read properties of undefined (reading 'currency')"
- **Root Cause**: Currency object is undefined when attempting to access its currency property during gift card processing

## Flakiness & Reproducibility
- **Test Attempts**: 10 total (--repeat-each=10)
- **Pass Rate**: 70% (7 passed, 3 failed)
- **Failed Attempts**: #4, #7, #9 (same error and status code)
- **Consistency**: Deterministic error when it occurs, but intermittent trigger

## Assumptions
- The currency service is properly initialized for most requests but periodically returns null or undefined
- The issue is specific to EUR currency operations
- The gift card balance lookup succeeds (since the card is recognized)
- The cart and checkout state are valid in all test attempts

## Potential Root Cause
Developer team suggests currency service cache inconsistency. The service likely has a stale or missing cached entry for the EUR currency configuration, causing the API handler to receive an undefined currency object. This explains the intermittent nature (7/10 successes indicate cache hits work correctly but occasional cache misses or evictions cause failures).

## Impact
- **Severity**: High (payment flow failure during critical checkout stage)
- **Scope**: EUR currency transactions only in staging
- **User Impact**: If present in production, would cause gift card application failures for EUR region customers

## Recommended Actions
1. Verify currency service cache invalidation and refresh logic
2. Add null/undefined checks in `/api/checkout/gift-card` handler before accessing currency properties
3. Add logging to track currency cache hits/misses
4. Review currency service initialization during EUR store setup
5. Consider adding retry logic with exponential backoff for gift card application
