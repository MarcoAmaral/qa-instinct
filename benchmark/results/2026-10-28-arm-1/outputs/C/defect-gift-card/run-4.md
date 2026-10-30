---
title: Gift card application fails intermittently with currency service error
slug: gift-card-currency-service-error-3318
article_type: troubleshooting
product_area: Checkout
audience: Developer
plan_availability: None: internal defect report
reading_time: 2 min
related_articles: None: tracked in issue system
last_updated: 2026-10-28
---

# Gift card application fails intermittently with currency service error

Gift card application on EUR store checkout returns a 500 error and does not apply the discount. The failure appears random and correlates with currency service cache state.

## Symptom

When a test user applies a gift card during EUR store checkout, the request succeeds 70% of the time. On failure:
- User sees a toast: "Something went wrong. Please try again."
- Order total does not update (remains €49.00 instead of €29.00 after applying €20.00 gift card).
- Network request `POST /api/checkout/gift-card` returns 500.
- Response body: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

## Test case

**Build:** 4.12.0-rc.2 (commit 9f3c2ab)  
**Browser:** Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04  
**Base URL:** https://staging.shop.example

**Steps:**
1. Sign in as `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart and open checkout
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00)
4. Press "Apply"

**Expected:** Order summary shows "Gift card: -€20.00" and total of €29.00  
**Actual:** Toast error; total remains €49.00; 500 response with `Cannot read properties of undefined`

## Frequency and environment

- Reproducible: 3 failures in 10 attempts on the same commit with `--repeat-each=10`
- Attempts 4, 7, and 9 failed; attempts 1, 2, 3, 5, 6, 8, 10 passed
- All 3 failures returned identical error: `TypeError: Cannot read properties of undefined (reading 'currency')`

## Root cause assessment

The error occurs in the gift-card endpoint when reading a `currency` property on an undefined object. The property is accessed without a null check, suggesting:
- A dependency (likely the currency service) returns `null` or `undefined` instead of an object
- The failure is not deterministic on a single commit; cache state or timing is a factor

**Developer note:** Currency service cache reliability was flagged as flaky in the prior sprint.

## Information needed for investigation

- Stack trace from server logs for commit 9f3c2ab during the 06:12 UTC run
- Currency service cache implementation and invalidation logic
- Whether currency service calls are retried or have fallback behavior

---

**Assumptions:** This report assumes the `/api/checkout/gift-card` endpoint calls an external or cached currency service to look up exchange rates or validate the currency context. No assumptions made about the currency service's implementation.
