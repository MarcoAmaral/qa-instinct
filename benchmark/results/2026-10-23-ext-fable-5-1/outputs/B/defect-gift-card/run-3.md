# Defect: Intermittent 500 on `POST /api/checkout/gift-card` blocks gift card redemption in EUR checkout

| Field | Value |
|---|---|
| Severity | High. A paying customer intermittently cannot redeem a gift card and is told to retry. |
| Priority | P1 for 4.12.0 release decision. Fails on a release candidate. |
| Component | Checkout API, gift card endpoint |
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Environment | staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 |
| Detected by | CI pipeline e2e-staging #3318, 2026-10-14 06:12 UTC |
| Spec | checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| Frequency | 3 of 10 attempts on the same commit (attempts 4, 7, 9 of `--repeat-each=10`) |
| Status | New, not yet reproduced outside CI |
| Reporter | <account email, redacted> |

**Summary.** Applying a valid gift card during EUR checkout intermittently fails with an HTTP 500. The response body exposes an unhandled server exception and the storefront shows a generic error toast. The cart total is left unchanged. The failure is nondeterministic on a single commit, so it is state or timing dependent rather than a straightforward code regression.

## Steps to reproduce

1. Sign in on the EUR store as `buyer.eur@shop.example`.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat the full flow roughly ten times. Observed failure rate was about 30 percent.

**Expected.** The order summary shows "Gift card: -€20.00" and a total of €29.00.

**Actual (on failing attempts).** A toast reads "Something went wrong. Please try again." The total stays at €49.00. The gift card is not applied.

## Evidence

Failing request and response, identical on all three failed attempts:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

The seven passing attempts rendered the expected summary with the same account, product, and gift card. No client-side difference between passing and failing attempts is recorded in the log.

Secondary finding: the 500 response returns the raw exception message to the browser. This is an information disclosure and should be tracked as a separate low-severity defect against error handling.

## Analysis and next steps

**What the error tells us.** The handler dereferences `.currency` on a value that is `undefined` in the failing cases. Candidates are the cart or order object, the gift card record, the store or locale context, or a currency lookup result. Since the same inputs succeed most of the time, the undefined value is most likely coming from a cache miss, a race between checkout session creation and the gift card call, or a dependency that occasionally returns an empty result.

**Developer hypothesis.** A developer on the team channel suggested the currency service cache, noting it was flaky last sprint. This is a plausible lead and matches the `currency` property in the stack, but it is unconfirmed. The report should not be closed as "known flaky" without evidence. If the previous sprint's issue has a ticket, link it here and confirm whether its fix shipped in rc.2.

**Assumptions made in this report.**

- No server-side logs or stack traces were available beyond the response body. Only the top-level message is known.
- The failing attempts ran with the same test data and no parallel workers mutating the shared account or gift card. If workers run in parallel, shared-state contention becomes a leading hypothesis.
- The test is otherwise stable. No history of failures on earlier commits is available in the log, so this is treated as a release-blocking regression candidate until proven pre-existing.
- Non-EUR stores were not exercised. It is unknown whether USD or GBP checkout is affected.

**Suggested diagnostics for the owner.**

- Pull the server stack trace for the three failed requests, matched by timestamp or request ID, to identify which object is undefined.
- Add a guard and a structured log line at the dereference so the next occurrence reports which lookup returned empty and for which store and cart.
- Check whether the currency service cache can return a miss or an expired entry during a cold start or TTL rollover, and whether the handler falls back correctly on a miss.
- Run the same spec against USD and GBP stores with `--repeat-each=20` to establish whether the issue is EUR-specific.
- Run the spec with a single worker to rule out shared test data contention.

**Acceptance criteria for closure.**

- The spec passes 50 consecutive repeats on the fixed build with no 500 responses.
- A cache miss or missing currency context yields a handled error with a specific user message, never an unhandled TypeError.
- The API no longer returns raw exception text in the response body.
- A regression test covers the cache miss or missing context path directly, so the fix does not depend on timing to be verified.
