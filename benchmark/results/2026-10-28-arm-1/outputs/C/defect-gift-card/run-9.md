---
title: Gift card application fails with TypeError when processing EUR store orders
slug: gift-card-eur-500-error
article_type: troubleshooting
product_area: Checkout
audience: Developer
plan_availability: None: internal defect report
reading_time: 2 min
related_articles: None: no related articles yet
last_updated: 2026-10-28
---

# Gift card application fails with TypeError when processing EUR store orders

Gift card redemption on the EUR store intermittently returns a 500 error during checkout, preventing order completion. The error occurs in the currency service when applying a valid gift card.

## Failure details

**Symptom:** User receives "Something went wrong. Please try again." toast when applying a gift card to an order, and the order total does not update.

**Error:** `TypeError: Cannot read properties of undefined (reading 'currency')` from POST `/api/checkout/gift-card`

**Frequency:** Intermittent. Test run #3318 (build 4.12.0-rc.2, commit 9f3c2ab) failed 3 of 10 attempts with identical error; 7 attempts passed.

**Environment:**
- Base URL: https://staging.shop.example
- Browser: Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner
- Test user: buyer.eur@shop.example (EUR store)

## Reproduction steps

1. Sign in to the EUR store as a test user.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card GC-TEST-0042 (balance EUR 20.00) and press "Apply".

**Expected:** Order summary shows "Gift card: -€20.00" and total updates to €29.00.

**Actual:** Toast shows "Something went wrong. Please try again." and total remains €49.00.

## Likely cause

Currency service cache is stale or missing data for EUR store, returning undefined when the gift-card endpoint tries to read the currency property. The flakiness (3 failures out of 10 attempts, all with the same error) and the developer note about cache issues last sprint indicate a race condition or cache invalidation problem.

## To fix

1. Verify the currency service cache initialization for the EUR store.
2. Add null/undefined checks in the gift-card endpoint before accessing the `currency` property.
3. Add cache invalidation or TTL review for multi-currency support.

## To collect before investigating

- Full server logs from 2026-10-14 06:12 UTC run, focusing on currency service calls during failed attempts 4, 7, and 9.
- Currency cache state or hit/miss rate during the test run.
- Whether the issue reproduces on commits before the last cache refactor.
