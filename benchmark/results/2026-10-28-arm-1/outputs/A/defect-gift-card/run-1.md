# Defect Report: Gift Card Application Fails with Currency Service Error

## Summary
Gift card application endpoint intermittently fails with a 500 error when applying a EUR gift card to an order in the staging environment. The error indicates undefined currency property access in the backend service.

## Environment
- **Environment**: Staging (https://staging.shop.example)
- **Build**: 4.12.0-rc.2 (commit 9f3c2ab)
- **Test Date**: 2026-10-14 06:12 UTC
- **Browser**: Chromium 129.0.6668.29
- **Test Framework**: Playwright 1.48.1
- **Runner OS**: Ubuntu 22.04

## Affected Component
- **Test Suite**: checkout.spec.ts
- **Test Case**: gift card > applies a gift card to an order in EUR
- **API Endpoint**: POST /api/checkout/gift-card

## Reproduction Steps
1. Sign in with test user buyer.eur@shop.example (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (EUR 20.00 balance)
5. Click "Apply"

## Expected Behavior
- Order summary updates to show "Gift card: -€20.00"
- Order total decreases to €29.00

## Actual Behavior
- Toast message displays: "Something went wrong. Please try again."
- Order total remains unchanged at €49.00
- Server responds with HTTP 500

## Error Details
- **Response Status**: 500 Internal Server Error
- **Error Message**: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
- **Error Type**: Attempting to access 'currency' property on undefined object

## Flakiness Assessment
- **Test Run**: 10 iterations (--repeat-each=10)
- **Pass Rate**: 70% (7 passed, 3 failed)
- **Failure Attempts**: 4, 7, and 9
- **Consistency**: Same error status and response body across all failures

## Suspected Root Cause
Currency service cache inconsistency. Per developer team note, this issue was also observed in the previous sprint, suggesting a known intermittent problem with currency service state management or cache invalidation.

## Impact
- **Severity**: High
- **User Impact**: Payment processing failure for EUR transactions using gift cards
- **Test Impact**: E2E pipeline unreliability (30% flake rate on this test)
- **Scope**: Affects EUR store transactions specifically

## Additional Observations
- Error is intermittent, occurring in 3 out of 10 runs with identical setup
- Passing attempts demonstrate the feature works correctly when cache is in valid state
- Issue appears to be backend-side (server error) not client-side (successful API call attempts made)

## Recommended Investigation
1. Review currency service cache initialization and invalidation logic
2. Check if cache warmup is occurring properly before checkout operations
3. Examine currency service dependency injection in gift card validation flow
4. Investigate if concurrent test runs share cache state improperly
5. Consider adding retry logic or cache refresh mechanism in gift card endpoint
