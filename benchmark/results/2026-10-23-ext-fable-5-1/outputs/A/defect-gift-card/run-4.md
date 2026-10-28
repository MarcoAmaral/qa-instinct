# Defect Report: Intermittent 500 on gift card apply in EUR checkout (`undefined.currency` TypeError)

**Severity:** High. Blocks a core checkout path for affected requests and surfaces a generic error to the customer.
**Priority:** High. Reproduces at a 30% rate on the release candidate.
**Component:** Checkout API, gift card endpoint (`POST /api/checkout/gift-card`)
**Build:** 4.12.0-rc.2, commit 9f3c2ab
**Environment:** staging (https://staging.shop.example), Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 CI runner
**Detected by:** pipeline e2e-staging #3318, 2026-10-14 06:12 UTC
**Spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Summary

Applying a gift card at checkout in the EUR store intermittently fails with an HTTP 500. The response body exposes a server-side TypeError: `Cannot read properties of undefined (reading 'currency')`. The customer sees a generic "Something went wrong" toast and the gift card is not applied. The failure is non-deterministic: across 10 runs of the same test on the same commit, 3 failed and 7 passed.

## Steps to reproduce

1. Sign in on staging as `buyer.eur@shop.example` (EUR store).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat the full flow several times. The failure appeared on attempts 4, 7 and 9 of 10 in CI.

A single run is not sufficient to reproduce. Run the spec with `--repeat-each=10` or higher.

## Expected result

The order summary shows "Gift card: -€20.00" and the total updates to €29.00. The API returns a 2xx response.

## Actual result

- UI shows the toast "Something went wrong. Please try again." and the total stays at €49.00.
- Network: `POST /api/checkout/gift-card` responds with status 500.
- Response body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency

| Runs on this build | Passed | Failed |
|---|---|---|
| 10 (`--repeat-each=10`) | 7 | 3 |

All three failures returned the identical status and body.

## Analysis and observations

- **The error is server-side, not a test or browser flake.** The API returns a 500 with a stack-level TypeError, so the request reaches the server and crashes in application code. The passing runs confirm the test itself and the request shape are valid.
- **Some object that should carry a `currency` field is undefined on the failing path.** Likely candidates are the resolved store/locale context, the cart or order record, or the gift card lookup result. The code dereferences `.currency` without a null guard.
- **Non-determinism on identical input points to shared state or timing.** The same user, cart and gift card produce different outcomes, which suggests a cache miss or eviction, a race between cart creation and the gift card call, or load-balanced instances with inconsistent state.
- **The developer's suggestion is unconfirmed.** A note on the team channel attributes this to the currency service cache, which was reportedly flaky last sprint. That is a plausible hypothesis consistent with the symptom, but it is not verified by anything in this log. It should be treated as a lead, not a root cause.
- **Two separate defects are present.** Even if the undefined value is a cache issue, the endpoint should not return 500 with a raw exception message in the body. That leaks internal details and gives the customer no actionable feedback.

## Assumptions

- The developer's "currency service cache" refers to a server-side cache in the checkout or pricing service. Its ownership and location are not stated in the log.
- No server-side logs or stack traces beyond the response body were available. Assumed the 500 originates in the gift card endpoint handler or a service it calls synchronously.
- The 7 passing runs returned the correct total, so the gift card balance and user fixture data are assumed to be correct and stable.
- The spec was retried via `--repeat-each` on the same commit without any deploy between attempts, so environment drift between runs is assumed to be minimal.
- Not confirmed whether the same failure occurs in non-EUR stores or with other gift cards. Assumed not yet tested.

## Suggested investigation

1. Pull server logs for the three failing requests, matched by timestamp from the CI run, and get the full stack trace to identify which object is undefined.
2. Check whether the currency service cache can return undefined on a miss, on expiry, or during warm-up, and whether the gift card handler handles that case.
3. Compare request timing between passing and failing attempts to see if the failure correlates with cart age or first-request-after-idle.
4. Verify whether the issue reproduces for USD and GBP stores and for other gift card codes.
5. Review last sprint's incident on the currency service cache for an earlier fix or a known regression.

## Suggested remediation (for the owning team to confirm)

- Guard the `.currency` access and fail fast with a meaningful error if the upstream object is missing.
- Return a 4xx or a structured 5xx with a user-safe message. Do not expose the raw exception text in the API response.
- Add a regression test that simulates a currency lookup returning undefined and asserts a graceful failure.

## Attachments and references

- CI run: e2e-staging #3318, 2026-10-14 06:12 UTC
- Playwright trace and network HAR for attempts 4, 7 and 9 (assumed retained by the pipeline, not included here)
- Team channel note from the developer suggesting a currency service cache cause
