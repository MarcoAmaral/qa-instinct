# Applying a gift card at checkout intermittently fails with "Something went wrong" (EUR store)

**ID:** Assumed to be assigned by the tracker on filing
**Reported:** 2026-10-24
**Reporter:** <account email, redacted>
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)
**Pipeline:** e2e-staging #3318, run 2026-10-14 06:12 UTC
**Severity:** High. A customer-facing checkout step fails on a release candidate with no workaround visible to the customer.
**Priority:** Assumed P1 until the release manager decides otherwise, because 4.12.0-rc.2 is a release candidate.
**Status:** New
**Assignee:** Unassigned. Assumed to be the checkout team, because the failing endpoint belongs to checkout.

## Summary

On the EUR staging store, applying a valid gift card at checkout sometimes shows the toast **Something went wrong. Please try again.** instead of the discount. The request to the gift card endpoint returns an HTTP 500. The order total does not change. The failure is intermittent: 3 of 10 identical runs on the same commit failed.

## Environment

| Item | Value |
| --- | --- |
| Base URL | https://staging.shop.example |
| Store | EUR store, signed in as buyer.eur@shop.example |
| Browser | Chromium 129.0.6668.29 |
| Test runner | Playwright 1.48.1 on Ubuntu 22.04 |
| Spec | checkout.spec.ts > gift card > applies a gift card to an order in EUR |

## Steps to reproduce

1. Sign in to the EUR store as buyer.eur@shop.example.
2. Add **Desk Lamp** (EUR 49.00) to the cart.
3. Open checkout.
4. In the gift card field, enter `GC-TEST-0042` (balance EUR 20.00).
5. Select **Apply**.
6. If the discount appears, repeat steps 1 to 5. The failure appeared in about 3 of 10 runs.

## Expected result

The order summary shows **Gift card: -€20.00** and the total changes to €29.00.

## Actual result

A toast shows **Something went wrong. Please try again.** The total stays at €49.00. The browser receives this response:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Reproducibility

Intermittent. With `--repeat-each=10` on the same commit, attempts 4, 7 and 9 failed. The 7 other attempts passed and showed the expected summary. All 3 failures returned the same status and body.

## Evidence

- CI run e2e-staging #3318, failure at attempt 4 of 10.
- Response status and body as shown above.
- Assumed available but not yet attached: Playwright trace, screenshot of the toast, and the HAR file for the failed attempts. The assignee should pull these from the CI artifacts for run #3318.

## Observations

- The server returns a JavaScript error message in the response body. Customers can see internal error text in the network response. This is a separate, lower-severity issue and should be filed on its own if it is not already tracked.
- The failure is consistent in shape across all 3 failed attempts. It is not a timeout and not a test flake in the browser. The server rejected the request each time.
- The data did not change between attempts. The same user, product, gift card and currency produced both passes and failures.

## Root cause

Not confirmed. A developer suggested on the team channel that the currency service cache is the cause, and noted that it was flaky last sprint. That is a hypothesis, not a finding. This report does not assert a cause. The assignee should verify against server logs before fixing.

## Suggested next steps for the assignee

1. Pull server logs for the 3 failing requests from run #3318 and capture the stack trace for the TypeError.
2. Check whether the gift card balance or the order changed on any failed attempt, so a customer cannot lose balance on a request that reports failure.
3. Check whether the failure also occurs on stores with other currencies, such as USD or GBP.
4. If the currency service cache is involved, link the ticket from last sprint so the history is in one place.

## Assumptions

- The gift card `GC-TEST-0042` is a shared staging fixture and its balance was EUR 20.00 at the start of every attempt. If a failed attempt deducted balance, later attempts would behave differently, and the 7 passes suggest it did not.
- The failure is not specific to Playwright or Chromium, because the error comes from the server, not the browser.
- Production is not yet affected, because the build is a release candidate on staging. This should be confirmed before 4.12.0 ships.
- The interface labels **Apply**, **Something went wrong. Please try again.** and **Gift card: -€20.00** are taken from the test log and match what the customer sees.
