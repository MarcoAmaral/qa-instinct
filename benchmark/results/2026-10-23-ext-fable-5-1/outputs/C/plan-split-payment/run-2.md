# Test plan: Split payment (release 5.3)

## Summary

This plan tests that a customer can pay one order with 2 cards, that the 2 charges always add up to the order total, that a declined second charge refunds the first within 60 seconds, and that single-card checkout keeps working. Effort goes to the risks that can lose money or break the 4,000 daily single-card orders. Gateway tests are scheduled on the 4 sandbox days before release.

## Assumptions

- Today is Saturday 24 October 2026. Working days are Monday to Friday. Release is Friday 6 November 2026.
- PayGate sandbox days are 27 October, 29 October, 3 November and 5 November.
- An order uses one currency with 2 decimal places. Zero-decimal currencies are out of scope.
- Split payment is limited to 2 cards. The customer enters the amount for the first card. A **Split evenly** option exists and is where the remainder-cent rule applies.
- Each charge is a single capture, not an authorisation followed by a capture. The first card is charged before the second.
- PayGate provides test card numbers for approved, declined and timed-out responses, and an idempotency key on charge and refund requests.
- The feature ships behind a feature flag that is off by default and can be turned off in production without a deploy.
- An automated regression suite exists for single-card checkout. If it does not, the developers record a manual smoke set on day 1.
- The developers build a PayGate stub for use on non-sandbox days. The stub returns the same codes and timings as the sandbox.
- The tester has 5 days of effort in total. Developers own unit tests and stub-based tests.

## Risks, ranked

| # | Risk | Impact | Likelihood | Priority |
| --- | --- | --- | --- | --- |
| R1 | Single-card checkout breaks or slows for existing customers | High | Medium | P1 |
| R2 | Second card declined but first charge is not refunded, or refund takes over 60 s | High | Medium | P1 |
| R3 | The 2 charges do not add up to the order total, or the remainder cent goes to the wrong card | High | Medium | P1 |
| R4 | First card declined but second card is still charged | High | Low | P1 |
| R5 | PayGate timeout or lost response causes a double charge or a missed refund on retry | High | Medium | P1 |
| R6 | Order marked paid before both charges succeed, or left in an unclear state while a refund is pending | High | Medium | P1 |
| R7 | Customer submits twice and 4 charges are made | Medium | Medium | P2 |
| R8 | Invalid first-card amounts accepted: 0, equal to the total, more than the total, negative, more than 2 decimals | Medium | Medium | P2 |
| R9 | Same card used for both halves behaves differently from 2 different cards | Medium | Low | P2 |
| R10 | Finance reports and reconciliation cannot map 2 gateway transactions and 1 refund to 1 order | Medium | Medium | P2 |
| R11 | Card data or full card numbers appear in logs or error messages | High | Low | P2 |
| R12 | Sandbox outage on a planned day leaves gateway behaviour untested | Medium | Medium | P2 |

## Test approach by risk

**R1 Single-card regression.** Run the automated regression suite on every build. On each sandbox day, place 3 single-card orders on the sandbox: approved, declined, timed out. Compare checkout response time with a baseline taken on 27 October before the feature is merged. Any slowdown above 10 percent blocks release.

**R2 Refund on second-card decline.** On the stub: first approved, second declined, confirm one refund request for the exact first amount. On the sandbox: repeat 10 times and record the time from the decline response to the refund confirmation. All 10 runs must finish within 60 seconds. Also test second-card timeout and second-card refund failure, and confirm the order is flagged for manual follow-up with the customer told what happened.

**R3 Amount arithmetic.** Developer unit tests on the split function in cents:

- Total 1001, split evenly: first 501, second 500.
- Total 1000, split evenly: 500 and 500.
- Total 1, split evenly: 1 and 0, which must be rejected because the second charge is 0.
- Total 1000, first 1: second 999.
- Total 1000, first 999: second 1.
- Total 1000, first 1000: rejected.
- Customer input 10.005: rejected or rounded, as the product decides on day 1.
- Totals near the integer limit and totals with discounts and shipping applied.

The tester checks that the amounts shown on the review page, the receipt and the PayGate transactions all match for 5 orders on the sandbox.

**R4 First card declined.** Stub and sandbox: first declined, confirm no request is sent for the second card and the order stays unpaid.

**R5 Timeouts and retries.** Stub only, because timing is controlled: first charge succeeds but the response is lost, then the retry carries the same idempotency key and PayGate does not charge again. Refund request times out, then the retry succeeds and only 1 refund exists. Developers write these as integration tests against the stub. The tester runs the same 2 cases once on the sandbox on 3 November to confirm the stub matches real behaviour.

**R6 Order state.** Check the order status after each outcome: both approved, first declined, second declined with refund done, second declined with refund pending, second declined with refund failed. Status must only be paid when both charges are confirmed.

**R7 Double submit.** Select **Pay** twice quickly, and submit from 2 browser tabs. Exactly 2 charges are made.

**R8 Invalid amounts.** Manual tests on the checkout form with each invalid value. The form shows an error and does not call PayGate.

**R9 Same card twice.** Sandbox: both halves on the same test card, approved and declined cases.

**R10 Reconciliation.** Export the day's transactions from the admin reports after the 3 November sandbox run. Each split order shows 2 charges, and each refunded order shows 1 refund linked to the same order number.

**R11 Logs.** Search application logs after the sandbox runs for the test card numbers. Only the last 4 digits may appear.

**R12 Sandbox outage.** If a sandbox day is lost, the stub tests stand in and the final sandbox pass moves to the next sandbox day. Losing 5 November means the release slips, because R2 has not been proven against the real gateway.

## Schedule

| Day | Date | Sandbox | Work |
| --- | --- | --- | --- |
| 1 | Mon 26 Oct | No | Agree stub contract, test cards, rounding rule for inputs and the feature flag. Tester writes test cases. Developers start unit tests for R3. |
| 2 | Tue 27 Oct | Yes | Tester confirms sandbox access and test card behaviour. Records single-card baseline for R1. |
| 3 | Wed 28 Oct | No | Developers finish R3 unit tests and R5 stub tests. Tester reviews them. |
| 4 | Thu 29 Oct | Yes | First split build on sandbox. Happy path, R2 decline and refund timing, R4. |
| 5 | Fri 30 Oct | No | Fixes. Regression suite run. Tester tests R7 and R8 on the stub. |
| 6 | Mon 2 Nov | No | Fixes. R6 order state cases on the stub. |
| 7 | Tue 3 Nov | Yes | Full sandbox pass: R2 10 timed runs, R5 sample, R9, R10 export, R11 log search. |
| 8 | Wed 4 Nov | No | Fix verification on the stub. Regression suite. Code freeze at end of day. |
| 9 | Thu 5 Nov | Yes | Final sandbox pass of split payment and single-card. Go or no-go decision. |
| 10 | Fri 6 Nov | No | Release with the flag off. Turn the flag on for staff accounts. Place 1 real split order and 1 real single-card order with a company card and confirm both in PayGate. |

The tester's 5 days go to days 2, 4, 7 and 9 in full and half days on days 1 and 5. Developers cover the rest.

## Entry and exit criteria

Testing on the sandbox starts when the build passes the R3 unit tests and the regression suite.

Release goes ahead when:

- All P1 tests pass on the sandbox on 5 November.
- Refund time is within 60 seconds in 10 out of 10 sandbox runs.
- The regression suite passes and single-card response time is within 10 percent of the baseline.
- No open defects of severity 1 or 2. Open P2 defects are listed in the release note with an owner.
- The feature flag has been turned off and on in staging without a deploy.

## Out of scope

- Load testing of split payment. Volume is expected to be a small share of 4,000 orders a day, and the flag limits exposure.
- More than 2 cards, saved cards and wallets.
- Zero-decimal currencies and multi-currency orders.
- PayGate's own refund delays after it has confirmed the refund.

## Roles

- **Tester**: test cases, sandbox runs, regression baseline, go or no-go report on 5 November.
- **Developer 1**: split arithmetic unit tests, PayGate stub, R5 integration tests.
- **Developer 2**: order state tests, feature flag, production check on 6 November.
