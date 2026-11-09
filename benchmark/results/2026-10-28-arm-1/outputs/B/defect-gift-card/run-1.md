# Defect Report: Gift Card Application Fails Intermittently with 500 Error in EUR Checkout

## Summary
The gift card application feature exhibits flaky behavior in the EUR store checkout flow, failing approximately 30% of the time (3 of 10 attempts). When the failure occurs, the API returns a 500 error with a TypeError indicating the currency service is returning undefined properties, preventing the gift card from being deducted from the order total.

## Severity
**High** — Critical checkout functionality; flakiness impacts e2e staging validation; blocks release verification.

## Environment
- **Build Version:** 4.12.0-rc.2 (commit 9f3c2ab)
- **Base URL:** https://staging.shop.example
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04 (runner)
- **Store:** EUR
- **Test Currency:** EUR (€)

## Steps to Reproduce
1. Sign in with test user: `buyer.eur@shop.example` (EUR store configured)
2. Add "Desk Lamp" (EUR 49.00) to shopping cart
3. Navigate to checkout page
4. Enter gift card code: `GC-TEST-0042` (balance: EUR 20.00)
5. Click "Apply" button

## Expected Result
- Order summary displays "Gift card: -€20.00" line item
- Order total updates to €29.00 (€49.00 − €20.00)
- No error messages displayed

## Actual Result (Failure Cases)
- Toast notification appears: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- Backend API error logged

## Technical Details

### Failed Request
```
POST /api/checkout/gift-card
Response Status: 500
Response Body: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

### Flakiness Pattern
- **Test Execution:** 10 repeated attempts on same commit (--repeat-each=10)
- **Pass Rate:** 7 passed (70%)
- **Fail Rate:** 3 failed (30%) — attempts 4, 7, and 9
- **Consistency:** Failed attempts produced identical error response
- **Pass Validation:** Passing attempts correctly displayed expected summary

## Root Cause Assessment
**Assumption:** The currency service is returning undefined/null values intermittently, likely due to a caching issue or race condition in the cache layer.

**Evidence:** 
- TypeError specifically indicates `currency` property is undefined
- Failures occur sporadically across attempts on the same build
- Same successful flow works consistently in 70% of cases
- Developer team note indicates prior history of currency service cache flakiness in the previous sprint

## Impact
- Release candidate 4.12.0-rc.2 cannot be validated for EUR market checkout with confidence
- E2E staging pipeline provides unreliable test results for gift card functionality
- Customer-facing checkout flow for EUR store carries risk of similar failures in production

## Recommended Actions
1. **Immediate:** Investigate currency service cache implementation and initialization logic
2. **Investigation Focus:** 
   - Currency service cache state management and refresh patterns
   - Race conditions between cart updates and currency lookups
   - Cache invalidation timing relative to gift card application requests
3. **Follow-up:** Review previous sprint's currency service cache fixes to determine if regression occurred
4. **Testing:** Add cache state assertions to test suite to catch similar issues earlier

## Files/Components to Review
- Gift card application endpoint handler
- Currency service and cache layer
- Cart/checkout currency resolution logic

## Attachment Notes
- CI pipeline run ID: e2e-staging #3318
- CI run timestamp: 2026-10-14 06:12 UTC
- Affected test file: checkout.spec.ts
