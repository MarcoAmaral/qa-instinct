# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** two-card split at checkout, cent arithmetic and remainder rule, both PayGate charges, automatic refund of the first charge when the second is declined, and non-regression of single-card checkout.

**Out of scope:** more than two cards, split across non-card methods, partial refunds after fulfilment, PayGate's own internals.

**Assumptions, stated because the brief does not say:**

- Release date is Friday 6 November 2026. Sandbox days in the window are 27 Oct, 29 Oct, 3 Nov and 5 Nov.
- "Cannot be split evenly" refers to an "split evenly" option. Custom amounts are entered by the customer in whole cents, so no rounding occurs there.
- The first-card amount must be at least 1 cent and at most total minus 1 cent. Anything else is a validation error, not a single-card order.
- Card data is tokenised by PayGate. The application never stores PANs, so PCI scope is unchanged.
- "Declined" includes hard declines, soft declines, gateway timeouts and 5xx errors. All of them must trigger the refund.
- The refund is an asynchronous job that retries on failure. The 60-second clock starts at the second charge's failure response.
- The developers will build a PayGate stub that replays recorded sandbox responses, so testing can continue on non-sandbox days.
- An automated regression suite exists for single-card checkout. If it does not, the Friday 30 Oct slot becomes a manual regression pass and exploratory time is cut.
- The feature ships behind a feature flag with a kill switch.

## 2. Risk register

Ranked by likelihood times impact. Priority drives the order of testing and what must pass before release.

| # | Risk | Impact | Likelihood | Priority |
|---|------|--------|-----------|----------|
| R1 | Second card declined but first charge not refunded, or refunded late | Customer charged with no order; chargebacks; support load | Medium | P1 |
| R2 | Single-card checkout regresses | 4,000 orders/day at risk; direct revenue loss | Medium | P1 |
| R3 | Cent arithmetic wrong: totals do not add up, remainder on wrong card, negative or zero amounts | Over- or under-charging; reconciliation failures | Medium | P1 |
| R4 | Double charge on retry, timeout or ambiguous gateway response | Customer charged twice; refund logic may not cover it | Medium | P1 |
| R5 | Order left in inconsistent state when the customer abandons, refreshes or double-submits between the two charges | Orders paid but not placed, or placed but not fully paid | Medium | P2 |
| R6 | Input validation gaps on first-card amount | Bad requests reach PayGate; confusing errors | High | P2 |
| R7 | Refund itself fails at PayGate and is not retried or alerted | Same outcome as R1, but silent | Low | P2 |
| R8 | Reconciliation and reporting do not show two charges and a refund per order | Finance cannot reconcile; hard to detect R1 in production | Medium | P3 |
| R9 | Sandbox unavailable or unstable on a scheduled day | Schedule slips; untested paths at release | Medium | Schedule |
| R10 | Half-time tester is the single point of failure | Coverage gaps | Medium | Schedule |

## 3. Test approach by risk

Three layers, each usable on different days:

- **Unit tests (developers, any day):** cent arithmetic, remainder rule, validation, state machine for the two-charge flow. Tester reviews cases, does not write them.
- **Stub-based integration (tester, non-sandbox days):** full checkout against the PayGate stub. Covers timeouts, 5xx, malformed responses and refund failures that the sandbox cannot produce on demand.
- **Sandbox end-to-end (tester plus one developer, Tue/Thu):** real gateway behaviour, real refund timing, real decline codes.

**R1 Refund on decline (P1).** On the sandbox: second card hard decline, soft decline, insufficient funds. Measure time from decline response to refund confirmed at PayGate. Run each case at least three times on two separate sandbox days. On the stub: second charge timeout, 5xx, and malformed response all trigger the refund. Verify the order ends in a single terminal "payment failed, refunded" state and the customer sees one clear message.

**R2 Single-card regression (P1).** Run the existing regression suite against the stub on 30 Oct and against the sandbox on 3 Nov. Add an explicit check that an order with the split option untouched sends exactly one charge. Check feature flag off produces the pre-5.3 checkout byte-for-byte in the request to PayGate.

**R3 Cent arithmetic (P1).** Unit tests for even split on odd totals, remainder cent on card one, totals of 1 cent, 2 cents, 3 cents, and large values near integer limits. Property test: for any total and any first-card amount in range, card one plus card two equals total. End-to-end check that the two sandbox charges sum to the order total for at least one odd and one even total.

**R4 Idempotency (P1).** Stub returns timeout on charge one, then the client retries. Verify exactly one charge is created and the idempotency key is reused. Same for charge two and for the refund. Verify double-submit of the checkout form creates one order and at most two charges.

**R5 Abandonment and state (P2).** Close the browser after charge one succeeds. Verify the order does not remain half-paid indefinitely: either charge two proceeds server-side or charge one is refunded after a defined timeout. Refresh mid-flow and verify no duplicate charges.

**R6 Validation (P2).** First-card amount of 0, equal to total, greater than total, negative, non-numeric, more than two decimals, empty. Both cards the same card number. Expired or invalid second card entered before charge one is attempted, to confirm the first charge is not made needlessly.

**R7 Refund failure (P2).** Stub returns failure on the refund call. Verify retry with backoff, an alert raised, and the order flagged for manual action. Nothing should silently swallow the failure.

**R8 Reconciliation (P3).** Admin and finance views show two transactions and, where applicable, one refund per order. Export matches PayGate's sandbox transaction list.

**Exploratory (if time allows):** mixed card brands, 3DS challenge on the second card, currency display with the remainder cent, accessibility of the split control.

## 4. Schedule

Tester capacity is roughly four hours per day, about 40 hours in total. Sandbox days are protected for gateway work only.

| Day | Date | Activity |
|-----|------|----------|
| Mon | 26 Oct | Review plan with developers. Agree stub scope and sandbox test card set. Confirm regression suite runs. |
| Tue | 27 Oct | **Sandbox 1.** Record real responses for success, each decline type, timeout and refund. Smoke the happy path if a build exists. Developers build the stub from the recordings. |
| Wed | 28 Oct | Review unit tests for R3 and R6. Stub-based validation and arithmetic checks. |
| Thu | 29 Oct | **Sandbox 2.** Happy path, R1 decline and refund cases, first timing measurements. |
| Fri | 30 Oct | Single-card regression on the stub (R2). Retest fixes. |
| Mon | 2 Nov | Stub-based R4, R5, R7. Retest fixes. |
| Tue | 3 Nov | **Sandbox 3.** Full P1 and P2 pass. Single-card regression on sandbox. Repeat refund timing. This is the last day a found defect can be fixed and re-verified on the real gateway. |
| Wed | 4 Nov | Fix and retest on stub. R8 reconciliation. Exploratory. |
| Thu | 5 Nov | **Sandbox 4.** Confirmation run of all P1 cases only. Go/no-go decision by end of day. |
| Fri | 6 Nov | Release behind flag. Monitor. |

**If a sandbox day is lost (R9):** fall back to the stub for that day and move its sandbox cases to the next sandbox day. If 3 Nov is lost, recommend releasing with the flag off and enabling after a sandbox run the following week.

**If the tester is unavailable (R10):** developers own the sandbox sessions. The case list in section 3 is written so a developer can execute it without further briefing.

## 5. Entry and exit criteria

**Entry to sandbox 2:** stub exists, feature flag works, unit tests for arithmetic and validation pass.

**Exit for release:**

- All P1 cases pass on the real sandbox on 3 Nov or 5 Nov.
- Refund completed within 60 seconds in every measured run, with the slowest observed time recorded in the release notes.
- Single-card regression passes on both stub and sandbox.
- No open severity 1 or 2 defects. Severity 3 defects are listed in the release notes with an owner.
- A production alert exists for "charge one succeeded, charge two failed, refund not confirmed within 60 seconds".
- Kill switch verified to return checkout to single-card mode without a deploy.

## 6. Release recommendation

Enable the flag for a small share of traffic on 6 Nov and watch the refund alert and the split-order count for two working days before full rollout. Production load and real issuer behaviour cannot be exercised in the sandbox, so the first days of live traffic are part of the test.
