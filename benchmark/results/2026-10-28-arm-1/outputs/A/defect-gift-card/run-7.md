# Defect Report: Gift Card Application Fails with 500 Error (Intermittent)

**Report Date:** 2026-10-28  
**Severity:** High  
**Status:** New  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)

## Summary
Gift card application in checkout fails intermittently with a server error when processing requests for EUR currency orders. The failure occurs in 30% of test attempts (3 failures out of 10 on the same commit), indicating a flaky issue likely related to currency service state.

## Environment
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **URL:** https://staging.shop.example
- **Test File:** checkout.spec.ts
- **Test Name:** gift card > applies a gift card to an order in EUR

## Steps to Reproduce
1. Sign in as test user `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code `GC-TEST-0042` (balance EUR 20.00)
5. Click "Apply" button

## Expected Behavior
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00

## Actual Behavior
- Toast message appears: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- HTTP POST `/api/checkout/gift-card` returns 500 error

## Error Details
```
Response Status: 500
Response Body: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Flakiness
- Test consistently passes when run in isolation
- Fails intermittently when run with `--repeat-each=10` on the same commit
- Failure rate: 30% (attempts 4, 7, and 9 failed; attempts 1-3, 5-6, 8, 10 passed)
- Indicates state-dependent or timing-related issue

## Suspected Root Cause
Currency service cache is likely returning stale or incomplete data, causing the API handler to fail when attempting to read the `currency` property from an undefined object. This aligns with observed flakiness across repeated test runs where cache state may differ between attempts.

## Impact
- Checkout workflow for EUR currency users is unreliable
- Pre-release build 4.12.0-rc.2 has blocking test failures
- Staging environment affected; production impact unknown

## Recommended Actions
1. Investigate currency service cache invalidation logic
2. Review `/api/checkout/gift-card` endpoint error handling for undefined currency
3. Add defensive null-checking for currency object properties
4. Consider cache TTL or refresh strategy changes
