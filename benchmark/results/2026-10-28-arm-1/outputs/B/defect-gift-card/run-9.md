# Defect Report: Gift Card Application Fails with Currency Service Error

## Summary
Gift card application endpoint returns 500 error intermittently (3 of 10 attempts) when processing EUR currency gift cards, preventing successful order discount.

## Environment
- **Build Version:** 4.12.0-rc.2 (commit 9f3c2ab)
- **Browser:** Chromium 129.0.6668.29
- **Test Framework:** Playwright 1.48.1
- **OS:** Ubuntu 22.04
- **Base URL:** https://staging.shop.example
- **Test Store Currency:** EUR

## Steps to Reproduce
1. Sign in as test user `buyer.eur@shop.example` (EUR store)
2. Add "Desk Lamp" (EUR 49.00) to cart
3. Navigate to checkout
4. Enter gift card code `GC-TEST-0042` (balance: EUR 20.00)
5. Click "Apply" button

## Expected Result
- Order summary displays "Gift card: -€20.00" line item
- Order total updates to €29.00

## Actual Result
- Toast notification displays: "Something went wrong. Please try again."
- Order total remains €49.00 (gift card not applied)
- Endpoint `/api/checkout/gift-card` returns HTTP 500

## Error Details
- **Response Status:** 500 Internal Server Error
- **Response Body:** `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
- **Root Cause (Technical):** Null/undefined reference exception when attempting to access `currency` property; suggests currency service data structure is undefined or not properly initialized

## Flakiness
- **Pass Rate:** 70% (7 of 10 repeat attempts passed)
- **Failure Rate:** 30% (3 of 10 repeat attempts failed)
- **Failed Attempts:** #4, #7, #9
- **Failure Pattern:** Intermittent; indicates timing-dependent or state-dependent bug rather than deterministic logic error

## Severity
**High** – Feature completely non-functional when failure occurs; end-user cannot apply gift cards; impacts checkout flow and revenue.

## Assumptions
- Gift card `GC-TEST-0042` is valid and funded for all test attempts
- Currency service is a shared backend dependency that retrieves/caches exchange rate or locale data
- Cache invalidation or initialization timing is the likely root cause based on developer note

## Investigation Notes
Team developer indicated this is likely related to **currency service cache flakiness** (recurrence from previous sprint). Suspect:
- Cache miss or race condition during gift card currency validation
- Improper null-check before accessing currency object properties
- Currency service initialization timing issue in request pipeline

## Recommendation
- **Priority:** P1 (release blocker for EUR store checkout)
- **Owner:** Backend team (gift-card API handler + currency service)
- **Action Items:**
  1. Add defensive null-check before currency property access
  2. Audit currency service cache initialization and TTL
  3. Add structured logging to `/api/checkout/gift-card` endpoint to capture cache state on failures
  4. Consider circuit breaker or fallback mechanism for currency service dependency
