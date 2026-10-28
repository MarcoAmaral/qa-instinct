# Defect: Applying a gift card in the EUR store intermittently fails with HTTP 500 (`TypeError ... reading 'currency'`)

**ID:** (to be assigned)
**Reported:** 2026-10-24
**Reporter:** <account email, redacted>
**Component:** Checkout / Gift cards (API `POST /api/checkout/gift-card`)
**Build:** 4.12.0-rc.2, commit `9f3c2ab`
**Environment:** staging (`https://staging.shop.example`), EUR store
**Severity:** High. The customer cannot redeem a gift card and is shown a generic error, and the failure is non-deterministic.
**Priority:** High. Found on a release candidate, and the current pass rate makes the failure likely to reach customers.
**Status:** New

## Summary

Applying a valid gift card at checkout in the EUR store fails about 3 times in 10 on the same build and commit. The API returns a 500 with an unhandled `TypeError` complaining that `currency` is read from `undefined`. The UI shows the generic toast "Something went wrong. Please try again." and the order total is not reduced. The failure is intermittent, so the test results point to a server-side state or race condition rather than a deterministic code path.

## Environment

| Item | Value |
|---|---|
| Pipeline | `e2e-staging` #3318, 2026-10-14 06:12 UTC |
| Build | 4.12.0-rc.2 (commit `9f3c2ab`) |
| Base URL | `https://staging.shop.example` |
| Browser | Chromium 129.0.6668.29 |
| Test tooling | Playwright 1.48.1, Ubuntu 22.04 runner |
| Spec | `checkout.spec.ts` > gift card > applies a gift card to an order in EUR |
| Test account | `buyer.eur@shop.example` (EUR store) |
| Test gift card | `GC-TEST-0042`, balance EUR 20.00 |

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` on the EUR store.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` and press "Apply".
4. Repeat the same scenario several times on the same build (the CI run used `--repeat-each=10`).

## Expected result

The order summary shows "Gift card: -€20.00" and the total is €29.00. The API call `POST /api/checkout/gift-card` returns a success status.

## Actual result

On some attempts the UI shows the toast "Something went wrong. Please try again." and the total stays €49.00.

The API call fails:

```
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency

| Attempts | Passed | Failed |
|---|---|---|
| 10 (same commit) | 7 | 3 (attempts 4, 7, 9) |

All three failures had the same status and response body. The seven passing attempts showed the expected summary. No pattern is visible in the attempt numbers, so the failures are not consistent with a one-off warm-up or first-run effect.

## Analysis and observations

- **The error is server-side.** The 500 and the stack message come from the gift-card endpoint, not from the browser. The UI behaviour is a correct consequence of the failed request.
- **The error is an unhandled exception leaking to the client.** The response body exposes a raw JavaScript `TypeError`. Even once the root cause is fixed, this endpoint should return a structured error and not expose internals.
- **`currency` is read from an object that is sometimes `undefined`.** Candidates include the gift card record, the cart or order, the store or locale context, or a currency lookup result. Because the same inputs pass most of the time, a lookup that can return nothing (cache miss, timeout, or a race on request-scoped state) is more likely than a bad input.
- **The developer's hypothesis is unverified.** A team member noted on the channel that it is "probably the currency service cache again, it was flaky last sprint too." This is plausible and consistent with the intermittent behaviour, but no evidence in this log ties the failure to that cache. It should be treated as a lead, not a diagnosis. If the previous sprint's issue was closed without a root-cause fix, this report may be a regression or a recurrence of that ticket and the two should be linked.
- **Not a test flake to be retried away.** The failing attempts received a real 500 with a real exception. Marking the spec as flaky or adding retries would hide a customer-facing defect.

## Assumptions

- The ten attempts were run against the same staging deployment with no deploy or configuration change in between.
- The gift card `GC-TEST-0042` had sufficient balance and was not in a locked or partially redeemed state during the failing attempts. The log does not show balance after each run.
- The same scenario in other currency stores (for example USD or GBP) has not been checked. The failure may not be EUR-specific.
- Server logs and request IDs for the failing calls were not captured in the CI log. They are assumed to be available on the staging environment for 2026-10-14 06:12 UTC.

## Suggested investigation

1. Pull server logs for `POST /api/checkout/gift-card` around 2026-10-14 06:12 UTC and get the full stack trace for the `TypeError`, including which object was `undefined`.
2. Check whether the currency service or its cache returned a miss, an error, or a timeout at the same timestamps, to confirm or rule out the hypothesis from the team channel.
3. Run the same spec with `--repeat-each=10` against a USD or GBP store to determine whether the problem is EUR-specific.
4. Review the gift-card endpoint for request-scoped state that could be missing under concurrent requests.
5. Regardless of root cause, add a null guard and a structured error response so an internal failure does not surface a raw exception to the client.

## Acceptance criteria for the fix

- The spec passes 10 of 10 on `--repeat-each=10` on the fixed build, and the same for at least one non-EUR store.
- `POST /api/checkout/gift-card` never returns a raw exception message in the response body.
- The root cause is identified and documented, not just guarded around, so the earlier "flaky" issue does not recur a third time.

## Attachments needed

- Playwright trace, screenshot, and video for attempts 4, 7, and 9 of run #3318.
- Server logs and request IDs for the three failing API calls.
- Link to the previous sprint's currency cache issue, if one exists.
