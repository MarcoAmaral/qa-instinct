# Test plan: Split payment (release 5.3)

**Release date:** Friday 6 November 2026 (10 working days from Monday 26 October).
**PayGate sandbox days in scope:** Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov.
**Test effort:** 1 tester at half time (about 5 person-days) plus the 2 developers for unit tests, a PayGate stub and fix verification.

## 1. Scope

In scope:

- Choosing a split amount and paying with two cards in checkout.
- The cent arithmetic, including the odd-cent rule.
- Both PayGate charges, and the automatic refund when the second charge is declined.
- Order status, receipts and payment records for split orders.
- Regression of the existing single-card checkout.

Out of scope:

- More than two cards.
- Changes to PayGate itself, fraud screening, or chargeback handling.
- Performance testing of PayGate. Only our own code is load-tested.

## 2. Assumptions

Where the brief is silent, this plan assumes the following. Each one should be confirmed with the developers on day 1.

| # | Assumption |
| --- | --- |
| A1 | One currency with 2 decimal places. Currencies with no minor unit (for example JPY) are not sold. |
| A2 | Checkout offers a **Split evenly** default and a field for a custom first-card amount. The odd-cent rule applies to the even split. |
| A3 | Each card must carry at least 1 cent. A first-card amount of 0 or equal to the total is rejected. |
| A4 | The first card is charged (captured) before the second is attempted, so a declined second charge needs a true refund, not a void. |
| A5 | The 60-second refund target is measured from PayGate's decline response to PayGate accepting the refund request. |
| A6 | The feature ships behind a feature flag that is off by default. |
| A7 | An automated regression suite exists for single-card checkout and runs in under an hour. |
| A8 | PayGate's sandbox provides test cards for approve, decline and timeout, and supports refunds. |
| A9 | The same card number entered twice is rejected with a message. |
| A10 | The developers can build a PayGate stub by Wednesday 28 October that returns approve, decline, timeout and refund failure on demand. |

## 3. Risks, ranked

Rating is likelihood times impact, on a scale of 1 to 3 each. Tests are planned from the top down, so if time runs out, the lowest rows are cut first.

| Rank | Risk | L | I | Score | What goes wrong for the customer |
| --- | --- | --- | --- | --- | --- |
| R1 | Refund after a declined second charge does not happen, or takes longer than 60 seconds | 2 | 3 | 6 | Customer's money is held with no order. Support load, chargebacks. |
| R2 | Single-card checkout breaks or slows down | 2 | 3 | 6 | About 4,000 orders a day at risk. Highest revenue exposure. |
| R3 | Split arithmetic is wrong: amounts do not add up to the order total, or the odd cent lands on the second card | 2 | 3 | 6 | Over- or under-charging. Accounting mismatch. |
| R4 | Second charge times out with an unknown outcome and the order is charged twice or left half-paid | 2 | 3 | 6 | Duplicate charges or stuck orders. |
| R5 | Refund request itself fails and nobody is told | 2 | 2 | 4 | Money held indefinitely. Needs an alert and a manual queue. |
| R6 | Invalid split amounts accepted: 0, negative, over the total, non-numeric, same card twice | 2 | 2 | 4 | Failed charges, confusing errors. |
| R7 | Receipts, order history and refund records show one charge instead of two | 2 | 2 | 4 | Support tickets, reconciliation errors. |
| R8 | Customer double-submits and charges are repeated | 1 | 3 | 3 | Duplicate charges. |
| R9 | Sandbox is unavailable on a planned day, or the build is late | 2 | 2 | 4 | Process risk. Covered by the stub and the contingency in section 7. |

## 4. Test approach by risk

**R1 Refund on declined second card.** Run the decline path at least 10 times on the real sandbox and record the time from decline to refund acceptance for each run. Pass only if all 10 are under 60 seconds and the first-card refund amount equals the first-card charge. Repeat once under load from the regression suite running at the same time. Also check the order status and the customer-facing message after the refund.

**R2 Single-card regression.** Run the full automated suite on every build. Run a manual smoke test of single-card checkout on each sandbox day against real PayGate. Compare checkout response time before and after the feature, with the flag off and on. The flag-off path must be byte-for-byte the existing behaviour.

**R3 Arithmetic.** Developers write unit tests covering the table below. The tester reviews the table against the code and adds any missing rows. No sandbox needed.

| Order total (cents) | Split | Expected card 1 | Expected card 2 |
| --- | --- | --- | --- |
| 2 | even | 1 | 1 |
| 3 | even | 2 | 1 |
| 1001 | even | 501 | 500 |
| 1000 | even | 500 | 500 |
| 1000 | custom 1 | 1 | 999 |
| 1000 | custom 999 | 999 | 1 |
| 99999999 | even | 50000000 | 49999999 |
| 1 | even | rejected (A3) | |

Also check that display amounts are formatted from cents, never recalculated from a decimal, and that the two amounts plus any tax and shipping equal the order total shown to the customer.

**R4 Timeout on the second charge.** Use the stub on weekdays to simulate no response, a late response after our timeout, and a response that arrives after the refund has already started. Confirm the system queries PayGate for the charge status before refunding or retrying. Confirm one refund at most. Repeat the case on the sandbox if it supports a timeout test card (A8).

**R5 Refund failure.** Stub returns an error on the refund call. Confirm the order goes to a visible "refund pending" state, an alert reaches the on-call channel, and a retry happens. Confirm the customer is not told the refund succeeded.

**R6 Validation.** Manual tests on the stub: 0, negative, more than the total, exactly the total, decimals with 3 places, letters, blank, same card twice, expired second card, and a first card that is declined (no second charge should be attempted, no refund needed).

**R7 Records.** For one approved split order and one refunded one, check the receipt email, the order page, the admin payment view and the export used by finance. Each must show two charges with their amounts and the refund where it applies.

**R8 Double submit.** Press pay twice quickly and submit from two tabs. Expect one order and at most two charges in total.

## 5. Schedule

The sandbox days are the bottleneck, so every weekday without it is used for stub and unit work, and every sandbox day is planned in advance with a fixed list.

| Day | Date | Sandbox | Tester (half day) | Developers |
| --- | --- | --- | --- | --- |
| 1 | Mon 26 Oct | No | Confirm assumptions A1 to A10. Write cases for R1, R3, R4, R6. | Start build. Start PayGate stub. |
| 2 | Tue 27 Oct | Yes | Baseline run: single-card checkout on sandbox, learn test cards, time a manual refund. Record timings. | Build. |
| 3 | Wed 28 Oct | No | Review arithmetic unit tests (R3). | Stub ready. Unit tests for R3 done. |
| 4 | Thu 29 Oct | Yes | If a build exists: happy-path split and one decline-refund run. If not: repeat baseline and test the stub against real responses. | Build. Fix anything found. |
| 5 | Fri 30 Oct | No | R6 validation and R4 timeouts on the stub. | Feature complete (target). |
| 6 | Mon 2 Nov | No | R5 refund failure, R8 double submit on stub. Run regression suite (R2). | Fixes. |
| 7 | Tue 3 Nov | Yes | Main integration run: 10 decline-refund timings (R1), happy path, R7 records, single-card smoke (R2). | Join the run. Fix same day. |
| 8 | Wed 4 Nov | No | Verify fixes on stub. Re-run regression suite. | Fixes. Code freeze end of day. |
| 9 | Thu 5 Nov | Yes | Release candidate run: repeat R1 timings, happy path, single-card smoke. Go/no-go meeting. | Verify fixes on sandbox. |
| 10 | Fri 6 Nov | No | Release with flag off. Turn flag on for internal accounts. Watch refund timings and single-card error rate. | Release. On call. |

## 6. Exit criteria

Release is approved when all of the following are true:

- All R1 sandbox runs on Thursday 5 November refunded in under 60 seconds.
- Arithmetic unit tests pass, including every row in section 4.
- The single-card regression suite is green on the release build. Single-card checkout response time is within 10 percent of the baseline from Tuesday 27 October.
- No open defects of severity 1 or 2. Severity 1 is money charged and not refunded, or single-card checkout failing. Severity 2 is wrong amounts, wrong records, or a missing alert.
- The refund-failure alert (R5) was seen to fire at least once in testing.

## 7. Contingencies

- **Sandbox down on a planned day.** Use the stub that day and move the sandbox list to the next sandbox day. If Thursday 5 November is lost, release on 6 November with the flag off and run the release-candidate list on Tuesday 10 November before turning the flag on.
- **Build not ready by Tuesday 3 November.** Only one sandbox day remains. Recommend releasing with the flag off and enabling it after a full sandbox run on 10 November.
- **Tester time short.** Cut in this order: R8, R7, R6 edge inputs. Never cut R1, R2 or R3.

## 8. Rollout after release

Enable the flag for internal accounts on Friday 6 November, then for 5 percent of customers on Monday 9 November. Watch three numbers daily for the first week: refund time for declined second charges, split orders left in a pending state, and single-card checkout error rate against the previous week. Turn the flag off if any refund exceeds 60 seconds or the single-card error rate rises.
