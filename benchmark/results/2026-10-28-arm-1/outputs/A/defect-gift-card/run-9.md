# Defect Report: Gift Card Application Fails with Currency Service Undefined Error

**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Severity:** High  
**Flakiness:** Yes (3/10 attempts failed)  
**Environment:** e2e-staging, Chromium 129.0.6668.29, Ubuntu 22.04

## Summary
Gift card application fails intermittently with a 500 error on the `/api/checkout/gift-card` endpoint. The error indicates the currency service is returning undefined, causing downstream code to crash when attempting to read the `currency` property.

## Steps to Reproduce
1. Sign in as `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to the cart
3. Open checkout
4. Enter gift card code `GC-TEST-0042` (balance EUR 20.00)
5. Press "Apply"

## Expected Behavior
Order summary updates to show:
- Gift card discount: -€20.00
- Order total: €29.00

## Actual Behavior
A toast notification displays: "Something went wrong. Please try again."  
Order total remains unchanged at €49.00

## Error Details
**Endpoint:** POST `/api/checkout/gift-card`  
**Status Code:** 500  
**Error Message:**
```
TypeError: Cannot read properties of undefined (reading 'currency')
```

## Flakiness Pattern
- Test passed: 7/10 attempts
- Test failed: 3/10 attempts (attempts 4, 7, and 9)
- Consistent error response across all failures

## Root Cause Analysis
**Assumption:** The currency service cache is returning undefined under certain conditions, likely during concurrent requests or cache invalidation.

**Supporting Evidence:** Developer note indicates this issue was flaky last sprint and suspected to be cache-related.

## Recommended Actions
1. Review currency service cache initialization and invalidation logic
2. Add null/undefined checks in the gift card endpoint before accessing the `currency` property
3. Investigate whether cache TTL or concurrency issues are causing intermittent undefined states
4. Consider adding circuit breaker or fallback logic for currency service failures
5. Add monitoring/alerting for 500 errors on gift card endpoints

## Test Coverage Notes
Test framework: Playwright 1.48.1  
Base URL: https://staging.shop.example  
Assumption: Issue is reproducible on staging but may also affect production if currency service cache has similar issues
