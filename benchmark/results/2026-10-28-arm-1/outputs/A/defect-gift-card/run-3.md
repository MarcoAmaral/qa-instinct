# Defect Report: Gift Card Application Fails with 500 Error (Intermittent)

## Summary
Gift card application in checkout fails intermittently with a 500 error when applying gift cards to EUR currency orders. The failure occurs in approximately 30% of test attempts on the same commit, indicating a non-deterministic issue likely related to service caching.

## Severity
**High** – Checkout functionality is partially broken in production; feature is customer-facing and affects revenue transactions.

## Environment
- **Build Version:** 4.12.0-rc.2
- **Commit:** 9f3c2ab
- **Test Framework:** Playwright 1.48.1
- **Browser:** Chromium 129.0.6668.29
- **OS:** Ubuntu 22.04 (CI runner)
- **Test Environment:** Staging (https://staging.shop.example)
- **Test Case:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Steps to Reproduce
1. Log in as test user `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code `GC-TEST-0042` (balance: EUR 20.00)
5. Press "Apply" button

## Expected Behavior
Order summary displays:
- Gift card discount: -€20.00
- Order total: €29.00

## Actual Behavior
- Toast message displayed: "Something went wrong. Please try again."
- Order total remains unchanged: €49.00
- API request fails with HTTP 500 status

## Error Details
- **Endpoint:** POST `/api/checkout/gift-card`
- **HTTP Status:** 500
- **Error Message:** `TypeError: Cannot read properties of undefined (reading 'currency')`
- **Root Cause (Inferred):** The currency service is returning undefined for the currency object, preventing the gift card application logic from accessing the currency property.

## Failure Frequency
- **Test Attempts:** 10 (with `--repeat-each=10` flag on same commit)
- **Passed:** 7
- **Failed:** 3 (attempts 4, 7, and 9)
- **Flake Rate:** 30%
- **Intermittency Pattern:** Non-deterministic; failures scattered across multiple attempts

## Root Cause (Suspected)
Currency service cache invalidation or stale cache state. The intermittent nature and developer team note indicate a caching layer issue that was previously observed and not fully resolved in prior sprints.

## Affected Scope
- EUR currency stores (EUR transaction processing)
- Potentially other non-default currency stores if the cache issue is global
- Assumption: GBP, USD, and other currency stores may also be affected if cache is shared

## Recommendations
1. **Immediate:** Investigate currency service cache initialization and invalidation logic
2. **Investigation:** Trace cache key generation for currency lookups; verify cache is properly cleared between requests
3. **Testing:** Add specific test coverage for gift card application across multiple currency types
4. **Monitoring:** Add alerting on `/api/checkout/gift-card` 500 error rate in staging and production
