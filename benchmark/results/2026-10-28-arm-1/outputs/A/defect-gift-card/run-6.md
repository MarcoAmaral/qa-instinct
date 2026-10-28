# Defect Report: Gift Card Application Fails Intermittently in EUR Staging Checkout

**Report Date:** 2026-10-28  
**CI Run:** e2e-staging #3318 (2026-10-14 06:12 UTC)  
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Status:** Intermittent/Flaky

## Summary
The gift card application flow in EUR staging checkout fails intermittently with a 500 error caused by an undefined property access in the currency service. The same code passes in 70% of runs and fails in 30% of repeated attempts, indicating a race condition or caching issue rather than a deterministic bug.

## Environment
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04 (runner)
- **Base URL:** https://staging.shop.example
- **Test Account:** buyer.eur@shop.example (EUR store)

## Reproduction Steps
1. Sign in as test user with EUR locale
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code `GC-TEST-0042` (EUR 20.00 balance)
5. Click "Apply"

## Failure Details

**Expected Result:**  
Order summary displays "Gift card: -€20.00" with order total €29.00

**Actual Result:**  
Toast notification appears: "Something went wrong. Please try again."  
Order total remains €49.00; gift card not applied

**Error Response:**  
```
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Reproducibility
- **Flakiness Rate:** 30% (3 failures out of 10 attempts on identical commit)
- **Affected Attempts:** #4, #7, #9
- **Passing Attempts:** #1, #2, #3, #5, #6, #8, #10
- **Pattern:** Failures scattered across attempts; no deterministic trigger identified

## Root Cause Assessment

**Primary Suspect:** Currency service cache inconsistency (per developer note)  
**Hypothesis:** The currency service cache may contain a partially initialized state or stale entry during concurrent requests, causing the `currency` property to be undefined when accessed by the gift card application endpoint.

**Secondary Considerations:**
- Race condition between cart update and currency service cache refresh
- Timing-dependent initialization of currency configuration in staging environment
- Possible state leak between test attempts

## Impact
- **Severity:** Medium
- **Area Affected:** EUR store checkout with gift cards
- **User Impact:** Intermittent checkout failures requiring retry
- **Release Risk:** Blocks promotion of build 4.12.0-rc.2 to production; requires investigation and fix before release

## Recommended Investigation
1. Review currency service cache initialization and TTL settings
2. Examine request sequencing and potential race conditions in gift card application flow
3. Add logging to capture currency service state at failure moment
4. Consider cache invalidation strategy or synchronization mechanism for currency data
5. Re-run test suite with extended logging enabled to capture cache state during failures
