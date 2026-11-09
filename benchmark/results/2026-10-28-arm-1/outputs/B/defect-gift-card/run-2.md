# Defect Report

**Title:** Gift card application fails intermittently with 500 error in EUR checkout

**Severity:** High (Payment flow blocker)

**Status:** Open

**Reported Date:** 2026-10-14

---

## Summary

The gift card application feature fails intermittently during the EUR store checkout flow, returning a 500 error with a currency service error. The test demonstrates a 30% failure rate (3 of 10 attempts) with identical error signatures, suggesting a timing-dependent or cache-related issue.

---

## Environment

| Property | Value |
|----------|-------|
| Build Version | 4.12.0-rc.2 |
| Commit | 9f3c2ab |
| Browser | Chromium 129.0.6668.29 |
| Test Framework | Playwright 1.48.1 |
| OS | Ubuntu 22.04 |
| Test Environment | staging.shop.example |
| Test Spec | checkout.spec.ts › gift card › applies a gift card to an order in EUR |

---

## Reproduction Steps

1. Sign in as `buyer.eur@shop.example` (EUR store account)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Navigate to checkout
4. Enter gift card code `GC-TEST-0042` (balance: EUR 20.00)
5. Click "Apply" button

---

## Expected Result

- Order summary displays: "Gift card: -€20.00"
- Order total updates to: €29.00

---

## Actual Result

- Toast notification displays: "Something went wrong. Please try again."
- Order total remains: €49.00 (gift card not applied)

---

## Error Details

**Endpoint:** `POST /api/checkout/gift-card`

**Status Code:** 500 Internal Server Error

**Response Body:**
```json
{
  "error": "TypeError: Cannot read properties of undefined (reading 'currency')"
}
```

---

## Flakiness Profile

- **Total Attempts:** 10 (with --repeat-each=10)
- **Passed:** 7
- **Failed:** 3
- **Failure Rate:** 30%
- **Consistent Failures:** Attempts 4, 7, and 9 (same error signature)

---

## Root Cause Analysis

**Hypothesis:** Currency service caching issue (unresolved from previous sprint)

The error indicates the currency object is undefined when the gift card API handler attempts to read the `currency` property. This is consistent with a cache coherency problem where:
- Currency data is not populated before the gift card validation runs
- Cache refresh timing is inconsistent
- Multi-tenancy currency context is not properly initialized in some request cycles

---

## Impact

- Payment flow unreliability in EUR locale
- Checkout abandonment risk during peak load (higher concurrency = higher cache contention likelihood)
- Regression validation blocked for 4.12.0-rc.2 release candidate

---

## Assumptions

- Gift card `GC-TEST-0042` exists with EUR 20.00 balance in staging
- The test is correctly authored and assertions are accurate
- "Currency service cache" refers to an in-process or external cache mechanism used for exchange rates or locale-specific currency metadata

---

## Recommended Actions

1. **Immediate:** Review currency initialization in the gift card validation handler (`/api/checkout/gift-card`) for race conditions or missing cache lookups
2. **Investigation:** Enable request-level logging to capture currency context and cache state during failed attempts
3. **Validation:** Verify currency cache TTL, invalidation logic, and warm-up behavior on service restart
4. **Testing:** Run extended flakiness testing (50+ attempts) to characterize failure distribution
5. **Staging:** Rotate staging environment credentials and warm currency caches before running release validation
