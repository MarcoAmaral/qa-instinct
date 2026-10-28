# Gift card fails to apply at EUR checkout (intermittent 500)

Applying a gift card at checkout in the EUR store sometimes fails. The server returns HTTP 500, the shopper sees the toast "Something went wrong. Please try again.", and the total does not change. The failure happened on 3 of 10 runs of the same test on the same commit, so it is a real defect in the checkout API, not a broken test.

| Field | Value |
| --- | --- |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Found in | Pipeline e2e-staging #3318, 2026-10-14 06:12 UTC |
| Environment | https://staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner |
| Area | Checkout, gift cards |
| Endpoint | `POST /api/checkout/gift-card` |
| Frequency | 3 of 10 attempts (attempts 4, 7 and 9) |
| Severity | High. The failure blocks a payment step on the release candidate. |
| Priority | Assumed P1 for the 4.12.0 release; see Assumptions. |
| Status | New |

## Steps to reproduce

1. Sign in as the test user buyer.eur@shop.example in the EUR store.
2. Add **Desk Lamp** (EUR 49.00) to the cart.
3. Open checkout.
4. Enter gift card GC-TEST-0042 (balance EUR 20.00).
5. Select **Apply**.
6. Repeat steps 1 to 5 up to 10 times. The failure does not occur on every run.

Automated reproduction:

```text
checkout.spec.ts > gift card > applies a gift card to an order in EUR
npx playwright test checkout.spec.ts -g "applies a gift card to an order in EUR" --repeat-each=10
```

## Expected result

The order summary shows "Gift card: -€20.00" and a total of €29.00.

## Actual result

A toast appears with the text "Something went wrong. Please try again." The order summary does not change, and the total stays at €49.00.

The request behind **Apply** fails:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

All 3 failed attempts returned the same status and body. The 7 passing attempts showed the expected summary.

## What the evidence shows

- **The failure is server-side.** The browser sends the same request each time, and the server answers 500 with an unhandled TypeError. The client behaves correctly for a 500.
- **The failure is not tied to a code change.** All 10 attempts ran against the same commit, the same account and the same gift card.
- **The server reads `currency` from a value that is sometimes undefined.** Which object is undefined is not visible from the test. Server logs for the 3 failing requests should show the stack trace.
- **The response leaks an internal error message.** The raw TypeError text reaches the browser. This should be a generic error with a request ID, even after the main bug is fixed.
- **The developer's note is a hypothesis, not a finding.** A team member wrote on the team channel: "probably the currency service cache again, it was flaky last sprint too." No log or trace in this run confirms that. Please verify before closing against the cache, and if it is confirmed, link the previous sprint's ticket here.

## Open questions for the investigator

- Does the failure also occur in other currency stores, or only in EUR?
- Is the gift card balance left unchanged after a failed attempt? The test does not check this.
- Do the server logs show the 3 failing requests at about 06:12 UTC on 2026-10-14, and which object was undefined?
- Did the same test fail on earlier builds of 4.12.0, or is rc.2 the first?

## Assumptions

- **Severity and priority** are assumed from the impact on a payment step in a release candidate. Adjust if the release manager rates it differently.
- **The 7 passes mean the data is valid.** The gift card, account and product are assumed to be correctly set up, because the same inputs succeed most of the time.
- **The failed requests did not deduct the gift card balance.** This is unverified. If a balance was deducted on a 500, raise the severity.
- **Playwright traces and screenshots for the 3 failed attempts** are assumed to be attached to pipeline run #3318 as artifacts. If retention has removed them, rerun the command above to regenerate.
- **No release notes or customer-facing text** are needed yet, because the defect is on staging only.

## Attachments

- Pipeline e2e-staging #3318 (CI log excerpt quoted above)
- Playwright trace and screenshot for attempts 4, 7 and 9, if retained
- Team channel message with the cache hypothesis, for reference only
