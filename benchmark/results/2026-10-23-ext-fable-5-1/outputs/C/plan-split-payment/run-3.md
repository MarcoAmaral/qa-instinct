# Test plan: Split payment (release 5.3)

## 1. Summary

This plan tests paying for 1 order with 2 cards through PayGate. It ranks risks by how likely they are and how much they cost if missed. The highest-ranked risks get tested first and on every PayGate sandbox day. Lower-ranked risks get tested with a local PayGate stub, or are accepted and monitored after release.

## 2. Assumptions

Information missing from the brief is filled in as follows. Each assumption is marked **A1** to **A10** and can be corrected without changing the plan's shape.

- **A1 Dates.** Today is Saturday 24 October 2026. The 10 working days are Monday 26 October to Friday 6 November. Release is Friday 6 November. Sandbox days are Tuesday 27 October, Thursday 29 October, Tuesday 3 November and Thursday 5 November.
- **A2 Tester effort.** Half time means 4 hours per day, about 40 hours in total. Developers test their own code with unit tests and support the tester on sandbox days.
- **A3 Currency.** Orders are in 1 currency with 100 minor units (for example USD or EUR). Zero-decimal currencies such as JPY are out of scope.
- **A4 Card data.** Card numbers are tokenised by PayGate in the browser. The feature stores tokens only. No new PCI scope is added.
- **A5 Charge order.** The first card is charged first. If the first charge is declined, the second card is not charged and the customer sees a decline message.
- **A6 Refund mechanism.** The refund after a second-card decline is a PayGate refund call, not a void. It runs from a background job, not from the web request.
- **A7 Limits.** The first-card amount must be at least 1 cent and at most the order total minus 1 cent. Both cards are allowed to be the same card.
- **A8 3-D Secure.** Cardholder authentication is not triggered for either card in this release.
- **A9 Feature flag.** Split payment ships behind a flag that is off at release and turned on in stages.
- **A10 Stub.** A local PayGate stub exists or can be built by a developer on day 1. It replays recorded sandbox responses, including decline and timeout cases.

## 3. Scope

**In scope**

- Choosing the split amount at checkout and the validation around it.
- Charging 2 cards through PayGate, including the remainder-cent rule.
- Automatic refund of the first charge when the second is declined, within 60 seconds.
- Order records, receipts and the customer's order history for split orders.
- The existing single-card checkout, which must keep working at about 4,000 orders a day.

**Out of scope**

- More than 2 cards.
- Later manual refunds of split orders by support staff, beyond 1 smoke test.
- Zero-decimal currencies, 3-D Secure, and PayGate's own correctness.

## 4. Risks, ranked

Likelihood and impact are rated 1 (low) to 3 (high). Priority is the product. Tests are run in priority order.

| ID | Risk | Likelihood | Impact | Priority | Why it matters |
| --- | --- | --- | --- | --- | --- |
| R1 | Second card declined, first charge not refunded, or refunded after 60 seconds | 3 | 3 | 9 | Customer money held with nothing delivered. Chargebacks and support load. |
| R2 | Split math wrong: the 2 charges do not add up to the order total, or the remainder cent goes to the wrong card | 2 | 3 | 6 | Accounting mismatch on every affected order. Hard to find later. |
| R3 | Single-card checkout breaks or slows down | 2 | 3 | 6 | About 4,000 orders a day at risk. |
| R4 | Duplicate charges on retry, timeout or double submit | 2 | 3 | 6 | Customer charged twice. Often only found through complaints. |
| R5 | PayGate timeout or unknown result on either charge leaves the order in an undefined state | 3 | 2 | 6 | Orders stuck as neither paid nor failed. Manual clean-up. |
| R6 | Invalid split amounts accepted: 0, full total, more than total, negative, too many decimals | 2 | 2 | 4 | Charges of 0 or negative amounts, or a card never charged. |
| R7 | Receipts, order history and admin screens show 1 charge instead of 2, or the wrong amounts | 2 | 2 | 4 | Customers and support cannot see what was charged. |
| R8 | Sandbox only available 4 days, so defects found late cannot be retested in time | 3 | 2 | 6 | Schedule risk, not a product risk. Handled in section 6. |
| R9 | Later partial refund of a split order refunds the wrong card or fails | 2 | 1 | 2 | Support can fix by hand. Smoke test only. |
| R10 | Second gateway call makes split checkout slow under load | 1 | 2 | 2 | Split orders are a small share at first. Monitor after release. |

## 5. Test approach by risk

Each risk lists the tests to run, where they run, and who owns them. "Stub" means the local PayGate stub (A10). "Sandbox" means the real PayGate sandbox on a Tuesday or Thursday.

### R1 Refund after second-card decline

- **Unit (developers, stub):** second charge declined triggers 1 refund call for the exact first amount. Refund job retries on PayGate error and logs each attempt. Refund job cannot run twice for the same order.
- **End to end (tester, sandbox):** 10 runs with a sandbox decline card as the second card. Record the time from decline to refund confirmed. Pass if every run is under 60 seconds and the order is marked failed with a reason the customer can read.
- **Failure cases (tester, stub):** refund call times out, refund call returns an error, the job runner is down for 30 seconds. Pass if the refund still completes and an alert is raised when it cannot.
- **Monitoring (developers):** a metric for refund latency and a count of orders in the "awaiting refund" state for more than 60 seconds, with an alert.

### R2 Split math

- **Unit (developers):** a table of cases, each checked for first amount, second amount and total. Minimum cases:

| Order total | First-card choice | Expected first | Expected second |
| --- | --- | --- | --- |
| 100.00 | 50.00 | 50.00 | 50.00 |
| 100.01 | half | 50.01 | 50.00 |
| 0.03 | half | 0.02 | 0.01 |
| 0.02 | 0.01 | 0.01 | 0.01 |
| 99.99 | 0.01 | 0.01 | 99.98 |
| 99.99 | 99.98 | 99.98 | 0.01 |
| 1,000,000.00 | 333,333.33 | 333,333.33 | 666,666.67 |

- **End to end (tester, sandbox):** 3 of the cases above through the real checkout. Check the amounts in the PayGate sandbox dashboard, not only in the app.
- **Check:** amounts are integers in cents everywhere in the code. No floating-point arithmetic on money. A developer confirms this by code review on day 1.

### R3 Single-card regression

- **Automated (existing suite, developers):** the full checkout regression suite runs on every build. It runs against the stub on all days and against the sandbox on sandbox days.
- **Manual smoke (tester, sandbox):** 5 single-card orders per sandbox day, including 1 decline and 1 with a saved card. Covers the same page the split option was added to.
- **Performance (developers):** compare median checkout time for single-card orders before and after the change on the stub. Pass if the difference is under 50 milliseconds.
- **Flag off (tester):** with the feature flag off, the checkout page shows no split option and behaves exactly as in release 5.2.

### R4 Duplicate charges

- **Unit (developers, stub):** every charge and refund call carries an idempotency key. Replaying the same request produces no second charge.
- **End to end (tester, sandbox):** submit the payment form twice quickly. Refresh the page during the second charge. Press back and resubmit after a success. Pass if PayGate shows 1 charge per card per order.

### R5 Timeouts and unknown results

- **Stub (tester):** first charge times out. Second charge times out after the first succeeded. PayGate returns HTTP 500 on the second charge. Pass if the order ends in exactly 1 of these states: paid, failed with refund done, or flagged for manual review with an alert. No order may be left in an in-between state.
- **Sandbox (tester):** 1 run of the "second charge times out" case if the sandbox supports it. If it does not, the stub result stands and the gap is recorded in the release notes.

### R6 Invalid split amounts

- **Tester, stub, day 3:** first amount of 0, equal to total, total plus 0.01, negative, 3 decimal places, blank, letters, and a value changed in the browser after validation. Pass if each is rejected with a message before any charge is made, and the server rejects it even if the browser does not.
- **Same card twice (A7):** allowed and both charges succeed.

### R7 Receipts and history

- **Tester, sandbox:** for 1 successful split order and 1 refunded split order, check the confirmation page, the email receipt, the customer's order history and the admin order view. Each shows 2 charges, the last 4 digits of each card, and the amounts from the R2 table.

### R9 Later partial refund

- **Tester, sandbox, day 9:** 1 smoke test. Support refunds 10.00 from a split order. Pass if the refund goes to a card and the order shows the right remaining balance. Any defect here is logged for release 5.4 unless it loses money.

### R10 Load

- Not tested before release. The feature flag limits exposure. Checkout latency and PayGate error rate are watched during the staged rollout (section 8).

## 6. Schedule

Sandbox days carry the end-to-end work. All other days use the stub. The tester's 4 hours per day are shown; developer tasks sit alongside their build work.

| Day | Date | Tester (4 h) | Developers |
| --- | --- | --- | --- |
| 1 | Mon 26 Oct | Review this plan with developers. Write the R2 case table and R6 case list. | Build or update the PayGate stub (A10). Code review for integer cents. Add idempotency keys. |
| 2 | Tue 27 Oct (sandbox) | Confirm sandbox decline, timeout and error test cards. Record their responses for the stub. Run single-card regression on sandbox. | Load recorded responses into the stub. |
| 3 | Wed 28 Oct | R6 validation tests on stub. R5 timeout tests on stub if the build is ready. | Unit tests for R1, R2 and R4 pass. |
| 4 | Thu 29 Oct (sandbox) | First end-to-end pass: R2 happy path, R1 decline and refund timing, R4 double submit. Single-card smoke. | On call for defects. |
| 5 | Fri 30 Oct | Log and triage defects. Retest fixes on stub. | Fix day. |
| 6 | Mon 2 Nov | R5 remaining cases on stub. R3 flag-off check. Prepare R7 checklist. | Fix day. Performance comparison for R3. Alerts for R1. |
| 7 | Tue 3 Nov (sandbox) | Full pass: R1 with 10 timed runs, R2, R4, R7. Single-card regression on sandbox. | On call for defects. |
| 8 | Wed 4 Nov | Retest fixes on stub. Write release notes with any gaps. | Fix day. Code freeze at end of day. |
| 9 | Thu 5 Nov (sandbox) | Release candidate pass: R1 10 timed runs, R2 3 cases, R3 smoke, R7, R9. | No new changes. Hotfixes only. |
| 10 | Fri 6 Nov | Go or no-go meeting. Watch the first staged rollout. | Release with flag off. Enable the flag for staff accounts. |

**Schedule risk R8.** A defect found on Thursday 5 November cannot be retested on the sandbox before release. To reduce this, the pass on Tuesday 3 November is treated as the real release test, and Thursday 5 November is a repeat. If a severity 1 defect is found on Thursday 5 November, the release goes out with the flag off and the flag stays off until the next sandbox day, Tuesday 10 November.

## 7. Entry and exit criteria

**Entry to sandbox testing (Thursday 29 October)**

- The build is deployed to the test environment with the flag on.
- Developer unit tests for R1, R2 and R4 pass.
- The stub replays the recorded sandbox responses.

**Exit for release (Friday 6 November)**

- All R1 to R7 tests pass on the sandbox on Tuesday 3 November or Thursday 5 November.
- 10 of 10 timed refund runs complete in under 60 seconds.
- The single-card regression suite passes on the release candidate.
- No open severity 1 or 2 defects. Severity 1 is money lost or charged twice. Severity 2 is an order left in an undefined state or a wrong amount shown.
- Alerts for refund latency and stuck orders are live.
- A rollback plan exists: turning the flag off restores release 5.2 behaviour without a deploy.

## 8. Release and after

- Release with the flag off on Friday 6 November.
- Enable for staff accounts first. Each tester and developer places 1 split order with real cards for a small amount and confirms the receipt.
- Enable for 5 percent of customers for 2 working days, then 50 percent, then all. Pause at any stage if refund latency exceeds 60 seconds, the stuck-order count is above 0, or the single-card error rate rises.
- The tester reviews split-order support tickets daily for the first week and adds any new case to the regression suite.

## 9. Defects and reporting

- Defects are logged the day they are found with the risk ID, the sandbox or stub, the order ID, and the PayGate request ID.
- A 1-page status is sent at the end of each sandbox day: tests run, pass and fail counts per risk, open defects by severity, and whether the exit criteria are on track.

## 10. Open points for the product owner

These do not block testing but change the result if the assumption is wrong.

- A5: confirm the first card is charged first and a first-card decline stops the order.
- A7: confirm the same card may be used twice and the minimum amount per card is 1 cent.
- A8: confirm 3-D Secure is not triggered in this release. If it is, R1 and R4 need extra cases and 1 more sandbox day.
- A6: confirm the refund is a refund and not a void. A void is faster but may not be available after settlement.
