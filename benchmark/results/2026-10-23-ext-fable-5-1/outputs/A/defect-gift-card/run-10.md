# Defect Report: POST /api/checkout/gift-card intermittently returns 500 (TypeError on `currency`) in EUR checkout

**ID:** to be assigned
**Severity:** High. Blocks gift card redemption for affected requests and surfaces a generic error to the customer.
**Priority:** High. Reproduces on a release candidate (4.12.0-rc.2) at a 30% rate.
**Component:** Checkout API, gift card endpoint
**Environment:** staging (https://staging.shop.example), build 4.12.0-rc.2, commit 9f3c2ab
**Detected by:** CI pipeline e2e-staging #3318, 2026-10-14 06:12 UTC
**Status:** Open

## Summary

Applying a gift card at checkout in the EUR store intermittently fails. The backend returns HTTP 500 with a `TypeError` reading `currency` from an undefined object. The UI shows a generic "Something went wrong" toast and the order total is not reduced. The same spec on the same commit passed 7 of 10 attempts, so the defect is intermittent rather than a hard failure.

## Steps to reproduce

1. Sign in to the EUR store as `buyer.eur@shop.example`.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat the flow several times. In CI, running the spec with `--repeat-each=10` reproduced the failure on attempts 4, 7 and 9.

Automated spec: `checkout.spec.ts > gift card > applies a gift card to an order in EUR`.

## Expected result

The order summary shows "Gift card: -€20.00" and a total of €29.00. The API responds with a 2xx status.

## Actual result

A toast reads "Something went wrong. Please try again." The total stays at €49.00.

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Reproduction rate

| Measure | Value |
| --- | --- |
| Attempts on commit 9f3c2ab | 10 |
| Failed | 3 (attempts 4, 7, 9) |
| Passed | 7 |

All three failures returned the identical status and response body.

## Evidence

- CI run e2e-staging #3318, Playwright 1.48.1, Chromium 129.0.6668.29, Ubuntu 22.04 runner.
- Network capture from the failing attempts showing the 500 and the error body quoted above.
- Playwright trace and screenshot artifacts for attempts 4, 7 and 9 are assumed to be attached to the CI run.

## Analysis and notes

The error is a server-side unhandled exception, not a UI defect. Some object the handler expects to carry a `currency` field is undefined on the failing requests. Because the failure is intermittent on an identical input, the likely cause is state or timing dependent, for example a cache miss, a race between two lookups, or a dependency that occasionally returns an empty result.

A developer suggested on the team channel that the cause is "probably the currency service cache again," noting similar flakiness last sprint. This is a plausible hypothesis but it is unconfirmed. It should be verified against server logs and the stack trace rather than assumed. If a previous ticket exists for last sprint's flakiness, it should be linked here and that fix reassessed.

Separately, the server returns the raw exception message in the response body. Leaking internal error text to clients is a minor hardening issue worth tracking alongside the fix.

## Assumptions

- The three failures are all from the same run and commit, as stated in the log. No other builds have been checked.
- The gift card `GC-TEST-0042` retained a EUR 20.00 balance across attempts, so balance depletion is not the cause. Passing attempts showed the correct deduction, which supports this.
- No concurrent deploys or configuration changes happened on staging during the run.
- The failure has not yet been checked in other currency stores (for example USD or GBP). It is unknown whether it is EUR specific.

## Suggested next steps for triage

1. Pull the server stack trace for the three failing requests from staging logs around 06:12 UTC on 2026-10-14 to identify the undefined object.
2. Confirm or rule out the currency service cache hypothesis by checking cache hit and miss metrics for the same window.
3. Add a guard and an explicit error response for the missing currency case so the client receives an actionable message instead of a 500.
4. Re-run the spec with `--repeat-each=10` or higher on the fix to confirm the intermittent failure no longer occurs.
5. Run the equivalent spec in at least one non-EUR store to confirm the scope.

## Release impact

This defect is present on release candidate 4.12.0-rc.2. Recommend holding 4.12.0 until the root cause is identified and the fix is verified, since gift card redemption is a customer-facing payment flow.
