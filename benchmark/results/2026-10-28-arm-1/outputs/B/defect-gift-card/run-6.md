# Defect Report: Gift Card Application Fails with 500 Error During EUR Checkout

**Report Date:** 2026-10-28  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Pipeline:** e2e-staging #3318, CI Run 2026-10-14 06:12 UTC

## Summary
Gift card application endpoint returns HTTP 500 with undefined currency property error during checkout flow, causing checkout to fail intermittently. Issue exhibits flaky behavior with 30% failure rate across repeated test runs.

## Severity
**High** — Blocks checkout transaction completion in affected instances; production payment path affected.

## Environment
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04 (CI runner)
- **Base URL:** https://staging.shop.example
- **Affected Currency:** EUR

## Steps to Reproduce
1. Sign in to EUR store account (test user: buyer.eur@shop.example)
2. Add item to cart: "Desk Lamp" (EUR 49.00)
3. Navigate to checkout
4. Enter gift card code: GC-TEST-0042 (balance EUR 20.00)
5. Click "Apply" button
6. Observe POST request to `/api/checkout/gift-card`

## Expected Result
- Gift card discount applied successfully
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00
- No error messages displayed

## Actual Result
- Toast notification displays: "Something went wrong. Please try again."
- Order total remains at €49.00 (gift card not applied)
- API returns HTTP 500 response
- Console error: `TypeError: Cannot read properties of undefined (reading 'currency')`

## Technical Details

**Endpoint:** POST `/api/checkout/gift-card`  
**HTTP Status:** 500 Internal Server Error  
**Response Body:**
```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

**Failure Pattern:**
- Test run result: 7 passed, 3 failed out of 10 repeat attempts (70% pass rate)
- Failed attempts: #4, #7, #9
- Failure distribution suggests intermittent server-side state issue, not consistent code path

## Root Cause Analysis
**Suspected Issue:** Currency service cache inconsistency. The error indicates the currency object is undefined when the gift card application handler attempts to access its `currency` property. This suggests:
1. Currency service initialization or cache lookup failure
2. Race condition in cache population on server startup or refresh cycle
3. Cache key mismatch between request processing and currency lookup

The 30% failure rate and notes from development team indicate this is a known recurring issue ("flaky last sprint too").

## Recommended Actions
1. **Immediate:** Investigate currency service cache initialization in gift card handler
2. **Short-term:** Add null/undefined checks before accessing currency properties in checkout API
3. **Follow-up:** Review cache invalidation/refresh logic for EUR region currency settings
4. **Testing:** Add specific test case for currency service unavailability scenarios

## Attachments
- CI Pipeline Log: e2e-staging #3318
- Test Spec: checkout.spec.ts > gift card > applies a gift card to an order in EUR
- Commit Hash: 9f3c2ab
