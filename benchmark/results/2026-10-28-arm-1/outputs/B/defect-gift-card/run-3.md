# Defect Report: Gift Card Application Fails with Currency Service Error

**Report ID:** QA-2026-1014-001  
**Date:** 2026-10-28  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Status:** Open  

---

## Summary

The gift card application feature fails intermittently during checkout in the EUR store environment. When applying a valid gift card, the API returns a 500 error indicating an undefined currency property, preventing the order summary from updating and presenting an error toast to the user. The failure is non-deterministic, occurring in 3 of 10 test attempts (30% failure rate).

---

## Environment

| Property | Value |
|----------|-------|
| **Test URL** | https://staging.shop.example |
| **Test Browser** | Chromium 129.0.6668.29 |
| **Test Framework** | Playwright 1.48.1 |
| **OS** | Ubuntu 22.04 |
| **Test Spec** | checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| **Execution Date/Time** | 2026-10-14 06:12 UTC |
| **Pipeline** | e2e-staging #3318 |

---

## Test Execution Summary

- **Total Attempts:** 10 (--repeat-each=10)
- **Passed:** 7
- **Failed:** 3
- **Failure Rate:** 30%
- **Failed Attempts:** 4, 7, 9
- **Failure Pattern:** Non-deterministic / intermittent

---

## Steps to Reproduce

1. Authenticate as test user `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout page
4. Enter gift card code: `GC-TEST-0042` (balance: EUR 20.00)
5. Click "Apply" button

---

## Expected Result

- Order summary updates to show: "Gift card: -€20.00"
- Order total updates from €49.00 to €29.00
- No error messages displayed

---

## Actual Result

- A toast notification displays: "Something went wrong. Please try again."
- Gift card is not applied
- Order total remains €49.00
- API call fails with HTTP 500 error

---

## Error Details

**Failed Endpoint:** `POST /api/checkout/gift-card`  
**HTTP Status:** 500  
**Response Body:**
```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

**Error Type:** Runtime TypeError  
**Root Cause Indicator:** The code attempts to access the `currency` property on an undefined object, suggesting the currency service or currency object is not properly initialized or cached.

---

## Severity & Priority

| Aspect | Rating |
|--------|--------|
| **Severity** | High |
| **Priority** | High |
| **Blocker for Release** | Yes (rc.2 is a release candidate) |
| **User Impact** | Purchase flow broken for affected transactions |

---

## Root Cause Analysis (Preliminary)

**Primary Hypothesis:** Currency service cache inconsistency or race condition.

**Evidence:**
1. Failure is non-deterministic (3 of 10 passes on same build/commit)
2. Error indicates missing currency context at API request time
3. Team developer notes indicate this component exhibited flakiness in the previous sprint
4. Test uses EUR currency; failure specific to currency-dependent operation
5. Passing and failing attempts occur within the same test run, same build

**Likely Causes:**
- Currency service cache not initialized or invalidated between requests
- Race condition between currency service initialization and gift card application request
- Stale or missing currency object in checkout session state
- Concurrent request handling causing currency context loss

---

## Assumptions Made

- Gift card `GC-TEST-0042` is valid and active in the staging environment
- The test user `buyer.eur@shop.example` is properly provisioned with EUR store access
- Network connectivity and staging infrastructure were stable during test execution
- The Playwright test setup and teardown are functioning correctly

---

## Recommendations

1. **Immediate:** Investigate currency service initialization and caching logic in `/api/checkout/gift-card` endpoint
2. **Add Debugging:** Enable logging to capture currency object state and cache hit/miss during gift card requests
3. **Review:** Check for race conditions between currency service setup and checkout API calls
4. **Fix Verification:** Add specific unit tests for currency context availability in gift card handler
5. **Stabilization:** Increase test sample size (>10 attempts) after fix to confirm stability
6. **Follow-up:** Review similar currency-dependent operations for the same issue pattern

---

## Attachments / Related Items

- Failed test attempts: 4/10, 7/10, 9/10
- Passing attempts: All others
- Related Sprint Issue: Currency service flakiness noted in previous sprint
