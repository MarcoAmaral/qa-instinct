# Defect report: Applying a gift card at EUR checkout intermittently fails with HTTP 500

**ID:** to be assigned
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)
**Pipeline:** e2e-staging #3318, 2026-10-14 06:12 UTC
**Environment:** https://staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner
**Spec:** checkout.spec.ts > gift card > applies a gift card to an order in EUR
**Severity:** High. A paying customer cannot redeem a gift card at checkout and is shown a generic error with no recovery path.
**Priority:** High. Proposed release blocker for 4.12.0 (assumption, see below).
**Reproducibility:** Intermittent, 3 of 10 attempts on the same commit (30%).

## Summary

The gift card endpoint `POST /api/checkout/gift-card` sometimes returns HTTP 500 with an unhandled `TypeError` instead of applying the card. When it fails, the storefront shows a generic "Something went wrong" toast and the order total is unchanged. The same build, same commit, and same inputs succeed on the other attempts, so the failure depends on server-side state rather than on the request.

## Steps to reproduce

1. Sign in as buyer.eur@shop.example on the EUR store.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card GC-TEST-0042 (balance EUR 20.00) and press "Apply".
4. Repeat the steps. Running the spec with `--repeat-each=10` reproduces the failure on roughly 3 of 10 attempts.

## Expected result

The order summary shows "Gift card: -€20.00" and the total becomes €29.00.

## Actual result

A toast appears with "Something went wrong. Please try again." and the total stays at €49.00.

Network evidence from the failing attempts (4, 7, and 9 of 10):

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

The 7 passing attempts showed the expected summary. All three failures had the identical status and response body.

## Analysis

- The server reads `.currency` from a value that is sometimes undefined. The request inputs are identical across attempts, so the undefined value most likely comes from a dependency lookup that intermittently returns nothing, such as the store, cart, or gift card currency record.
- The error is unhandled. It escapes as a raw `TypeError` message in the response body, so there is no guard or fallback on this path.
- A developer on the team channel suggested "probably the currency service cache again, it was flaky last sprint too." This is a plausible lead and matches the symptoms, but it is unconfirmed. This report does not assert a root cause. If a prior ticket exists for that flakiness, it should be linked here.
- The storefront swallows the 500 into a generic toast, so the customer gets no indication that the card itself is fine.

## Impact

- Customers on the EUR store cannot reliably redeem gift cards. Each failed attempt leaves the full price in the total and may cause the customer to abandon checkout or pay without their credit.
- Other currencies are untested in this run and may be affected, since the failure is on a currency lookup rather than on EUR specifically.
- The e2e-staging pipeline is non-deterministic on this spec, which weakens the release signal for 4.12.0.

## Secondary observations

- The API returns the internal exception text to the client. This should be replaced with a sanitized error and the detail kept in server logs.
- The flake rate of 30% is high enough that this test should not be retried or quarantined to turn the pipeline green. The failure is a real defect.

## Suggested next steps

1. Pull server logs for the three failing requests and identify which object was undefined when `.currency` was read.
2. Check whether the currency service, or its cache, returned an empty or expired entry at those timestamps, to confirm or rule out the developer's hypothesis.
3. Add a guard on the gift card path that returns a proper 4xx or 5xx error with a clear message when the currency cannot be resolved, rather than crashing.
4. Rerun the spec with `--repeat-each=10` or higher after the fix, and extend coverage to at least one non-EUR store.

## Assumptions

- The 500 was observed only at the gift card endpoint. No other checkout endpoints were affected in this run.
- Gift card GC-TEST-0042 is a valid, unused test card with balance available on every attempt. The test does not consume the balance between repeats.
- The test user and cart state are reset between repeats, so the failure is not caused by leftover state from a prior attempt.
- Release blocker status is proposed because gift card redemption is a payment path. The release owner may downgrade if the feature is behind a flag or low in traffic.
- No code was inspected for this report. Findings are based solely on the CI log provided.

## Attachments to add

- Playwright trace and screenshot for attempts 4, 7, and 9.
- Server-side logs for the failing `POST /api/checkout/gift-card` requests.
- Link to the prior sprint's currency service flakiness ticket, if one exists.
