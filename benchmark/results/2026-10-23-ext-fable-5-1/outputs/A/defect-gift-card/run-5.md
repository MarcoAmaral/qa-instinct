# Defect Report: Intermittent 500 on gift card application in EUR checkout

**ID:** (assigned on filing) · **Reported:** 2026-10-24 · **Reporter:** QA automation triage
**Build:** 4.12.0-rc.2 (commit 9f3c2ab) · **Environment:** staging (https://staging.shop.example)
**Pipeline:** e2e-staging #3318, 2026-10-14 06:12 UTC
**Spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Summary

Applying a gift card at checkout in the EUR store intermittently fails with an HTTP 500 from `POST /api/checkout/gift-card`. The response body exposes a server-side `TypeError: Cannot read properties of undefined (reading 'currency')`. The UI shows a generic error toast and the order total is not reduced. The failure reproduced 3 times out of 10 identical runs on the same commit, so this is an intermittent backend defect, not a test timing issue.

## Severity and priority

| Field | Value | Rationale |
|---|---|---|
| Severity | High | A core payment path fails with an unhandled server exception. A customer cannot redeem a gift card and gets no actionable message. |
| Priority | High | Build is a release candidate (rc.2). Roughly 30% failure rate on staging would translate to a visible checkout failure rate in production. |
| Type | Functional, intermittent | |
| Blocks release? | Recommend yes until root cause is known | See "Analysis". |

## Environment

- Browser: Chromium 129.0.6668.29 via Playwright 1.48.1
- Runner: Ubuntu 22.04
- Store: EUR storefront, test user `buyer.eur@shop.example`
- Test gift card: `GC-TEST-0042`, balance EUR 20.00

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` on the EUR store.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` and press "Apply".
4. Repeat steps 1 to 3 roughly 10 times, or run the spec with `--repeat-each=10`.

## Expected result

The order summary shows "Gift card: -€20.00" and the total becomes €29.00. `POST /api/checkout/gift-card` returns a 2xx.

## Actual result

On a subset of attempts, a toast reads "Something went wrong. Please try again." and the total stays at €49.00. The network call fails:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency and evidence

| Attempt | Result |
|---|---|
| 1, 2, 3, 5, 6, 8, 10 | Pass, expected summary shown |
| 4, 7, 9 | Fail, 500 with the TypeError body above |

All 10 attempts ran against the same commit and the same test data. Failing attempts are not consecutive, which points to a race or stale/missing state rather than a deterministic code path.

## Analysis

- The exception is raised server-side. The handler reads `.currency` on a value that is `undefined`. Candidates are the store or locale context, the cart or order record, the gift card record, or a currency lookup result.
- A developer suggested on the team channel that this is "probably the currency service cache again" and that it was flaky last sprint. This is a plausible hypothesis given the property name, but it is unverified. The report should not be closed on that basis without a reproduction or log evidence.
- Secondary issue: the API returns a raw exception message to the client. That is an information disclosure and a poor error contract. Recommend tracking separately or fixing alongside.
- The user-facing toast is generic. Even once the 500 is fixed, the client should distinguish a retryable server error from a rejected gift card.

## Assumptions

- The gift card balance is reset between attempts, or is not consumed by the test, since passing attempts after failures still showed a EUR 20.00 deduction.
- No earlier build data was available, so regression status is unknown. Assumed the test passed consistently before 4.12.0-rc.2 because the spec exists and the failure is intermittent rather than total.
- The "last sprint" flakiness referred to by the developer was not formally tracked. Assumed no prior ticket exists.
- Staging server logs and a request ID for the failing calls were not captured in the CI output.

## Suggested next steps

1. Pull staging application logs for the three failing requests around 06:12 UTC on 2026-10-14 to get the full stack trace and identify which object was `undefined`.
2. Check whether the currency service cache can return a miss or an expired entry for EUR during request handling, and whether the gift card handler guards that case.
3. Add a null guard and a 4xx or structured 5xx response in the gift card handler so the client gets a stable error contract.
4. Stop returning raw exception messages in API error bodies.
5. Re-run the spec with `--repeat-each=20` or higher after the fix to confirm the failure rate drops to zero.
6. Check the USD and GBP equivalents of this spec for the same symptom to confirm whether the defect is currency-specific.

## Attachments to include when filing

- CI log for pipeline e2e-staging #3318
- Playwright trace and HAR for attempts 4, 7, and 9
- Link to the team channel message containing the developer's hypothesis
