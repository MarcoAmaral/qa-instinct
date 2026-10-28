# Defect Report: Intermittent 500 on gift card application in EUR checkout (`TypeError ... reading 'currency'`)

**ID:** DEF-TBD (assign on triage)
**Reported by:** QA, 2026-10-24
**Build:** 4.12.0-rc.2, commit `9f3c2ab`
**Environment:** staging, `https://staging.shop.example`
**Source:** pipeline `e2e-staging` run #3318, 2026-10-14 06:12 UTC
**Severity:** High (customer-facing checkout failure, payment-adjacent, intermittent)
**Priority:** P1 (blocks release candidate until root cause is understood; see Release Risk)
**Status:** New

## Summary

Applying a valid gift card during EUR checkout intermittently fails with an HTTP 500 from `POST /api/checkout/gift-card`. The response body exposes a server-side `TypeError: Cannot read properties of undefined (reading 'currency')`. The customer sees a generic "Something went wrong. Please try again." toast and the order total is not reduced. On the same commit, 3 of 10 repeated runs failed, so this is a backend defect and not a test timing issue.

## Environment

| Item | Value |
|---|---|
| Base URL | https://staging.shop.example |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Browser | Chromium 129.0.6668.29 |
| Test runner | Playwright 1.48.1 on Ubuntu 22.04 CI runner |
| Store / currency | EUR store |
| Test account | buyer.eur@shop.example |
| Gift card | GC-TEST-0042, balance EUR 20.00 |
| Spec | `checkout.spec.ts` > gift card > applies a gift card to an order in EUR |

## Steps to Reproduce

1. Sign in as `buyer.eur@shop.example` on the EUR store.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card code `GC-TEST-0042` and press "Apply".
4. Observe the order summary and the network response for `POST /api/checkout/gift-card`.

Because the failure is intermittent, repeat the steps at least 10 times, or run the spec with `--repeat-each=10`, to reproduce reliably.

## Expected Result

- The order summary shows the line "Gift card: -€20.00".
- The order total updates to €29.00.
- `POST /api/checkout/gift-card` returns a success status.

## Actual Result

- A toast appears: "Something went wrong. Please try again."
- The order total remains €49.00 and no gift card line is shown.
- `POST /api/checkout/gift-card` returns HTTP 500 with body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency and Pattern

| Metric | Value |
|---|---|
| Attempts on this commit | 10 |
| Passed | 7 |
| Failed | 3 (attempts 4, 7, 9) |
| Failure rate | 30% |

All three failures had the identical status and response body. The failing attempts are not consecutive, and the passing attempts all showed the correct summary. The failure occurs on the same commit, same inputs, same test account, and the same gift card, which rules out test data drift between runs as the primary cause.

## Evidence

- CI log for `e2e-staging` #3318, failure block for attempt 4 of 10 (quoted above).
- Network capture from the Playwright run showing the 500 and the response body.
- Assumption: the Playwright trace and screenshot artifacts for attempts 4, 7, and 9 are attached to the pipeline run. If they were not retained, re-run with `--trace on` to capture them.

## Analysis

The error is an unhandled server-side exception, not a validation response. Some object that the gift card handler expects to carry a `currency` field is `undefined` at the time of the read. Plausible candidates include the resolved store or cart currency context, the gift card record, or a currency conversion lookup. The intermittent behaviour with identical inputs points to a timing or state dependency on the server, such as an unpopulated cache, a race between session setup and the gift card call, or a dependency returning empty on some requests.

The developer's note suggests "probably the currency service cache again, it was flaky last sprint too." This is a reasonable hypothesis and consistent with the symptom, but it is unverified. The report does not treat it as the root cause. If a cache miss or cold cache can produce an `undefined` currency, that is a defect in its own right: the handler must either fetch on miss or fail with a controlled, descriptive error rather than crash.

The failure is not attributable to the test. The test performs a straightforward user flow, the assertion failure is downstream of a genuine 500, and the same steps pass most of the time on the same build.

## Impact

- **Customer:** Roughly 3 in 10 gift card applications fail at checkout with an unhelpful message. Customers may retry, abandon the purchase, or contact support believing the card is invalid or spent.
- **Business:** Gift card redemption is revenue-affecting and reputation-affecting, and the failure sits on the payment path.
- **Release:** This is a release candidate. Shipping with a known intermittent 500 on checkout carries material risk.
- **Security hygiene (secondary):** The API returns a raw JavaScript exception message to the client. This leaks implementation detail and should be replaced with a sanitised error and a correlation ID, with the full stack recorded server-side.

## Assumptions

- The three failed attempts used the same cart state as the passing attempts. The log does not show cart teardown between repeats, so I assume each repeat starts from a clean cart.
- The gift card balance was not consumed by earlier passing attempts, since the test is assumed to reset or never finalise the order. If balance consumption is possible, confirm the card still held EUR 20.00 at attempts 4, 7, and 9.
- No deploy or configuration change occurred on staging during the run.
- Server logs for staging at 06:12 UTC on 2026-10-14 are retrievable and include a stack trace for the `TypeError`.
- Non-EUR stores have not been tested for this path on this build. Scope may be wider than EUR.

## Suggested Investigation Steps for Development

1. Pull the staging server logs for `POST /api/checkout/gift-card` around 2026-10-14 06:12 UTC and locate the full stack trace for the `TypeError` to identify the exact object that is `undefined`.
2. Confirm or rule out the currency service cache hypothesis by checking cache hit/miss metrics or logs for the failing request times, and by reproducing with the cache cold or cleared.
3. Check whether the handler calls any upstream service with a timeout or fallback that returns `undefined` on failure.
4. Add a guard and a controlled error response for a missing currency context so the endpoint never returns a raw exception.
5. Review whether the prior sprint's "flaky" incident was fixed or only mitigated, and link that ticket here.

## Suggested Verification After Fix

- Re-run the spec on the fixed build with `--repeat-each=50` and require 50 of 50 passes.
- Add an automated API-level test that exercises the endpoint with a cold or evicted currency cache, if the cache hypothesis is confirmed.
- Verify the endpoint returns a structured error with no exception text on any induced failure.
- Extend coverage to at least one non-EUR store to confirm the fix is not currency-specific.

## Release Risk

Recommend not promoting 4.12.0-rc.2 until the root cause is identified. If the prior sprint's incident was the same defect, the recurrence suggests the earlier mitigation was incomplete.

## Related

- Prior sprint "currency service cache" flakiness (ticket reference unknown; link on triage).
- Error-handling hardening for `POST /api/checkout/gift-card` (recommend a separate low-severity ticket if not fixed together).
