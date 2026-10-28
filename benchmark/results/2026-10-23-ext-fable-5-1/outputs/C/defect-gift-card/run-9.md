# Applying a gift card at checkout intermittently fails with a 500 error (EUR store)

**ID:** None: not yet filed; assign on creation
**Status:** New
**Severity:** High (assumed: the customer cannot use the gift card, and the release is a candidate build)
**Priority:** P1 for the 4.12.0 release (assumed; adjust if the 4.12.0 release does not go out with this build)
**Reported:** 2026-10-24
**Reporter:** QA automation, pipeline e2e-staging
**Component:** Checkout, gift card payments
**Assigned to:** None: no owner yet

## Summary

Applying a gift card at checkout fails on about 3 out of 10 attempts on build 4.12.0-rc.2. The shopper sees the toast **Something went wrong. Please try again.** and the order total does not change. The server returns a 500 error from the gift card endpoint with a `TypeError` about an undefined `currency` property. The same steps on the same build pass on the other attempts.

## Environment

| Item | Value |
| --- | --- |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | Staging, https://staging.shop.example |
| Store | EUR store |
| Browser | Chromium 129.0.6668.29 |
| Test runner | Playwright 1.48.1 on Ubuntu 22.04 |
| CI run | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Spec | `checkout.spec.ts` > gift card > applies a gift card to an order in EUR |

## Steps to reproduce

1. Sign in as the test user `buyer.eur@shop.example` in the EUR store.
2. Add **Desk Lamp** (EUR 49.00) to the cart.
3. Open checkout.
4. In the gift card field, enter `GC-TEST-0042`. The card has a balance of EUR 20.00.
5. Select **Apply**.
6. Repeat steps 1 to 5 up to 10 times on the same build. The failure does not occur every time.

## Expected result

The order summary shows **Gift card: -€20.00** and the total changes to €29.00.

## Actual result

A toast appears with the text **Something went wrong. Please try again.** The total stays at €49.00. The gift card is not applied.

The browser sends `POST /api/checkout/gift-card` and receives HTTP 500 with this body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency

The spec ran 10 times on the same commit with `--repeat-each=10`.

| Result | Attempts |
| --- | --- |
| Passed | 7 (attempts 1, 2, 3, 5, 6, 8, 10) |
| Failed | 3 (attempts 4, 7, 9) |

All 3 failures returned the same status code and the same response body. All 7 passes showed the expected summary.

## Evidence

- CI log for e2e-staging #3318, attempt 4 of 10, including the request and response for `POST /api/checkout/gift-card`.
- Assumed available: Playwright trace and screenshot for attempts 4, 7 and 9 in the run's artifacts. Attach them to this report when filing.
- Not yet collected: server-side logs for the gift card endpoint at the 3 failure times. Request these from the backend team with the timestamps of attempts 4, 7 and 9.

## Impact

A shopper who applies a gift card may get a generic error and a full-price total. The error message does not tell them the request can be retried safely. Shoppers in the EUR store are confirmed affected. Other currency stores are untested.

## Notes and open questions

- **Cause is not confirmed.** A developer on the team channel suggested the currency service cache, which was unreliable last sprint. This is a hypothesis, not a finding. The report records only what the test observed: an intermittent 500 and a `TypeError` on a `currency` property in the response.
- **Not yet known whether this is a regression.** No run of this spec on the previous build (4.11.x) is cited in the log. Run the same spec with `--repeat-each=10` on the previous release build to check.
- **Other stores are untested.** Run the matching spec, if one exists, in a non-EUR store to learn whether the failure depends on currency.
- **Retry behaviour is untested.** The toast tells the shopper to try again. Check whether a second **Apply** on the same session succeeds.

## Assumptions made in this report

- The 3 failures happened on separate test sessions, each starting from a fresh sign-in, as the spec steps describe.
- The gift card `GC-TEST-0042` kept a balance of EUR 20.00 across all 10 attempts, so balance was not the variable.
- The toast text, the summary line **Gift card: -€20.00** and the **Apply** button label are quoted from the log and match the interface exactly. Correct them if the product labels differ.
- Severity and priority are set by the reporter. The triage owner should confirm them.
