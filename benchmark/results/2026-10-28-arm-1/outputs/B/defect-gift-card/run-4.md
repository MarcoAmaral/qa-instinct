# Defect Report

**Severity:** High (Blocking checkout functionality)  
**Status:** New  
**Date Reported:** 2026-10-14  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Assignee:** Backend / Checkout Team  

## Summary
Gift card application on the staging environment intermittently fails with a 500 error when applying a valid EUR gift card to an order in checkout. The failure appears to be related to an undefined currency property in the gift card API endpoint, causing the order summary to fail to update and displaying an error toast to the user.

## Environment
- **Environment:** Staging (https://staging.shop.example)
- **Browser:** Chromium 129.0.6668.29, Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Currency:** EUR
- **Test Suite:** e2e-staging #3318
- **Test File:** checkout.spec.ts

## Steps to Reproduce
1. Sign in as test user `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to the cart
3. Navigate to checkout
4. Enter gift card code `GC-TEST-0042` (balance: EUR 20.00)
5. Press "Apply" button

**Note:** Intermittent issue — failure occurs inconsistently (3 out of 10 repeated attempts on same commit)

## Expected Result
- Order summary displays "Gift card: -€20.00"
- Order total updates to €29.00
- Gift card successfully applied with no error messages

## Actual Result
- Toast notification appears: "Something went wrong. Please try again."
- Order summary does not update
- Order total remains €49.00
- API endpoint returns 500 error

## Technical Details
- **Endpoint:** POST `/api/checkout/gift-card`
- **HTTP Status:** 500
- **Error Response:** `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
- **Occurrence:** Attempts 4, 7, and 9 of 10 repeated runs on the same commit

## Frequency & Reproducibility
- **Frequency:** Intermittent (30% failure rate on this build)
- **Reproducibility:** Low — occurs inconsistently even with identical conditions
- **Pattern:** No clear pattern identified; appears random across attempts

## Root Cause Analysis (Hypothesis)
Based on developer feedback and error signature, the currency service cache appears to be stale or returning undefined values in certain request sequences. The TypeError indicates that the gift card endpoint is attempting to access a `currency` property on an undefined object, likely from a cache miss or race condition in the currency service.

## Impact
- **User Impact:** Customers unable to apply gift cards to their orders; affects checkout completion
- **Scope:** EUR store affected; may also affect other currency configurations
- **Regression Risk:** This is a repeat issue from the previous sprint, indicating an unresolved systemic problem

## Recommended Actions
1. **Immediate:** Inspect currency service cache invalidation logic and TTL settings
2. **Investigation:** Review recent changes to gift card endpoint currency handling (commit 9f3c2ab and prior)
3. **Testing:** Verify fix covers both cached and cache-miss scenarios under concurrent load
4. **Follow-up:** Monitor frequency in subsequent builds to confirm resolution

## Related Issues
- Previous sprint incident with currency service cache flakiness (referenced by developer)

---

**Test Case ID:** checkout.spec.ts::gift card::applies a gift card to an order in EUR  
**CI Logs:** Pipeline e2e-staging #3318, Run 2026-10-14 06:12 UTC
