# Defect report: Gift card apply intermittently fails with HTTP 500 at EUR checkout

| Field | Value |
|---|---|
| Title | POST /api/checkout/gift-card intermittently returns 500 "Cannot read properties of undefined (reading 'currency')" for EUR orders |
| Severity | High. Checkout with a gift card fails for the customer with a generic error. Retry succeeds, and non-gift-card checkout is assumed unaffected, so not Critical. |
| Priority | P1. Release candidate 4.12.0-rc.2 is blocked until root cause is understood. |
| Component | Checkout API, gift card endpoint. Backend defect, not a test or frontend defect. |
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Environment | Staging, https://staging.shop.example, EUR store. Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner. |
| Reproducibility | Intermittent. 3 of 10 attempts failed on the same commit with identical inputs. |
| Detected by | Pipeline e2e-staging #3318, 2026-10-14 06:12 UTC, spec checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| Reporter | <account email, redacted> |
| Status | New |

## Description and reproduction

**Summary.** Applying a valid gift card with sufficient balance to a EUR order sometimes fails server-side. The API returns HTTP 500 with a TypeError. The frontend shows a generic "Something went wrong" toast and the order total is unchanged. The same request with the same data succeeds on other attempts, so the failure depends on backend state rather than on the input.

**Preconditions**
- Test user buyer.eur@shop.example exists on the EUR store.
- Product "Desk Lamp" is available at EUR 49.00.
- Gift card GC-TEST-0042 is active with a balance of EUR 20.00.

**Steps to reproduce**
1. Sign in as buyer.eur@shop.example.
2. Add "Desk Lamp" to the cart and open checkout.
3. Enter gift card code GC-TEST-0042 and press "Apply".
4. If the apply succeeds, remove the card and repeat step 3. Run at least 10 iterations.

**Expected result**
- Order summary shows "Gift card: -€20.00" and a total of €29.00 on every attempt.
- POST /api/checkout/gift-card returns a success status.

**Actual result**
- On roughly 3 of 10 attempts, the toast "Something went wrong. Please try again." appears and the total stays €49.00.
- The request fails:

```
POST /api/checkout/gift-card -> HTTP 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

**Observed frequency**

| Attempt | Result |
|---|---|
| 1, 2, 3, 5, 6, 8, 10 | Passed, expected summary shown |
| 4, 7, 9 | Failed, 500 with the body above |

## Evidence and analysis

- **This is a product defect, not test flakiness.** The assertion is correct and the backend returned a 500. The test should not be quarantined or retried away. If a retry must be added to unblock the pipeline, the defect stays open and the retry is tracked as debt.
- **The error is a null dereference in the backend.** Some object expected to carry a currency, such as the store, cart, order, or gift card record, was undefined when the handler read its currency field. Which object is unknown from the log alone.
- **The failure is state-dependent.** Same commit, same user, same card, same product, differing outcomes. Candidate causes are a cache miss or expiry on a currency or store lookup, a race between cart creation and gift card validation, or a dependency intermittently returning an empty response. These are hypotheses, not findings.
- **The developer's note is an unverified hypothesis.** The team channel message says it is "probably the currency service cache again". No evidence in this run confirms or rules that out. If the same symptom was seen last sprint, the earlier ticket or fix should be linked and the question of why it recurred answered.
- **Two secondary issues surfaced by this failure.** The API leaks an internal exception message to the client, which should be replaced by a stable error code and logged server-side. The toast gives the customer no actionable information, such as whether the card was charged or whether the code was rejected.
- **No partial state was observed.** The total stayed at €49.00 after the failure, so the frontend did not apply the discount locally. Whether the backend debited the gift card balance on the failed attempts is not verified and must be checked.

## Assumptions, impact and next steps

**Assumptions made because the log does not say**
- Timestamps and request IDs of the three failing attempts are available in the Playwright trace and in backend logs for pipeline #3318.
- The gift card is reusable in staging and its balance was not consumed by the seven passing attempts. If it was consumed, the balance shown in the test data is stale and should be confirmed.
- No other spec in pipeline #3318 failed, so the issue is scoped to the gift card endpoint.
- This test passed consistently on 4.12.0-rc.1 or earlier. If it did not, the regression window is wider than commit 9f3c2ab.
- Only the EUR store was exercised. Behaviour on other currency stores is untested.

**Customer impact if shipped.** About 3 in 10 gift card applications fail with an unhelpful message. Customers may retry and succeed, abandon checkout, or contact support. Any undebited or double-debited balance would be a financial correctness issue.

**Requested from engineering**
1. Pull backend logs and stack trace for the three failing requests and identify which object was undefined.
2. Confirm or reject the currency service cache hypothesis with evidence, and link the prior incident if it exists.
3. Check gift card balance and ledger entries for GC-TEST-0042 after the run to confirm no debit occurred on the failed attempts.
4. Add a guard and a proper error response with a stable error code. Do not expose exception text to clients.
5. Add an API-level test that exercises the cold-cache or missing-lookup path, so the regression is caught deterministically rather than at 30 percent.
6. Re-run checkout.spec.ts with --repeat-each=20 on the fix and attach results to this ticket.

**Attachments to add**
- Playwright trace and video for attempts 4, 7 and 9 from e2e-staging #3318.
- HAR or network log for the failing POST requests.
- Link to the team channel message and to the last sprint's ticket, if one exists.
