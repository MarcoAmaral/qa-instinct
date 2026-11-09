# Defect Report: Flaky Gift Card Application in EUR Checkout

## Summary
Gift card application fails intermittently in the staging checkout flow (EUR store) with a 500 error and undefined currency property error.

## Severity
**Medium** - Feature is critical but only fails in ~30% of attempts; workaround exists (retry).

## Environment
- **Build/Commit:** 4.12.0-rc.2 (9f3c2ab)
- **Environment:** e2e-staging
- **Browser:** Chromium 129.0.6668.29, Playwright 1.48.1
- **OS:** Ubuntu 22.04 (runner)
- **Test Runner:** Playwright with --repeat-each=10
- **Base URL:** https://staging.shop.example

## Test Case
**Spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Reproduction Steps
1. Sign in as buyer.eur@shop.example (EUR store account)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout page
4. Enter gift card code: GC-TEST-0042 (EUR 20.00 balance)
5. Click "Apply" button

## Expected Behavior
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00

## Actual Behavior (on failure)
- Toast notification displays: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- No visual indication of which field/action caused the error

## Error Details
- **Endpoint:** POST `/api/checkout/gift-card`
- **HTTP Status:** 500 Internal Server Error
- **Error Message:** `TypeError: Cannot read properties of undefined (reading 'currency')`
- **Failure Rate:** 3 of 10 attempts (30%)
- **Failing Attempts:** #4, #7, #9 (non-deterministic)

## Root Cause (Suspected)
Currency service cache inconsistency. The error indicates the currency object is undefined when the gift card endpoint tries to read the `currency` property, suggesting:
- Currency cache not populated for EUR store
- Race condition between cart initialization and currency lookup
- Stale cache entry from prior test iteration

## History
- Developer note: "probably the currency service cache again, it was flaky last sprint too"
- Indicates this is a recurring issue with the currency caching layer

## Recommended Actions
1. **Immediate:** Investigate currency service cache initialization in `POST /api/checkout/gift-card` handler; add null/undefined checks
2. **Short-term:** Add retry logic with exponential backoff to currency cache lookup
3. **Long-term:** Refactor currency cache strategy (consider request-scoped cache vs. shared cache) to eliminate store-specific timing issues
4. **Testing:** Add specific test case for multi-currency checkout flows with cache invalidation scenarios

## Related Systems
- Gift card service API
- Currency service (cache layer)
- Checkout orchestration logic
