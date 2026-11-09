# Defect Report: Gift Card Application Fails with 500 Error in EUR Store Checkout

## Summary
Gift card application fails intermittently during checkout in the EUR store, returning a 500 error with a currency undefined error. This is a flaky test affecting 3 of 10 attempts on the same commit.

## Build Information
- **Build Version:** 4.12.0-rc.2
- **Commit:** 9f3c2ab
- **Date:** 2026-10-14 06:12 UTC
- **Pipeline:** e2e-staging #3318

## Environment
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04 runner
- **Base URL:** https://staging.shop.example

## Affected Test
- **Spec:** checkout.spec.ts > gift card > applies a gift card to an order in EUR
- **Test Account:** buyer.eur@shop.example (EUR store)

## Steps to Reproduce
1. Sign in as test user buyer.eur@shop.example in the EUR store
2. Add "Desk Lamp" (EUR 49.00) to the cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (balance EUR 20.00)
5. Click "Apply" button

## Expected Result
- Order summary displays "Gift card: -€20.00"
- Total order amount updates to €29.00

## Actual Result
- Toast notification displays "Something went wrong. Please try again."
- Order total remains at €49.00
- No gift card discount applied

## Technical Details
- **Failed Endpoint:** POST /api/checkout/gift-card
- **HTTP Status:** 500 Internal Server Error
- **Error Response:** `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
- **Failed Attempts:** 3 out of 10 (attempts 4, 7, and 9)
- **Passing Attempts:** 7 out of 10

## Flakiness Assessment
This is a **flaky test** with a 30% failure rate. The same test spec with identical parameters (`--repeat-each=10`) produces inconsistent results on the same commit.

## Root Cause Analysis
**Suspected Issue:** Currency service cache is returning undefined or null for currency data when processing the gift card application. This aligns with the error message indicating the code is attempting to read the `currency` property from an undefined object.

**Developer Note:** Team member indicated this may be related to the currency service cache, which was previously flaky in the previous sprint.

## Severity
- **Priority:** High
- **Impact:** Checkout functionality blocked for EUR store users when gift cards are used (intermittent)
- **Scope:** Production checkout workflow, payment processing

## Recommendations
1. Investigate currency service cache initialization and null-checking in the gift card processing logic
2. Add defensive checks to handle undefined currency objects before property access
3. Review cache invalidation and refresh mechanisms for the currency service
4. Consider adding retry logic or circuit breaker pattern if cache misses are unavoidable
5. Implement monitoring/alerting for currency service failures in production

## Related Information
- Test uses gift card GC-TEST-0042 with EUR 20.00 balance
- Issue appears specific to EUR store locale/currency handling
- Suggests currency data may not be properly loaded or cached for certain concurrent requests
