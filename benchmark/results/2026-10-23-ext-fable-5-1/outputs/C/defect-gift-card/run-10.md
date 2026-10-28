# Applying a gift card at checkout intermittently fails with HTTP 500 (`TypeError ... reading 'currency'`)

**Build:** 4.12.0-rc.2 (commit 9f3c2ab)
**Environment:** staging, https://staging.shop.example
**Area:** Checkout > Gift cards
**Severity:** High. The failure blocks payment with a gift card in a core checkout step, on a release-candidate build.
**Priority:** High. Assumed, because 4.12.0 is in release-candidate testing and this would be user-facing in production.
**Reported by:** <account email, redacted>, 2026-10-24
**Source:** pipeline e2e-staging #3318, run on 2026-10-14 at 06:12 UTC

## Summary

Applying a gift card to a EUR order sometimes fails. The gift-card request returns HTTP 500 with a server-side `TypeError`. The shopper sees a generic error toast and the gift card is not applied. On the same commit, the failure occurred in 3 of 10 repeated runs of the same test. It is intermittent, not deterministic.

## Steps to reproduce

1. Sign in on the EUR store as the test user `buyer.eur@shop.example`.
2. Add "Desk Lamp" (EUR 49.00) to the cart.
3. Open checkout.
4. Enter gift card `GC-TEST-0042` (balance EUR 20.00).
5. Select **Apply**.
6. Repeat the whole sequence several times. The failure appears in about 3 of 10 attempts.

Automated reproduction:

```text
Spec: checkout.spec.ts > gift card > applies a gift card to an order in EUR
Command flag: --repeat-each=10
Result: 7 passed, 3 failed (attempts 4, 7 and 9)
```

## Expected result

The order summary shows the line "Gift card: -€20.00" and the total changes to €29.00.

## Actual result

A toast appears with the text "Something went wrong. Please try again." The total stays at €49.00. No gift-card line is shown.

## Evidence

Network request on each failed attempt:

```text
POST /api/checkout/gift-card -> 500
```

Response body on each failed attempt:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

All 3 failed attempts returned the same status and body. All 7 passing attempts showed the expected summary. The full Playwright trace and log are in pipeline e2e-staging #3318.

## Test environment

| Item | Value |
| --- | --- |
| Browser | Chromium 129.0.6668.29 |
| Test runner | Playwright 1.48.1 |
| Runner OS | Ubuntu 22.04 |
| Store / currency | EUR store, EUR gift card |

## Frequency and impact

The test fails in 3 of 10 attempts on a single commit. The same request succeeds in the other attempts, so the failure depends on server state rather than on the input. Any shopper applying a gift card may hit it. The error message gives no guidance, and a retry may or may not succeed.

## Notes and unconfirmed hypotheses

A developer commented on the team channel: "probably the currency service cache again, it was flaky last sprint too." This is a hypothesis and is not confirmed by the evidence in the CI log. The error text shows that some object expected to have a `currency` property was `undefined` when the gift-card endpoint ran. Which object, and why, is not known yet.

Suggested next checks for the assignee:

- Server logs for `POST /api/checkout/gift-card` on staging around 2026-10-14 06:12 UTC, to find the stack trace behind the `TypeError`.
- Whether the previous sprint's flaky-cache issue has a ticket and whether its fix shipped in 4.12.0-rc.2.
- Whether the same test fails for other currencies or only for EUR.
- Whether the failure is tied to a specific server instance or to the first request after a cache expiry.

## Assumptions

- Severity and priority are my assessment. The team's triage rules may set them differently.
- The failure reproduces manually as well as under Playwright. I only have the automated evidence.
- No server-side logs or stack traces were attached to the CI run. The error text in the response body is the only server evidence available.
- The gift card `GC-TEST-0042` had its full EUR 20.00 balance at the start of every attempt. The log does not say whether the passing attempts consumed the balance.
- The previous sprint's flaky-cache problem is a separate, possibly related issue. It is not linked here because no ticket reference was given.
