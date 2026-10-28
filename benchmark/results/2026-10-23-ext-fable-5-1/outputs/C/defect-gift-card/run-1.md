# Applying a gift card at EUR checkout sometimes fails with "Something went wrong"

**Summary:** On build 4.12.0-rc.2, applying a gift card to an EUR order intermittently fails. The checkout shows the toast **Something went wrong. Please try again.** and the total does not change. The request to `POST /api/checkout/gift-card` returns HTTP 500. The failure happened in 3 of 10 runs of the same test on the same commit.

| Field | Value |
| --- | --- |
| Report ID | None: assigned by the tracker on creation |
| Reported by | Marco (<account email, redacted>) |
| Date reported | 2026-10-24 |
| Found in build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | Staging, https://staging.shop.example |
| Product area | Checkout, gift cards |
| Severity | High (assumed: a customer cannot use a gift card and the error gives no way to recover) |
| Priority | Blocker for the 4.12.0 release (assumed: the failing path is the checkout) |
| Type | Intermittent, 30% failure rate on this build |
| Status | New |

## Environment

- Pipeline: e2e-staging, run #3318, 2026-10-14 06:12 UTC
- Browser: Chromium 129.0.6668.29
- Test runner: Playwright 1.48.1 on Ubuntu 22.04
- Store: EUR store, signed in as test user `buyer.eur@shop.example`
- Spec: `checkout.spec.ts` > gift card > applies a gift card to an order in EUR

## Steps to reproduce

1. Sign in to the EUR store as `buyer.eur@shop.example`.
2. Add **Desk Lamp** (€49.00) to the cart and open checkout.
3. In the gift card field, enter `GC-TEST-0042` (balance €20.00).
4. Select **Apply**.
5. Repeat steps 1 to 4 about 10 times. The failure appears in roughly 3 of 10 runs.

## Expected result

The order summary shows **Gift card: -€20.00** and the total changes to €29.00.

## Actual result

A toast appears with the text **Something went wrong. Please try again.** The total stays at €49.00. The gift card is not applied.

## Evidence

Network request and response from the failing run:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Attempts 4, 7 and 9 of 10 failed with this status and body. Attempts 1, 2, 3, 5, 6, 8 and 10 passed and showed the expected summary.

Attachments to add from the CI run (assumed to be available in the Playwright report for run #3318):

- Playwright trace and screenshot for attempts 4, 7 and 9
- HAR file or network log for the failing `POST /api/checkout/gift-card` requests
- Server logs for the gift card endpoint around 06:12 UTC on 2026-10-14

## Frequency and scope

- Reproduced 3 times in 10 runs on one commit, with no code change between runs.
- Only the EUR gift card test was observed. It is not yet known whether other currencies, other gift cards or a manual checkout in a browser are affected.
- It is not yet known whether this is a regression. No earlier build was run with `--repeat-each=10` for comparison.

## Workaround

None confirmed. Selecting **Apply** again may succeed, because 7 of 10 attempts passed, but this was not tested as a retry within one session.

## Notes

- A developer on the team channel wrote: "probably the currency service cache again, it was flaky last sprint too." This is an unverified hypothesis, not a confirmed cause. The report records only what was observed.
- The error body exposes an internal exception message to the client. Consider tracking that separately as a hardening issue.
- The same commit passes and fails without changes, so the first step for the assignee is to find what differs between passing and failing requests, for example timing, cache state or session data.

## Assumptions made in this report

- Severity and priority are proposed by the reporter and can be changed by triage.
- The reporter and report date are taken from the account that filed this report, not from the CI run.
- Attachments listed above exist in the CI artifacts; if the pipeline does not keep traces, rerun the spec with tracing on.
- The test gift card `GC-TEST-0042` had a full €20.00 balance at the start of each attempt.
