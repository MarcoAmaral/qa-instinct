---
title: Gift card application fails intermittently with currency service error in EUR checkout
slug: gift-card-currency-service-error
article_type: troubleshooting
product_area: Checkout
audience: Backend team, QA
plan_availability: N/A - internal defect report
reading_time: 4 min
related_articles: None - internal defect report
last_updated: 2026-10-28
---

# Gift card application fails intermittently with currency service error in EUR checkout

Gift card application fails randomly during checkout in EUR store, returning a "Something went wrong" error and leaving the order total unchanged. The backend reports an undefined currency property error.

## Symptom: TypeError reading undefined currency property

When a customer applies a gift card to an order in the EUR store, the POST `/api/checkout/gift-card` endpoint returns HTTP 500 with error:

```
TypeError: Cannot read properties of undefined (reading 'currency')
```

The customer sees a generic toast: "Something went wrong. Please try again." The order total does not update and the gift card is not applied.

**Test environment:** Staging build 4.12.0-rc.2 (commit 9f3c2ab), Chromium 129, Playwright 1.48.1, Ubuntu 22.04 runner.

**Reproducibility:** 3 failures in 10 consecutive attempts on the same build (attempts 4, 7, 9 passed on other attempts), against base URL `https://staging.shop.example`.

**Steps to reproduce:**
1. Sign in as `buyer.eur@shop.example` (EUR store).
2. Add "Desk Lamp" (EUR 49.00) to the cart.
3. Open checkout.
4. Enter gift card code `GC-TEST-0042` (balance EUR 20.00).
5. Select **Apply**.

**Expected:** Order summary displays "Gift card: -€20.00"; order total updates to €29.00.

**Actual:** Toast displays "Something went wrong. Please try again."; order total remains €49.00.

## Root cause: currency service cache inconsistency

The currency service cache returns an incomplete or null currency object on some requests. The checkout service attempts to read the `currency` property from an undefined object without a null check.

This matches a known flakiness reported last sprint. The cache is likely being accessed before it finishes initialization or after expiration without proper retry logic.

## How to fix it

**For immediate investigation:**
1. Check currency service initialization and cache TTL configuration in checkout service.
2. Add defensive null checks before accessing `currency` property in `/api/checkout/gift-card` handler.
3. Add retry logic with exponential backoff for currency service calls.

**For permanent resolution:**
1. Verify currency service cache invalidation and refresh logic during peak load.
2. Add structured logging to currency service calls to identify timing of cache misses.
3. Consider circuit breaker pattern if currency service is a known single point of failure.

## Information to collect for support

- Build and commit hash (provided: 4.12.0-rc.2, 9f3c2ab).
- Exact timestamp of failure (2026-10-14 06:12 UTC, attempts 4, 7, 9).
- Browser and test runner versions (provided).
- Currency service logs and cache metrics around 06:12 UTC on 2026-10-14.
- Checkout service logs for POST `/api/checkout/gift-card` in the same window.

## Severity and priority

**Severity:** High — feature-blocking for EUR store customers; generic error message obscures root cause.

**Priority:** High — reproducible in staging; affects checkout flow in multiple attempts; likely to reach production if not addressed.

**Impact:** EUR store; affects gift card feature; users receive confusing error with no actionable guidance.

## Updates

None yet.
