# Test plan: Split payment (release 5.3)

Status: draft for review. Owner: QA tester. Reviewers: the 2 feature developers and the product owner.

## 1. Scope

This plan covers the split payment feature, where a customer pays for 1 order with 2 cards, and the existing single-card checkout, which must keep working.

In scope:

- Entering a split amount and the resulting 2 charges.
- Cent arithmetic, including the remainder cent rule.
- Decline of the second charge and the automatic refund of the first charge within 60 seconds.
- Decline of the first charge.
- Behaviour when PayGate is slow, times out, or returns an error.
- Order records, receipts and customer-facing messages for a split order.
- Regression of single-card checkout.

Out of scope:

- 3 or more cards.
- Refunds started manually by support after the order.
- PayGate's own behaviour beyond what its sandbox returns.
- Load testing of PayGate itself.

## 2. Assumptions

The brief leaves these points open. Each assumption below stands until someone corrects it.

| Topic | Assumption |
| --- | --- |
| Currency | All orders are in 1 currency with 100 minor units per major unit. |
| Minimum amount | Each card must carry at least 1 cent. The interface rejects 0 and amounts above the order total. |
| Charge order | The first card is charged first. The second card is charged only if the first charge succeeds. |
| First charge declined | The second card is not charged and the customer sees a decline message. |
| Refund timer | The 60 seconds start when the decline response for the second charge arrives. |
| Refund failure | If the automatic refund fails, the order is flagged for manual follow-up and an alert is raised. |
| Sandbox hours | The PayGate sandbox is open all day on Tuesdays and Thursdays. |
| Stub | The developers provide a PayGate stub for other days that can return approve, decline, timeout and error. |
| Feature flag | Split payment sits behind a feature flag and can be turned off in production without a deploy. |
| Unit tests | The developers write and run unit tests for the cent arithmetic and the refund logic. |
| Dates | Today is Friday 24 October 2026. The 10 working days are Monday 26 October to Friday 6 November. |

## 3. Risks, ranked

Risks are ranked by how badly the customer or the business is hurt, multiplied by how likely a defect is. The top risks get the most test time and the earliest sandbox slots.

| Rank | Risk | Harm if it happens | Why it is likely |
| --- | --- | --- | --- |
| 1 | The first charge is not refunded, or is refunded late, after the second card is declined. | Customer is charged for an order they did not get. Chargebacks and support load. | Depends on an external gateway, timing, and error handling. |
| 2 | Single-card checkout breaks or slows down. | About 4,000 orders a day at risk. | Shared checkout code changes. |
| 3 | Cent amounts are wrong. The 2 charges do not add up to the order total, or the remainder cent lands on the wrong card. | Over- or under-charging. Accounting mismatch. | Rounding and integer maths are easy to get wrong. |
| 4 | Both charges succeed but the order is recorded as failed, or 1 charge succeeds and the order is recorded as paid. | Customer charged with no order, or order shipped unpaid. | Two charges and one order state make more paths than the current code handles. |
| 5 | A PayGate timeout on the second charge leaves the first charge unrefunded with no record. | Same as risk 1, but hidden. | Timeouts are rarely tested. |
| 6 | The customer can enter an invalid split, for example 0, a negative number, or more than the total. | Failed charges, confusing errors. | New input field. |
| 7 | Receipts, emails and the order page show 1 card or the wrong amounts. | Customer confusion and support tickets. | New data shape in existing templates. |
| 8 | Customers retry during the refund window and are charged twice. | Double charge. | Users double-submit on slow pages. |

## 4. Test approach by risk

Each risk below lists the tests, where they run, and who runs them. "Stub" means the local PayGate stub. "Sandbox" means the real PayGate sandbox on a Tuesday or Thursday.

### Risk 1: Refund after second-card decline

- Second card declined, first charge refunded. Check the refund is requested, succeeds, and completes within 60 seconds. Record the measured time. Stub, then sandbox.
- Second card declined, refund request fails once. Check the retry and the final state. Stub.
- Second card declined, refund request fails every time. Check the order is flagged, an alert is raised, and the customer message is honest. Stub.
- Second card declined, refund takes more than 60 seconds. Check what the system does and what the customer sees. Stub with delay.
- Second card declined on the sandbox, using the PayGate test cards for each decline reason: insufficient funds, stolen card, expired card, wrong CVV. Sandbox.
- Confirm the refund is a full refund of the first charge, to the cent, including the remainder cent. Sandbox.

Owner: tester, with 1 developer for the stub cases.

### Risk 2: Single-card checkout regression

- Run the existing single-card checkout automated suite on every build. Developers.
- Manual smoke test of single-card checkout with the feature flag on and off. Tester, every build.
- Compare checkout response time before and after the change on a staging build with the flag on and off. If no timing tool exists, record 10 manual checkouts with a stopwatch and compare the averages. Tester, once in week 2.
- Confirm the feature flag off path never calls the split code. Developer code review plus 1 manual check.

### Risk 3: Cent arithmetic

- Unit tests for the split function, written by the developers and reviewed by the tester. Cases: even split, odd total, 1 cent total, 2 cent total, large total, total equal to first-card amount, first-card amount of 1 cent.
- Tester checks the table below by hand on the stub.

| Order total | First card entered | Expected first charge | Expected second charge |
| --- | --- | --- | --- |
| 10.00 | 5.00 | 5.00 | 5.00 |
| 10.01 | 5.00 | 5.00 | 5.01 |
| 10.01 | half | 5.01 | 5.00 |
| 0.01 | half | 0.01 | 0.00 (rejected, see risk 6) |
| 99.99 | 99.98 | 99.98 | 0.01 |
| 1,234.56 | 0.01 | 0.01 | 1,234.55 |

The "half" rows assume the interface offers an even split button. If it does not, delete those rows.

### Risk 4: Order state

- Both charges approved: order is paid, both charge IDs are stored on the order. Stub and sandbox.
- First charge declined: order is not paid, second card is not charged, no refund is attempted. Stub and sandbox.
- Second charge declined and refund succeeds: order is not paid, refund ID is stored. Stub and sandbox.
- Second charge declined and refund fails: order is flagged, not paid. Stub.
- Check the order in the admin tool and in any export used by finance. Tester.

### Risk 5: Timeouts and gateway errors

- First charge times out: order not paid, no second charge. Stub.
- Second charge times out: first charge is refunded, same rules as a decline. Stub.
- PayGate returns an HTTP 500 on the second charge. Same expected result as a timeout. Stub.
- Refund call times out: retry, then flag. Stub.
- Check logs for each case so support can trace what happened. Tester with a developer.

### Risk 6: Input validation

Test each value in the first-card amount field on the stub: 0, blank, negative, letters, more than the total, exactly the total, 1 cent, 3 decimal places, a comma as the decimal separator, pasted text with a currency symbol. Expected: a clear message and no charge for invalid values. Tester, 1 session.

### Risk 7: Receipts and messages

- Order confirmation page, confirmation email and order history show both cards, last 4 digits, and the amount on each. Stub.
- After a refund, the customer email and order page say which card was refunded and how much. Sandbox, because the refund email may depend on a real gateway event.
- Check on 1 desktop browser and 1 mobile browser. Tester.

### Risk 8: Double submission

- Select the pay button twice quickly. Expect 1 pair of charges. Stub.
- Refresh the page during the refund window. Expect no new charge. Stub.
- Use the browser back button after a decline and resubmit. Expect a fresh, correct pair of charges and no leftover from the first attempt. Sandbox.

## 5. Schedule

The tester has about 5 days of effort across the 10 working days. The 4 sandbox days are the fixed points. All stub testing happens on other days so sandbox time is spent only on tests that need the real gateway.

| Day | Date | Tester activity | Developer activity |
| --- | --- | --- | --- |
| 1 | Mon 26 Oct | Review this plan with the team. Agree the assumptions. Confirm the stub exists. | Build. Deliver the stub by end of day. |
| 2 | Tue 27 Oct | Sandbox: confirm sandbox access, test cards and refund behaviour by hand, with no feature code yet. Record how long a sandbox refund takes. | Build. |
| 3 | Wed 28 Oct | Stub: risk 3 table, risk 6 input checks on the first build. | Build. Unit tests for cent arithmetic done. |
| 4 | Thu 29 Oct | Sandbox: happy path and first-charge decline (risk 4) on the first build. | Build. Refund logic done. |
| 5 | Fri 30 Oct | Stub: risk 1 and risk 5 failure cases. Report defects. | Fix defects. |
| 6 | Mon 2 Nov | Stub: risk 4 and risk 8. Single-card regression with flag on and off (risk 2). | Fix defects. Run the single-card suite. |
| 7 | Tue 3 Nov | Sandbox: full risk 1 run with every decline reason. Measure refund time. Risk 7 refund emails. | Fix defects. |
| 8 | Wed 4 Nov | Retest fixes on the stub. Risk 7 receipts and pages. Timing comparison for risk 2. | Fix defects. Code freeze end of day. |
| 9 | Thu 5 Nov | Sandbox: final run of risk 1, risk 4 and risk 8 on the release candidate. | Release candidate build. |
| 10 | Fri 6 Nov | Exit review. Go or no-go decision. Release. | Release and monitor. |

If the feature is not testable on the stub by Wednesday 28 October, the Thursday 29 October sandbox slot is lost. Say so in the daily standup on Tuesday 27 October so the team can decide early.

## 6. Entry criteria

Testing on a build starts only when:

- The build is deployed to a test environment with the feature flag on.
- The PayGate stub can return approve, decline, timeout and HTTP 500 on request.
- The developers' unit tests pass.
- Sandbox credentials and the PayGate test card list are available to the tester.

## 7. Exit criteria

The feature is ready to release when all of these are true:

- Every risk 1 test passes on the sandbox on the release candidate. Measured refund time is under 60 seconds in every run.
- No open defects of severity 1 or 2. Severity 1 means money is wrong or lost. Severity 2 means the order state is wrong.
- The single-card automated suite passes on the release candidate.
- Single-card checkout timing is within 10% of the pre-change measurement.
- The feature flag turns the feature off cleanly, verified on the release candidate.
- Every assumption in section 2 has been confirmed or corrected.

If the exit criteria are not met on Friday 6 November, the recommendation is to release 5.3 with the feature flag off rather than delay the release.

## 8. Release day checks

After release, with the flag on:

1. Make 1 real split order with 2 company test cards and confirm both charges in PayGate.
2. Make 1 real split order where the second card is a card known to decline, and confirm the refund within 60 seconds.
3. Watch single-card order volume for 2 hours. A drop of more than 10% against the same weekday last week is a signal to turn the flag off.
4. Watch the alert for failed refunds for the first 2 days.

## 9. Defect reporting

Report each defect with: the build number, stub or sandbox, the order total and split entered, the test card used, the PayGate charge IDs, the time of the test, and the order ID. Severity 1 and 2 defects are raised in the team chat the same day, not only in the tracker.

## 10. What this plan does not cover, and why

- Load testing of split payment. The feature is new and volume is unknown. Single-card volume is covered by the timing check in risk 2.
- Accessibility of the new field. No time in a 5-day budget. Flagged for the next release.
- Currency conversion. Out of scope by the single-currency assumption.
- PayGate outage during a live refund. Covered only on the stub, because the sandbox cannot simulate an outage. The refund-failure alert is the safety net.

## 11. Open points for the review on Monday 26 October

- Who owns the manual follow-up when an automatic refund fails?
- Is there an even-split button in the interface, or does the customer always type the amount?
- Is the 60-second limit a contractual promise to customers or an internal target?
- Can finance confirm how a split order should appear in their export?
