# Defect Report: Gift card application in EUR checkout intermittently fails with HTTP 500

**Severity:** High. Customers with a valid gift card can be blocked from paying with it, and the UI gives no actionable guidance.
**Priority:** High. The failure reproduces on the release candidate for 4.12.0.
**Component:** Checkout API, gift card endpoint (`POST /api/checkout/gift-card`)
**Build:** 4.12.0-rc.2, commit 9f3c2ab
**Environment:** staging, https://staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 CI runner
**Detected by:** pipeline e2e-staging #3318, 2026-10-14 06:12 UTC
**Failing spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Summary

Applying a gift card to a EUR order fails intermittently. The gift card endpoint returns HTTP 500 with a `TypeError` from the server, the storefront shows a generic error toast, and the order total is left unchanged. On the same commit, 3 of 10 repeated attempts failed with an identical status and response body. The 7 passing attempts produced the expected summary, so the behavior is non-deterministic at the server rather than a test timing issue.

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` (EUR store).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat the whole flow several times. The failure occurred on roughly 3 in 10 runs with `--repeat-each=10`.

## Expected result

The order summary shows "Gift card: -€20.00" and the total becomes €29.00. The API responds with a success status.

## Actual result

The storefront shows a toast "Something went wrong. Please try again." and the total stays €49.00.

Network response:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Occurrence data

| Attempt | Result |
|---|---|
| 1, 2, 3, 5, 6, 8, 10 | Passed, expected summary shown |
| 4, 7, 9 | Failed, HTTP 500, identical response body |

## Analysis and notes

- The response body exposes an unhandled server exception. Some object the handler expects to carry a `currency` field is undefined at the point of access. The most likely candidates are the cart, the gift card record, or a store or currency lookup result that is sometimes missing.
- A developer suggested on the team channel that this is "probably the currency service cache again" and that it was flaky last sprint. This is a plausible lead but has not been verified. Treat it as a hypothesis, not a root cause.
- The failure is independent of browser behaviour: the request reaches the server and the server itself returns 500. The test assertions are secondary to that.
- A raw `TypeError` message in a public API response is a separate, smaller defect. The endpoint should return a structured error and log the stack trace server side.

## Assumptions

- The gift card `GC-TEST-0042` has a valid EUR balance throughout the run, and no other test consumes it concurrently. If gift card balance is shared across parallel workers, that should be ruled out first.
- The staging backend was not redeployed during the ten attempts, since all ran against the same build.
- No server-side logs were attached to the CI run. Server logs for the three failing requests are needed to confirm which object was undefined.

## Suggested next steps

1. Pull server logs and the stack trace for the three failing requests around 06:12 UTC on 2026-10-14 to identify the exact line that reads `currency`.
2. Check whether the currency or store lookup used by the gift card handler can return undefined on a cache miss, timeout, or cold start, and whether it is guarded.
3. If the prior sprint's flakiness has a ticket, link it here and compare the stack traces.
4. Add a guard and a structured error response so an upstream failure degrades to a clear message rather than a 500 with a raw exception.
5. Re-run the spec with `--repeat-each=20` or more on the fix to confirm the intermittent failure is gone.

## Attachments

- CI run e2e-staging #3318 (log excerpt included above).
- Playwright trace and network HAR for attempts 4, 7 and 9, if retained by the pipeline.
