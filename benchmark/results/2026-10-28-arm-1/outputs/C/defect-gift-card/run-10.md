---
title: Gift card application fails intermittently with 500 error in EUR store
type: defect
severity: high
status: new
environment: staging
build: 4.12.0-rc.2 (commit 9f3c2ab)
date_reported: 2026-10-14
---

# Gift card application fails intermittently with 500 error in EUR store

## Summary

Gift card validation returns HTTP 500 with a currency property read error in approximately 30% of attempts when applying a gift card to an order in the EUR store checkout flow. The error indicates that the currency service returns an undefined value where a currency object is expected.

## Steps to reproduce

1. Sign in as a test user on the EUR store (buyer.eur@shop.example).
2. Add an item to the cart (for example, "Desk Lamp" at EUR 49.00).
3. Open the checkout page.
4. Enter a valid gift card code (for example, GC-TEST-0042 with a EUR 20.00 balance).
5. Select **Apply**.

## Expected behavior

The order summary updates to show the gift card deduction ("Gift card: -€20.00") and the new total (EUR 29.00). The POST request to `/api/checkout/gift-card` succeeds with HTTP 200.

## Actual behavior

A toast notification displays "Something went wrong. Please try again." The order total remains EUR 49.00. The POST request to `/api/checkout/gift-card` returns HTTP 500 with the response body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Test results

- Build: Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner
- Test: checkout.spec.ts > gift card > applies a gift card to an order in EUR
- Attempts (10 repeats, same commit): 7 passed, 3 failed
- Affected attempts: 4, 7, 9

## Root cause (suspected)

The currency service cache appears to be returning undefined or incomplete data intermittently. This aligns with flakiness reported in the previous sprint.

## Assumption

The error occurs in the gift card validation endpoint when attempting to access a currency property on an undefined object, likely during a cache miss or stale cache state for EUR store configuration.

## Impact

- Feature: Gift card redemption in checkout
- Scope: EUR store only (assumed; test uses EUR-specific user)
- User-facing: Error prevents checkout completion; users must retry or contact support
