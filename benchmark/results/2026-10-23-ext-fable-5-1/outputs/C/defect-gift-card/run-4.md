# Applying a gift card at checkout sometimes fails with a 500 error in the EUR store

| Field | Value |
| --- | --- |
| Reported | 2026-10-24 |
| Reporter | <account email, redacted> |
| Status | New |
| Severity | High (assumed: customers cannot complete a discounted order, no workaround in the UI) |
| Priority | P1 (assumed: 4.12.0-rc.2 is a release candidate) |
| Component | Checkout, gift card API (assumed name) |
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Environment | Staging, https://staging.shop.example |
| Found by | CI pipeline e2e-staging #3318, 2026-10-14 06:12 UTC |
| Test | checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| Reproducibility | Intermittent: 3 failures in 10 runs on the same commit |

## Summary

Applying a gift card to a EUR order sometimes returns a server error. The order total does not change and the customer sees a generic error toast. The request to `POST /api/checkout/gift-card` fails with HTTP 500 and a `TypeError` about reading `currency` from an undefined value. The same steps pass about 7 times in 10 on the same build, so the failure depends on server state, not on the test input.

## Steps to reproduce

Run against staging on build 4.12.0-rc.2. Repeat the steps up to 10 times, because the failure is intermittent.

1. Sign in as the test user `buyer.eur@shop.example` (EUR store).
2. Add **Desk Lamp** (EUR 49.00) to the cart.
3. Open checkout.
4. Enter gift card `GC-TEST-0042` (balance EUR 20.00).
5. Select **Apply**.

## Expected result

The order summary shows **Gift card: -€20.00** and the total is **€29.00**.

## Actual result

A toast appears with the text **Something went wrong. Please try again.** The total stays **€49.00**. The gift card line does not appear in the order summary.

## Evidence

Network request:

```text
POST /api/checkout/gift-card -> 500
```

Response body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Test setup:

```text
Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner
--repeat-each=10 on commit 9f3c2ab
```

Results across the 10 attempts:

| Attempt | Result |
| --- | --- |
| 1, 2, 3, 5, 6, 8, 10 | Passed, expected summary shown |
| 4, 7, 9 | Failed, HTTP 500 with the response body above |

All 3 failures returned the same status and the same error text. The passing attempts used the same user, product and gift card.

## Impact

- A customer who hits this cannot apply a gift card on that attempt. The toast suggests retrying, and a retry may succeed, but the customer has no way to know that.
- The error message exposes a raw JavaScript stack message to the client. The API should return a safe error body.
- The release candidate cannot ship with a 3 in 10 failure rate on a checkout path unless the cause is confirmed to be staging-only.

Not yet known:

- Whether the gift card balance is deducted on a failed attempt. The test does not check the balance after the error.
- Whether the same request fails in production or on other currencies. Only the EUR test was run.
- Whether the failure affects the first apply in a session, later applies, or both.

## Notes from the team

A developer wrote on the team channel: "probably the currency service cache again, it was flaky last sprint too." This is a hypothesis, not a confirmed cause. The error text is consistent with a currency lookup returning nothing, but nothing in the CI log confirms which service returned the undefined value. Treat the note as a lead for investigation, not as the root cause.

## Suggested next steps for investigation

1. Pull the server logs for the 3 failing requests by timestamp and find the stack trace behind the `TypeError`. The response body gives the message but not the location.
2. Check whether the currency lookup for the EUR store can return undefined, for example on a cache miss, a cold start, or an expired entry.
3. Check the gift card balance for `GC-TEST-0042` after a failed apply to confirm no balance was deducted.
4. Change the API to return a safe error body and a 4xx or 5xx code with a stable error code, so the client does not display or log a raw exception message.
5. Add a server-side guard or retry for the currency lookup and re-run the spec with `--repeat-each=20` to confirm the fix.

Do not mark the spec as flaky or quarantine it. The failure is a real server error on a checkout path, and the test is reporting it correctly.

## Attachments

- CI log for pipeline e2e-staging #3318 (assumed: attached from the CI run page).
- Playwright trace for attempt 4 (assumed: available from the run artifacts).

## Assumptions

- Severity and priority are assigned by the reporter because the log does not give them. Adjust if the team has its own scale.
- The component name "gift card API" is the reporter's label. Use the name in the issue tracker if it differs.
- The reporter is the account that ran this report. Change to the CI owner if the team tracks CI-found defects differently.
- The failure is being reported against staging only. Production impact is unknown until step 2 above is checked.
- The developer quoted above is not named here because the log does not say who wrote the message.
