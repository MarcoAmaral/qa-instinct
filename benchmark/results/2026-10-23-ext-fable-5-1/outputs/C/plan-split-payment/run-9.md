# Test plan: Split payment (release 5.3)

## Summary

This plan puts the most test time on the 3 ways split payment can cost a customer or the business money: a stranded first charge, a wrong amount, and a broken single-card checkout. Everything else gets the time that is left.

## Assumptions

Where the brief is silent, the plan assumes the following. Each one should be confirmed on day 1.

- **Today is Friday 24 October 2026.** The release is Friday 6 November 2026. PayGate sandbox days are 27 Oct, 29 Oct, 3 Nov and 5 Nov. That is 4 sandbox days.
- **The tester has about 5 working days of effort** in total. Developers test their own code with unit tests and run the PayGate stub.
- **Charges run in order.** The first card is charged, then the second. The second is never attempted if the first is declined.
- **The customer can type any amount for the first card**, and the checkout also offers a "split evenly" option. The remainder-cent rule applies to that option.
- **Valid first-card amounts run from 1 cent to the order total minus 1 cent.** Anything else is rejected before any charge.
- **One currency, with cents.** Zero-decimal currencies are out of scope.
- **No 3-D Secure or similar card authentication** is in the flow.
- **A developer can build a PayGate stub** that returns the documented approve, decline, timeout and refund-failure responses. Without it, only 4 days of testing are possible.
- **Split payment ships behind a feature flag.** With the flag off, checkout is byte-for-byte the current single-card flow.
- **An automated regression suite exists for single-card checkout.**

## Risks, ranked

Priority combines how likely the failure is with what it costs. P1 risks are tested first, on every sandbox day, and block release if open.

| ID | Risk | Likelihood | Impact | Priority |
| --- | --- | --- | --- | --- |
| R1 | Second card declined, first charge not refunded, or refunded later than 60 seconds | Medium | High: customer paid for no order | P1 |
| R2 | Refund request itself fails and nobody is told | Medium | High | P1 |
| R3 | Amounts wrong: the 2 charges do not add up to the total, remainder cent on the wrong card, or floating-point rounding | Medium | High | P1 |
| R4 | PayGate timeout or lost response leaves a charge in an unknown state, causing double charges or stranded money | Medium | High | P1 |
| R5 | Single-card checkout breaks or slows for 4,000 orders a day | Low | Very high | P1 |
| R6 | Double submit, back button or retry after an error charges a card twice | Medium | High | P2 |
| R7 | Bad input accepted: 0, negative, more than the total, 3 decimals, same card twice | High | Medium | P2 |
| R8 | Order record, receipt, email and finance reports show 1 payment instead of 2, or later returns cannot refund across 2 cards | Medium | Medium | P2 |
| R9 | Second card details logged or stored in a way the first card is not | Low | High | P2 |
| R10 | Two gateway calls double checkout time past the page timeout | Low | Medium | P3 |
| R11 | Split controls unusable on mobile or with a screen reader | Medium | Low | P3 |
| R12 | Schedule: only 4 sandbox days, and defects found on day 9 cannot be retested on PayGate | High | High | Managed by plan |

## Approach by risk

**R1, R2: refund after a declined second card.** Measure the 60 seconds from the PayGate decline timestamp to the refund confirmation timestamp in the logs. Run it at least 10 times on sandbox and record each time. Use the stub to simulate a refund that fails and a refund that takes 90 seconds. Expect an alert, a retry, and the order in a manual-review queue. Expect the customer to see a message that says the first card will be refunded.

**R3: cent arithmetic.** Developers write unit tests on the split function with integer cents only. The tester runs the cases below through the UI against the stub, then confirms a sample on sandbox.

| Order total | Customer input | Card 1 | Card 2 |
| --- | --- | --- | --- |
| 10.00 | 4.00 on card 1 | 4.00 | 6.00 |
| 10.01 | Split evenly | 5.01 | 5.00 |
| 0.03 | Split evenly | 0.02 | 0.01 |
| 99,999.99 | Split evenly | 50,000.00 | 49,999.99 |
| 10.00 | 0.01 on card 1 | 0.01 | 9.99 |
| 10.00 | 9.99 on card 1 | 9.99 | 0.01 |
| 0.01 | Any | Split not offered | |
| 10.00 | Total changes after amounts entered (tax, shipping, coupon) | Amounts recalculated and shown again | |

**R4: unknown gateway state.** With the stub, return a timeout on the first charge, then on the second, then on the refund. Expect the system to query PayGate for the charge status, or void it, and never to place an order with money in an unknown state. Confirm on sandbox if PayGate offers a timeout test card.

**R5: single-card regression.** Run the automated suite on every build. On each sandbox day, place 5 single-card orders by hand with the feature flag on and 5 with it off. Compare checkout time with the current release. After release, watch the checkout error rate and the order count per hour for 48 hours.

**R6, R7: input and double submit.** Tester runs these against the stub. Includes: 0, negative, more than the total, exactly the total, 3 decimals, letters, blank, same card number on both, and a double-click on **Pay**.

**R8: records and reports.** Place a successful split order and check the order page, the customer email, the admin order view and the finance export. Then refund part of that order from admin and check which card is credited.

**R9: card data.** Search logs and the database for the second card's number and CVV after a sandbox run. Expect nothing beyond what is stored for the first card.

**R10, R11:** one timed run of a split order against sandbox, and one pass on a phone and with a screen reader. Done only if P1 and P2 work is complete.

## Schedule

| Day | Date | Sandbox | Work |
| --- | --- | --- | --- |
| 1 | Mon 26 Oct | No | Confirm assumptions. Developers start the stub. Tester writes P1 cases. |
| 2 | Tue 27 Oct | Yes | Record real PayGate responses for approve, decline, refund and timeout. Developers copy them into the stub. First exploratory pass on the build. |
| 3 | Wed 28 Oct | No | Developers finish unit tests for cent arithmetic. Tester runs R3 and R7 cases on the stub. |
| 4 | Thu 29 Oct | Yes | R1 and R4 end to end on sandbox. First 10 refund timings recorded. |
| 5 | Fri 30 Oct | No | Single-card regression on the stub. Defect fixes. |
| 6 | Mon 2 Nov | No | Retest fixes on the stub. R2, R6, R8 cases. |
| 7 | Tue 3 Nov | Yes | Full P1 pass on sandbox with the fixed build. Refund-failure cases. |
| 8 | Wed 4 Nov | No | R9 log check. P3 work if time allows. Code freeze at end of day. |
| 9 | Thu 5 Nov | Yes | Final sandbox regression: all P1, single-card orders, flag on and off. Go or no-go. |
| 10 | Fri 6 Nov | No | Release with the flag on for 5% of orders. Monitor refunds and error rate. |

Code freeze on day 8 is the key schedule rule. A fix after day 8 cannot be retested on sandbox before release, so it waits for 5.4 or the release slips.

## Roles

- **Tester:** owns this plan, runs all sandbox sessions, keeps the refund-timing log, and reports go or no-go on day 9.
- **Developer 1:** builds and maintains the PayGate stub, writes cent-arithmetic unit tests.
- **Developer 2:** runs the automated single-card suite on every build and fixes P1 defects first.

## Exit criteria

Release goes ahead only when all of the following are true.

- Every P1 case passes on PayGate sandbox, not only on the stub.
- All recorded refund timings are under 60 seconds, and a failed refund produces an alert and a manual-review entry.
- No open P1 or P2 defect.
- The automated single-card suite passes on the release build with the flag on and off.
- No card number or CVV appears in logs after a sandbox run.
- Monitoring is in place for refund time, refund failures and single-card error rate.

## Out of scope

- Three or more cards.
- Zero-decimal currencies and multi-currency orders.
- Card authentication flows such as 3-D Secure.
- Load testing beyond the single timed run in R10.

## Open items to confirm on day 1

- Does PayGate's sandbox offer test cards for timeout and refund failure? If not, those cases run only on the stub, and the plan says so in the release notes.
- Can a refund be requested from the same system that made the charge, or is it a separate PayGate credential?
- Does the admin order view already support 2 payments on 1 order, or is that part of this release?
