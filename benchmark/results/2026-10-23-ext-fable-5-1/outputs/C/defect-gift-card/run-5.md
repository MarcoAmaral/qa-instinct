# Defect report: Applying a EUR gift card at checkout fails intermittently with a 500 error

## Summary

Applying a gift card to a EUR order fails on about 3 of 10 attempts. The checkout shows a toast that says **Something went wrong. Please try again.** and the total does not change. The gift card request to the server returns HTTP 500 with a `TypeError` about reading `currency` from `undefined`.

| Field | Value |
| --- | --- |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | Staging, `https://staging.shop.example` |
| Pipeline | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Spec | `checkout.spec.ts` > gift card > applies a gift card to an order in EUR |
| Frequency | 3 failed of 10 runs on the same commit (attempts 4, 7 and 9) |
| Severity | High (assumed): the customer cannot use a gift card and the error gives no next step |
| Priority | Blocks release candidate (assumed): 4.12.0-rc.2 is a release candidate and this is a checkout path |
| Area | Checkout, gift cards |
| Status | New |

## Environment

- Browser: Chromium 129.0.6668.29
- Test runner: Playwright 1.48.1 on an Ubuntu 22.04 runner
- Test run flag: `--repeat-each=10`
- Test account: `buyer.eur@shop.example` (EUR store)
- Gift card: `GC-TEST-0042`, balance EUR 20.00

## Steps to reproduce

1. Sign in to the EUR store as `buyer.eur@shop.example`.
2. Add **Desk Lamp** (EUR 49.00) to the cart.
3. Open checkout.
4. Enter gift card `GC-TEST-0042` in the gift card field.
5. Select **Apply**.
6. Repeat steps 4 and 5, or re-run the spec with `--repeat-each=10`, until the failure appears.

## Expected result

The order summary shows **Gift card: -€20.00** and the total is **€29.00**.

## Actual result

A toast appears with the text **Something went wrong. Please try again.** The total stays at **€49.00**. The gift card is not applied.

## Evidence

Network request during the failed attempts:

```text
POST /api/checkout/gift-card -> 500
```

Response body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

All 3 failed attempts returned the same status and body. All 7 passing attempts showed the expected summary. The same commit was used for every attempt, so the failure is not caused by a code change between runs.

## Impact

- A customer on the EUR store may be unable to apply a gift card on some attempts.
- The error message does not tell the customer what to do, so some will abandon the order.
- The spec is unstable, so the e2e-staging pipeline cannot be trusted as a release gate while this is open.

## Notes and open questions

- A developer on the team channel suggested the currency service cache as the cause and said it was flaky last sprint. This is unverified. The report records the observed behaviour only. The cause should be confirmed from server logs for the 3 failed requests before a fix is planned.
- The server error exposes an internal exception message in the response body. This should be reviewed separately as a possible information leak.
- It is not yet known whether the failure also affects other currencies or production. The spec only covers EUR on staging.

## Assumptions

- Severity and priority are assumed from the fact that the failure sits in the checkout path of a release candidate. Adjust if the team's triage rules differ.
- The failure is treated as intermittent at about 30 percent, based on a single run of 10 attempts. A larger sample may show a different rate.
- The tester's toast and summary wording are taken from the CI log and are assumed to match the interface labels exactly.
- The test runs in a fresh browser context for each attempt. If attempts share a session, that may matter for reproduction.

## Attachments to add

- Server logs for `POST /api/checkout/gift-card` at the timestamps of attempts 4, 7 and 9.
- The Playwright trace and screenshot for attempt 4.
- The request headers and body of a failed request and a passing request, for comparison.
