# Defect Report: Gift Card Application Fails Intermittently with Currency Service Error

## Summary
Gift card application fails intermittently during checkout on the EUR store with a 500 Internal Server Error. The API response indicates a null reference in the currency service, resulting in a failed transaction and user-facing error.

## Environment
- **Build:** 4.12.0-rc.2 (commit 9f3c2ab)
- **Test Environment:** https://staging.shop.example
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Test File:** checkout.spec.ts
- **Test Case:** checkout.spec.ts > gift card > applies a gift card to an order in EUR

## Severity
**High** – Transactional failure affecting checkout functionality on production-equivalent staging environment.

## Steps to Reproduce
1. Sign in as buyer.eur@shop.example (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (balance: EUR 20.00)
5. Click "Apply" button

## Expected Behavior
- Order summary displays: "Gift card: -€20.00"
- Order total updates to: €29.00
- Toast notification confirms successful application

## Actual Behavior
- Toast message displays: "Something went wrong. Please try again."
- Order total remains: €49.00
- API request returns HTTP 500

## Root Cause
Backend error occurs when processing the gift card application:
- **API Endpoint:** POST /api/checkout/gift-card
- **HTTP Status:** 500 Internal Server Error
- **Error Message:** `TypeError: Cannot read properties of undefined (reading 'currency')`
- **Root Cause Analysis:** Currency object is undefined when the gift card service attempts to read its `currency` property. Likely occurs due to incomplete or stale currency service state/cache.

## Flakiness Pattern
- **Test Run:** 10 attempts with --repeat-each=10 on the same build
- **Pass Rate:** 70% (7/10 passed)
- **Failure Rate:** 30% (3/10 failed)
- **Failed Attempts:** #4, #7, #9
- **Pattern:** Non-deterministic; no clear ordering pattern; currency service state appears inconsistent between runs

## Assumptions
- The currency service cache is shared across test instances and may not be properly isolated or reset between attempts
- GC-TEST-0042 is a valid test gift card in the EUR store currency
- The 7 passing attempts all completed without error, indicating the feature works when the currency service state is correct

## Recommended Actions
1. **Immediate Investigation:** Review currency service initialization and cache management in the gift card API handler
2. **Test Fix:** Ensure test setup includes currency service cache reset or warm-up before each attempt
3. **Code Review:** Verify null-safety checks exist before accessing `currency` property in gift card processing logic
4. **Regression Prevention:** Add unit tests for gift card application with various currency states, including undefined/null scenarios

## Related Information
- Developer note suggests this is a recurring issue from the previous sprint
- Currency service flakiness appears to be a known systemic issue requiring broader investigation
