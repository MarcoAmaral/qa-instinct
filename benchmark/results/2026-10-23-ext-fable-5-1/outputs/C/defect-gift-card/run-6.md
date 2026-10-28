# Applying a gift card in EUR checkout intermittently fails with "Something went wrong"

| Field | Value |
| --- | --- |
| Status | New |
| Severity | High: a paying customer cannot use a gift card on about 3 in 10 attempts. Assumed; no severity scale was given. |
| Priority | Release blocker for 4.12.0. Assumed, because the failure is in a checkout path on a release candidate. |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | Staging, https://staging.shop.example, EUR store |
| Area | Checkout > Gift cards |
| Reported by | <account email, redacted>, from CI pipeline e2e-staging #3318 |
| Found on | 2026-10-14 06:12 UTC |
| Reproducibility | Intermittent: 3 failures in 10 runs of the same test on the same commit |

## Summary

When a customer applies a gift card at checkout in the EUR store, the request sometimes returns a server error. The customer sees the toast **Something went wrong. Please try again.** and the order total does not change. The same steps succeed on other attempts with no change to the build, the data or the browser.

## Steps to reproduce

1. Sign in to the EUR store as the test user `buyer.eur@shop.example`.
2. Add **Desk Lamp** (EUR 49.00) to the cart.
3. Open checkout.
4. Enter gift card `GC-TEST-0042` (balance EUR 20.00) in the gift card field.
5. Select **Apply**.
6. If the gift card applies, repeat steps 1 to 5. The failure appeared on 3 of 10 runs.

## Expected result

The order summary shows **Gift card: -€20.00** and the total changes to **€29.00**.

## Actual result

A toast shows **Something went wrong. Please try again.** The total stays at **€49.00** and the gift card is not applied.

## Evidence

Network request and response on each failing attempt:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Test and run details:

```text
Pipeline:  e2e-staging #3318, 2026-10-14 06:12 UTC
Spec:      checkout.spec.ts > gift card > applies a gift card to an order in EUR
Command:   --repeat-each=10 on commit 9f3c2ab
Result:    7 passed, 3 failed (attempts 4, 7 and 9)
Browser:   Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner
```

All 3 failures returned the same status code and the same response body. All 7 passing attempts showed the expected order summary.

## Impact

- A customer with a valid gift card may be unable to apply it and may pay the full amount or abandon the order.
- The toast tells the customer to try again but does not say why the gift card failed, so the customer cannot tell whether the card is at fault.
- The checkout end-to-end test is unreliable on this build, which blocks a clean sign-off of the release candidate.

## Notes for the investigating developer

- The response body exposes an internal error message to the browser. The customer-facing error should not include a stack message, whatever the root cause turns out to be.
- A developer on the team channel suggested the currency service cache, which was flaky last sprint. This is an unverified hypothesis, not a confirmed cause. Please record the actual cause on this ticket when found.
- The failure is not tied to the browser or the test data, because both were identical across passing and failing attempts.

## Assumptions made while writing this report

- The 500 response and the toast come from a server-side fault, not from the test harness. The log shows the browser received the 500 directly.
- The CI runner did not retry failed attempts automatically. The 7-to-3 split counts individual runs.
- No other gift card tests or currencies were run. Whether the same failure happens in other stores is unknown and should be checked.
- Server logs and request IDs for the 3 failing attempts were not in the CI output. Please attach them to this ticket if the pipeline keeps them.
- The product labels **Apply** and **Something went wrong. Please try again.** are taken from the test log. An editor should confirm they match the live interface.
