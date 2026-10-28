# Test plan: Split payment (release 5.3)

## Summary

This plan tests paying one order with 2 cards through PayGate. The highest risks are money being taken twice without a refund, wrong amounts in cents, and breaking the existing single-card checkout that handles about 4,000 orders a day. The plan puts the limited tester time and the 4 available sandbox days on those risks first.

## Assumptions

Where the brief is silent, the plan assumes the following. Correct any that are wrong before day 1.

| Topic | Assumption |
| --- | --- |
| Dates | Today is Friday 24 October 2026. The 10 working days run Monday 26 October to Friday 6 November. Release is Friday 6 November. |
| Sandbox days | PayGate sandbox is available on 27 October, 29 October, 3 November and 5 November. |
| Currency | One currency per order, with 100 minor units per major unit. No currency conversion. |
| Even split | Checkout offers a **Split evenly** option as well as a free-text amount for card 1. The remainder-cent rule applies to **Split evenly**. |
| Limits | Each card must carry at least 1 cent. Card 1 cannot carry the full amount or more. |
| Order of charges | Card 1 is charged first. Card 2 is charged only if card 1 succeeds. |
| Refund timer | The 60 seconds start when PayGate returns the decline for card 2. |
| Refund failure | If the automatic refund fails, the order is flagged for manual refund and an alert is raised. The customer is not charged twice silently. |
| Same card twice | The same card number may be used for both halves. |
| Test environment | A PayGate stub or mock can be run locally on non-sandbox days. The developers build it in week 1 if it does not exist. |
| Observability | Payment attempts, refunds and timings are logged with the order ID. |

## Scope

**In scope**

- Choosing the split amount and the **Split evenly** option.
- Both charges through PayGate, including decline, timeout and error on either card.
- Automatic refund of card 1 within 60 seconds when card 2 is declined.
- Cent rounding and the remainder-cent rule.
- Order status, receipts and emails for split orders.
- Regression of the single-card checkout.

**Out of scope**

- More than 2 cards.
- Partial refunds or returns after a split order is complete. Assumed to ship in a later release.
- PayGate's own correctness beyond its documented responses.
- Load testing beyond a smoke check of the split path.

## Risks, ranked

Priority combines how likely the failure is and what it costs. P1 risks are tested first and block release if open.

| # | Risk | Likelihood | Impact | Priority |
| --- | --- | --- | --- | --- |
| R1 | Card 2 declined but card 1 is not refunded, or refunded late or twice | Medium | Customer loses money; chargebacks; support load | P1 |
| R2 | Single-card checkout breaks or slows, affecting about 4,000 orders a day | Medium | Revenue loss for every customer | P1 |
| R3 | Amounts split wrongly in cents: rounding, remainder cent on wrong card, totals not matching the order | High | Wrong charges; accounting mismatch | P1 |
| R4 | Double charge from retries after a PayGate timeout or unknown response | Medium | Customer charged twice | P1 |
| R5 | Input validation lets card 1 take 0, negative, or more than the order total | High | Failed or wrong charges | P2 |
| R6 | Refund succeeds but order is left in a wrong state, or the customer gets a success email | Medium | Confused customers; manual clean-up | P2 |
| R7 | Receipts, order history and the admin view show one charge or wrong amounts | Medium | Support tickets; accounting errors | P2 |
| R8 | Sandbox unavailable on a planned day, or sandbox behaves differently from production | Medium | Testing slips past release | P2 (plan risk) |
| R9 | Concurrency: customer submits twice, or two browser tabs | Low | Double charge | P3 |
| R10 | Security: card data for the second card logged or stored | Low | Compliance breach | P3 |

## Test approach

Testing is split by what can run without the sandbox and what cannot. Sandbox days are reserved for things only PayGate can prove.

**1. Developer unit tests (any day, developers)**

- Split calculation: every cent total from 1 to 1,000, both free amount and **Split evenly**, assert card 1 + card 2 equals the total and the remainder cent lands on card 1.
- Input validation rules from R5.
- Refund decision logic: card 2 declined, timed out, or errored each triggers exactly one refund request.
- Idempotency keys on every charge and refund request.

**2. Integration tests against the PayGate stub (any day, developers plus tester)**

- All response combinations for card 1 and card 2: approved, declined, timeout, network error, malformed response.
- Refund timing measured in the test: refund request sent within 60 seconds of the decline. Target is under 10 seconds so production has margin.
- Refund failure path: stub rejects the refund, order is flagged, alert is raised.
- Duplicate submission from R9.

**3. PayGate sandbox sessions (Tuesdays and Thursdays, tester leads)**

Only cases that depend on PayGate's real behaviour:

- Happy path with 2 real sandbox cards.
- Card 2 declined using PayGate's decline test card, measure real refund time end to end.
- Card 1 declined, confirm card 2 is never charged.
- Same card on both halves.
- Confirm refund appears in the PayGate sandbox dashboard against the right charge.
- Rerun of any P1 defect fixed since the last session.

**4. Single-card regression (any day, tester)**

- Existing automated checkout suite runs on every build. If none exists, the developers record the 10 most common single-card paths as automated tests in week 1.
- Manual check of single-card checkout on the sandbox days as the first task, before any split testing.
- Compare checkout response time against the current release on the same stub.

**5. Exploratory testing (any day, tester)**

- 2 sessions of 1 hour each on the checkout screen: unusual amounts, browser back button, refresh between charges, mobile layout, currency symbols.

**6. Production smoke check (release day, developer on duty)**

- 1 real split order with a company card and a forced decline if PayGate supports it in production. Otherwise 1 real split order only.
- Watch refund alerts and single-card error rate for 2 hours after release.

## Key test cases

Cases are grouped by risk. Each sandbox case is marked **[S]**. All others run on the stub.

**R3 Amount split**

| Case | Total | Input | Expected card 1 | Expected card 2 |
| --- | --- | --- | --- | --- |
| T1 | 10.00 | **Split evenly** | 5.00 | 5.00 |
| T2 | 10.01 | **Split evenly** | 5.01 | 5.00 |
| T3 | 0.01 | **Split evenly** | 0.01 | rejected, card 2 would be 0 |
| T4 | 99.99 | card 1 = 0.01 | 0.01 | 99.98 |
| T5 | 99.99 | card 1 = 99.98 | 99.98 | 0.01 |
| T6 | 10.00 | card 1 = 3.333 | rejected or rounded to 3.33, per the agreed rule | |
| T7 | 1,234,567.89 | **Split evenly** | 617,283.95 | 617,283.94 |

**R5 Validation**

- T8: card 1 = 0, negative, blank, letters, more than total, equal to total. Each is rejected with a clear message.

**R1 and R4 Refund and double charge**

- T9 **[S]**: card 1 approved, card 2 declined. Refund of card 1 issued once, within 60 seconds, order marked failed, customer told both cards are not charged.
- T10: card 2 times out. Exactly 1 refund or 1 status query, never a second charge.
- T11: refund request fails. Order flagged, alert raised, no retry storm.
- T12: card 1 declined. Card 2 never contacted.
- T13: PayGate returns approved for card 2 after the client gave up. System reconciles and does not refund a completed order.

**R6 and R7 Order state and receipts**

- T14: successful split shows 2 charges with amounts on the receipt, order history and admin view.
- T15: refunded split shows the refund against card 1 and no success email.

**R2 Regression**

- T16: full single-card suite passes on every build.
- T17 **[S]**: manual single-card order on each sandbox day.
- T18: single-card checkout time within 10% of the current release.

**R9 and R10**

- T19: double submit and 2-tab submit create 1 order and at most 2 charges.
- T20: logs and database contain no full card number or security code for either card.

## Schedule

The tester has about 20 hours in total. Developers test their own units and share the stub integration work.

| Day | Date | Who | Work |
| --- | --- | --- | --- |
| 1 | Mon 26 Oct | Devs, tester | Confirm assumptions. Build or confirm the PayGate stub. Tester writes stub cases T1 to T15. |
| 2 | Tue 27 Oct | Tester | **Sandbox 1.** Confirm sandbox access, test cards and decline cards. Run T17 and the happy path on whatever is built. |
| 3 | Wed 28 Oct | Devs | Unit tests for split and validation complete. First build to tester. |
| 4 | Thu 29 Oct | Tester | **Sandbox 2.** T9, T12, T17 on the first build. Record refund timing. |
| 5 | Fri 30 Oct | Tester, devs | Stub runs of T1 to T13. Log defects. |
| 6 | Mon 2 Nov | Devs | Fix P1 defects. Regression suite running on every build. |
| 7 | Tue 3 Nov | Tester | **Sandbox 3.** Rerun all P1 cases on the fixed build. T14, T15, T19. |
| 8 | Wed 4 Nov | Tester | Exploratory sessions, T18, T20. Code freeze at end of day. |
| 9 | Thu 5 Nov | Tester, devs | **Sandbox 4.** Final run of T9, T12, T16, T17. Go or no-go decision. |
| 10 | Fri 6 Nov | Devs | Release. Production smoke check and 2-hour watch. |

If sandbox 1 is lost, sandbox 2 absorbs its work. If sandbox 3 or 4 is lost, the release moves to the next sandbox day plus 1. There is no spare sandbox day in this schedule.

## Roles

- **Tester**: owns this plan, writes and runs stub and sandbox cases, keeps the defect list, makes the go or no-go recommendation.
- **Developer 1**: split calculation, validation, unit tests, stub.
- **Developer 2**: charge and refund flow, idempotency, logging, regression suite automation.
- **Release owner** (assumed to be the team lead): makes the go or no-go decision on day 9.

## Entry criteria

- Assumptions confirmed or corrected.
- PayGate stub runs locally and can return approved, declined, timeout and error.
- Sandbox credentials and test card numbers in hand by day 2.

## Exit criteria

- All P1 cases pass on the stub and in the sandbox on the final build.
- No open P1 defect. Open P2 defects have a named owner and a date.
- Single-card regression suite passes on the release build.
- Measured refund time in the sandbox is under 60 seconds on every run, with the slowest run recorded.
- Refund failure alert has been seen to fire in the stub run.

## Plan risks and what we do about them

- **Only 4 sandbox days.** Everything that can run on the stub runs on the stub. Sandbox time is for PayGate behaviour only.
- **Tester is half time.** Developers own unit and stub tests. The tester reviews them rather than rewriting them.
- **Sandbox behaves differently from production.** The release-day smoke check with a real card is mandatory, and a developer watches alerts for 2 hours.
- **The 60-second rule has no stated owner if it is missed.** The plan treats any sandbox run over 60 seconds as a P1 defect.
- **Regression suite may not exist.** If it does not, 1 developer day in week 1 goes to it, because R2 affects every customer, not only those who split.

## Reporting

- Short written status at the end of each sandbox day: cases run, pass and fail counts, open P1 defects, slowest refund time.
- Go or no-go note on day 9 with the exit criteria listed and each marked met or not met.
