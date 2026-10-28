# Test plan: Split payment (release 5.3)

## 1. Purpose and scope

This plan covers testing for the split payment feature, where a customer pays 1 order with 2 cards. It also covers regression of the existing single-card checkout.

In scope:

- Choosing the split amount and validating it
- Charging 2 cards through PayGate
- Cent arithmetic and the remainder-cent rule
- Automatic refund of the first charge when the second charge is declined
- Single-card checkout regression

Out of scope:

- More than 2 cards
- Changes to PayGate itself
- Refund timing for orders cancelled by the customer after both charges succeed (assumed unchanged from today)

## 2. Assumptions

Where the brief is silent, this plan assumes the following. Correct any that are wrong before day 2.

- Today is Friday 24 October 2026. The 10 working days are Monday 26 October to Friday 6 November. Release is Friday 6 November.
- PayGate sandbox days in that window are Tuesday 27 October, Thursday 29 October, Tuesday 3 November and Thursday 5 November. That is 4 sandbox days.
- Developers can provide a local PayGate stub that returns scripted approve, decline, timeout and error responses. Without it, logic tests can only run on sandbox days.
- The first card is charged before the second. If the first charge is declined, nothing is charged and the customer sees an error.
- The split amount must be at least 1 cent and at most the order total minus 1 cent. A split of 0 or the full amount is rejected and the customer is sent to single-card checkout.
- The customer may use the same card number for both charges. The feature does not block it.
- The 60-second refund window is measured from the moment PayGate returns the decline for the second charge.
- If the automatic refund fails, the order is flagged for manual refund and an alert is sent to the support team.
- Existing automated regression tests exist for single-card checkout and pass today.
- The tester has 5 days of effort in total across the 10 working days.

## 3. Risk assessment

Risks are ranked by impact to the customer and the business, then by likelihood. Testing effort follows this order. If time runs out, items at the bottom are cut first.

| Rank | Risk | Impact | Likelihood | Why it matters |
| --- | --- | --- | --- | --- |
| 1 | First charge is not refunded, or is refunded after 60 seconds, when the second charge is declined | Critical | Medium | Customer loses money for an order they did not get. Chargebacks and support load. |
| 2 | Single-card checkout breaks or slows down | Critical | Medium | About 4,000 orders a day go through it. Any failure is revenue loss within hours. |
| 3 | Total charged does not equal the order total because of rounding or the remainder-cent rule | High | Medium | Accounting mismatch on every affected order. Hard to detect without reconciliation. |
| 4 | Duplicate charges on retry, timeout or double submit | High | Medium | Customer is charged twice. PayGate timeouts are common in production. |
| 5 | Order ends in an inconsistent state after a partial failure | High | Medium | Order marked paid with only 1 charge, or marked failed with 1 charge kept. |
| 6 | Split amount validation accepts bad input | Medium | High | Negative, zero, full, over-total or non-numeric amounts reach PayGate. |
| 7 | PayGate errors other than decline are not handled | Medium | Medium | Network errors, 5xx responses and malformed replies behave differently from declines. |
| 8 | Refund failure is silent | Medium | Low | Nobody knows a customer is owed money. |
| 9 | Receipts, order history and emails show wrong amounts per card | Low | Medium | Customer confusion and support tickets, but no money lost. |

## 4. Test approach by risk

### Risk 1: Automatic refund within 60 seconds

Test type: integration with PayGate sandbox, plus stub-based timing tests.

- Second card declined for each decline reason the sandbox supports: insufficient funds, card expired, fraud block, invalid card.
- Measure time from decline to refund confirmation. Pass only if under 60 seconds in every run. Run at least 10 times on the sandbox.
- Refund is for the exact first-charge amount, including the remainder cent.
- Refund request is sent once, not repeated, if the customer refreshes the page.
- PayGate refund call times out or returns an error. Check the order is flagged for manual refund and the alert fires.
- PayGate refund call succeeds but the response is lost. Check the system does not refund twice on retry.

Evidence: PayGate sandbox transaction log and application logs with timestamps for each run.

### Risk 2: Single-card checkout regression

Test type: automated regression, manual smoke, and a performance check.

- Run the full existing single-card automated suite on every build.
- Manual smoke of single-card checkout on each sandbox day, with 1 approve and 1 decline.
- Compare checkout response time before and after the change at the same load. Pass if the median is within 10 percent of the baseline. Assumes a load test tool already exists. If not, compare the application's own timing logs over 1 day on staging.
- Check that a customer who never sees the split option has no change in the checkout flow.

### Risk 3: Cent arithmetic and the remainder cent

Test type: unit tests written by developers, reviewed by the tester, plus a stub-based end-to-end check.

Test the split calculation with these totals and split amounts. Expected values are in cents.

| Order total | First card | Second card | Note |
| --- | --- | --- | --- |
| 100 | 50 | 50 | Even split |
| 101 | 51 | 50 | Remainder cent goes to first card |
| 1 | rejected | rejected | Cannot split 1 cent into 2 charges |
| 2 | 1 | 1 | Smallest valid split |
| 99999 | 1 | 99998 | Minimum on first card |
| 99999 | 99998 | 1 | Minimum on second card |
| 1000000 | 333333 | 666667 | Large amount, uneven thirds |

Also test:

- Amounts entered with a decimal point in the customer's locale convert to the correct cents. Try 10.005, 10.5, 10,50 and 10.
- First plus second equals the order total in every case. Add an assertion to the end-to-end suite.
- Tax or shipping changes after the split is chosen recalculate the second card, not the first.

### Risk 4: Duplicate charges

Test type: stub-based, then confirmed on the sandbox.

- Submit the checkout form twice within 1 second. Expect 2 charges in total, not 4.
- PayGate times out on the first charge, then the customer retries. Expect no duplicate first charge. Check the idempotency key is reused.
- PayGate times out on the second charge after actually approving it. Expect the system to query the charge status before retrying or refunding.
- Browser back button after the first charge succeeds, then resubmit.

### Risk 5: Order state after partial failure

Test type: stub-based state checks.

For each failure point, check the order status, the charges recorded, and what the customer sees.

| Failure point | Expected order status | Expected charges | Customer sees |
| --- | --- | --- | --- |
| First charge declined | Failed | None | Error, can retry |
| Second charge declined, refund succeeds | Failed | First charge refunded | Error, can retry |
| Second charge declined, refund fails | Needs manual refund | First charge kept, flagged | Error, support contact |
| Application crashes between the 2 charges | Needs manual refund | First charge kept, flagged | Error |
| Both succeed | Paid | 2 charges | Confirmation with both amounts |

The crash case assumes a recovery job runs on restart. If none exists, record it as a known gap.

### Risk 6: Split amount validation

Test type: manual in the browser, plus direct API calls to bypass the browser checks.

- Zero, negative, equal to the total, over the total, non-numeric, empty, very long input, and more than 2 decimal places.
- Each invalid value is rejected on the server, not only in the browser. Send each one directly to the API.
- The error message tells the customer the valid range.

### Risk 7: PayGate errors other than decline

Test type: stub-based.

- Network error, HTTP 500, HTTP 429, malformed response body, and a response that takes 30 seconds.
- Each one on the first charge, the second charge, and the refund call.
- No PayGate error is shown raw to the customer.

### Risk 8: Silent refund failure

Test type: stub-based.

- Force the refund to fail. Confirm the alert reaches the support channel within 5 minutes and includes the order number and amount.
- Confirm the order appears in whatever list support uses to find orders needing manual refunds.

### Risk 9: Receipts and order history

Test type: manual on the sandbox.

- Receipt email shows both cards, last 4 digits of each, and the amount per card.
- Order history in the customer's account shows the same.
- A refunded first charge shows as refunded, not as paid.

## 5. Schedule

The tester works half days. Sandbox days are reserved for PayGate integration tests. Other days use the stub.

| Day | Date | PayGate sandbox | Tester | Developers |
| --- | --- | --- | --- | --- |
| 1 | Mon 26 Oct | No | Review this plan with developers. Write test data for Risk 3. | Build PayGate stub. Start feature. |
| 2 | Tue 27 Oct | Yes | Confirm sandbox access and decline codes. Baseline single-card timing. | Feature work. |
| 3 | Wed 28 Oct | No | Review unit tests for Risk 3. Prepare API calls for Risk 6. | Unit tests for split calculation. |
| 4 | Thu 29 Oct | Yes | First split payment end to end on sandbox, happy path only. | Fix issues found. |
| 5 | Fri 30 Oct | No | Risks 5, 6 and 7 on the stub. | Feature complete for refund path. |
| 6 | Mon 2 Nov | No | Risk 4 on the stub. Risk 8. | Fix issues. |
| 7 | Tue 3 Nov | Yes | Risk 1 on the sandbox, all decline reasons, 10 timed runs. Risk 2 smoke. | Fix issues. |
| 8 | Wed 4 Nov | No | Retest fixes on the stub. Risk 9 on captured receipts. | Fix issues. Code freeze end of day. |
| 9 | Thu 5 Nov | Yes | Final sandbox run of Risks 1, 2 and 9. Regression suite. | Fix only blockers. |
| 10 | Fri 6 Nov | No | Go or no-go review. Release. | Release. Monitor. |

The feature must be testable on the sandbox by day 4. If it is not, day 7 becomes the first full sandbox run, and the final sandbox run on day 9 has no room for retests. In that case, recommend slipping the release to Tuesday 10 November, the next sandbox day plus 1.

## 6. Roles

- Tester: owns this plan, runs sandbox and stub tests for Risks 1, 2, 4 to 9, and reports status daily.
- Developer 1: writes and runs unit tests for Risk 3. Builds the PayGate stub by day 1.
- Developer 2: owns the regression suite run on each build and the timing comparison for Risk 2.
- Both developers: fix issues the same day they are reported from day 7 onward.

## 7. Entry criteria

Testing on the sandbox starts when:

- The PayGate stub is available and the feature works end to end against it.
- Unit tests for the split calculation pass.
- The existing single-card regression suite passes on the feature branch.

## 8. Exit criteria

Release is approved when all of the following are true:

- Risk 1: refund completed under 60 seconds in all 10 timed sandbox runs. No open issues.
- Risk 2: regression suite passes. Median checkout time within 10 percent of baseline. No open issues.
- Risk 3: all cases in the table pass. No open issues.
- Risks 4 and 5: no open issues of high severity.
- Risks 6 to 9: no open issues of critical or high severity. Medium issues are listed in the release notes with a fix date.
- A manual refund procedure is written and agreed with support before release.

## 9. Release day monitoring

For the first 3 days after release, check daily:

- Count of split orders where the second charge was declined, and the refund time for each. Any refund over 60 seconds is a critical issue.
- Count of orders flagged for manual refund. Any count above 0 needs a same-day review.
- Single-card order volume and error rate compared with the same weekday 1 week earlier.
- Sum of charges per order compared with the order total, for all split orders.

## 10. Known gaps

- Only 4 sandbox days are available. Stub tests cannot prove PayGate's real decline and refund behaviour.
- With the tester at half time, Risk 9 and parts of Risk 7 may be cut if days 7 and 9 are spent on retests.
- No load test of split payment itself. It is assumed to be a small share of orders at launch.
- The crash-recovery case in Risk 5 depends on a recovery job that may not exist.
