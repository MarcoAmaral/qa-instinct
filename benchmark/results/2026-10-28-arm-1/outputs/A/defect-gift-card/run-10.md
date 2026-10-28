# Defect Report: Gift Card Application Fails with Currency Service Error

**Title:** Gift card checkout fails intermittently with "Cannot read properties of undefined (reading 'currency')"

**Severity:** High

**Status:** Open

**Build Version:** 4.12.0-rc.2 (commit 9f3c2ab)

---

## Summary

The gift card application flow on staging fails intermittently (30% failure rate) when applying a gift card to an order in EUR. The checkout API returns a 500 error indicating the currency property is undefined, preventing the order summary from displaying the discount.

---

## Reproduction Details

**Environment:**
- Base URL: https://staging.shop.example
- Browser: Chromium 129.0.6668.29, Playwright 1.48.1
- OS: Ubuntu 22.04
- Test: `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

**Steps to Reproduce:**
1. Sign in as buyer.eur@shop.example (EUR store account)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (balance EUR 20.00)
5. Press "Apply" button

**Failure Rate:**
- 7 passed, 3 failed out of 10 consecutive attempts
- Failures occurred on attempts 4, 7, and 9
- Same error signature across all failures

---

## Failure Details

**Expected Behavior:**
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00

**Actual Behavior:**
- Toast notification: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- Network request fails: `POST /api/checkout/gift-card → 500`

**Error Response:**
```
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

---

## Root Cause Analysis (Preliminary)

The error indicates a null/undefined reference to a currency object in the gift card processing pipeline. The intermittent nature (70% pass rate) and developer comment suggest a **race condition or cache inconsistency in the currency service**, likely:
- Currency data not yet loaded when gift card validation begins
- Stale or missing currency cache entry for EUR
- Concurrency issue between currency service initialization and gift card endpoint call

---

## Impact

- **Feature:** Gift card redemption is broken for EUR stores on staging
- **Risk:** Release blocker if this behavior exists in production
- **Scope:** Multi-currency checkout flow; likely affects other currencies as well

---

## Recommended Actions

1. **Immediate:** Investigate currency service cache initialization and lifecycle in the gift card checkout flow
2. **Investigation:** Check if currency service has race conditions with concurrent requests
3. **Testing:** Add race condition test cases for multi-currency checkout scenarios
4. **Verification:** Confirm whether issue exists in production or is staging-specific
