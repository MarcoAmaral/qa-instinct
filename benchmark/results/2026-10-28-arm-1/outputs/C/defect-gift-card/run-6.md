---
title: Gift card application fails intermittently for EUR orders with currency service error
type: defect
severity: high
component: checkout
status: open
created: 2026-10-14
---

## Summary

Gift card application fails intermittently during E2E testing for EUR currency orders. The `/api/checkout/gift-card` endpoint returns a 500 error due to missing `currency` property in the currency service response.

## Description

When applying a gift card (GC-TEST-0042, EUR 20.00) to a checkout in the EUR store, the operation succeeds inconsistently. The user sees a generic toast error ("Something went wrong. Please try again.") and the order total remains unchanged.

The server responds with a 500 error containing: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`. This indicates the backend is attempting to read a `currency` property from an undefined object, likely during gift card discount calculation.

## Reproduction

**Test:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

1. Sign in as buyer.eur@shop.example (EUR store account)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Open checkout
4. Enter gift card code GC-TEST-0042 (balance EUR 20.00)
5. Press "Apply" button

**Expected:** Order summary displays "Gift card: -€20.00"; order total updates to €29.00

**Actual:** Toast displays "Something went wrong. Please try again."; order total remains €49.00; network request returns 500

## Frequency

Intermittent: 3 failures in 10 attempts (30% failure rate) on build 4.12.0-rc.2 (commit 9f3c2ab)
- Attempt 4: failed
- Attempts 5-6: passed  
- Attempt 7: failed
- Attempt 8: passed
- Attempt 9: failed
- Attempt 10: passed

## Environment

- Build: 4.12.0-rc.2 (commit 9f3c2ab)
- Browser: Chromium 129.0.6668.29
- Test Framework: Playwright 1.48.1
- Runner OS: Ubuntu 22.04
- Base URL: https://staging.shop.example
- CI Run: 2026-10-14 06:12 UTC, pipeline e2e-staging #3318

## Suspected Cause

Currency service cache timeout or staleness. The error occurs specifically in EUR currency context and intermittently, suggesting a race condition or cache invalidation issue. Developer notes indicate similar flakiness occurred in the previous sprint.

The endpoint likely queries currency service for exchange rates or validation but receives an incomplete or undefined response, missing the `currency` property needed for discount calculation.

## Investigation Needed

1. Review `/api/checkout/gift-card` implementation for currency service dependency
2. Check currency service cache invalidation logic and TTL
3. Verify EUR currency configuration in staging environment
4. Review recent changes to gift card discount or currency handling (commit 9f3c2ab and related)
5. Correlate timing of test failures with currency service cache events

## Related

- Previous currency service flakiness noted in prior sprint
- Affects EUR store only; USD and other currencies not tested in this failure
- Non-blocking: 70% pass rate allows functionality to work in production, but reliability is insufficient for release
