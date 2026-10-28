# Applying a gift card at checkout in the EUR store intermittently fails with a 500 error

**Summary:** On build 4.12.0-rc.2, applying gift card GC-TEST-0042 to a EUR order sometimes fails. The shopper sees the toast "Something went wrong. Please try again." and the total does not change. The gift card API returns HTTP 500 with a `TypeError` about a missing `currency` property. The failure happened in 3 of 10 runs of the same test on the same commit.

| Field | Value |
| --- | --- |
| Reported | 2026-10-24 |
| Reporter | <account email, redacted> |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | Staging, https://staging.shop.example |
| Pipeline | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Area | Checkout, gift cards |
| Spec | `checkout.spec.ts` > gift card > applies a gift card to an order in EUR |
| Frequency | Intermittent: 3 failures in 10 attempts (attempts 4, 7 and 9) |
| Severity | High (assumed, see Assumptions) |
| Priority | Blocks the 4.12.0 release candidate (assumed, see Assumptions) |
| Status | New |

## Environment

- Browser: Chromium 129.0.6668.29
- Test runner: Playwright 1.48.1 on Ubuntu 22.04
- Test user: buyer.eur@shop.example (EUR store)
- Test data: product "Desk Lamp" at EUR 49.00, gift card GC-TEST-0042 with a balance of EUR 20.00

## Steps to reproduce

1. Sign in to the EUR store as buyer.eur@shop.example.
2. Add "Desk Lamp" (EUR 49.00) to the cart.
3. Open checkout.
4. Enter the gift card code GC-TEST-0042.
5. Select **Apply**.

Because the failure is intermittent, repeat the steps several times. In CI, 10 runs with `--repeat-each=10` produced 3 failures.

## Expected result

The order summary shows the line "Gift card: -€20.00" and the total changes to €29.00.

## Actual result

A toast appears with the text "Something went wrong. Please try again." The order summary does not show a gift card line. The total stays at €49.00.

## Evidence

Network request during the failing attempts:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

All 3 failing attempts returned the same status and body. All 7 passing attempts showed the expected summary. The test steps and data were identical across all 10 attempts.

## Observations

- The failing response exposes a raw server exception message to the client. That is a separate concern from the failed discount and may be worth its own ticket.
- The stack trace is not in the CI log. The server logs for the failing requests have not been reviewed as part of this report.
- The failures are spread across the run (attempts 4, 7 and 9), not clustered at the start. This suggests the cause is not limited to a cold start.

## Hypothesis (unconfirmed)

A developer suggested on the team channel that the currency service cache is the likely cause and noted similar flakiness last sprint. This is a hypothesis, not a confirmed cause. Nothing in the CI log confirms or rules it out. The report records it so the investigation can start there, but the root cause field stays open until someone reproduces the error with server-side logging.

## Impact

A real shopper in the EUR store who hits this error cannot apply a gift card on that attempt. The toast tells them to try again, but it does not say whether the gift card balance was touched. If the error occurs in production at the same rate, roughly 3 in 10 gift card applications would fail on the first try.

## Suggested next steps for the assignee

1. Pull the server logs and stack trace for the 3 failing requests from pipeline run #3318.
2. Check whether the gift card or order object reaches the handler without a `currency` field, and under which conditions.
3. Confirm whether the gift card balance is unchanged after a failed attempt.
4. Add a test or log line that captures the request payload on failure, so the next occurrence is diagnosable from CI alone.

## Assumptions

- **Severity High:** the defect blocks a checkout payment step for real shoppers and affects money. Lower it if gift cards are a small share of EUR orders.
- **Blocks the release candidate:** 4.12.0-rc.2 is assumed to be a release candidate for production. If this build is not going to production, lower the priority.
- **Not a test problem:** the test steps, data and expectations were identical in passing and failing attempts, and the failure is a server 500. The report therefore treats this as a product defect, not a flaky test.
- **Button label:** the test log says the test pressed "Apply". The report assumes the visible button label is **Apply**. Correct it if the interface uses different wording.
- **Reporter and date:** the report uses the current user's address and today's date because the log does not name a reporter.
- **Gift card balance after failure:** the log does not say whether the balance changed. The report lists this as an open check rather than assuming either way.
