# Test plan: Split payment (release 5.3)

This plan tests the split-payment feature by risk. The biggest risks get the most time and the earliest slots.

## Assumptions

- Today is Saturday 24 October 2026. Working day 1 is Monday 26 October. Release is Friday 6 November.
- PayGate sandbox days before release: 27 and 29 October, 3 and 5 November. That is 4 sandbox days.
- The tester has about 5 working days in total. The 2 developers test their own code and pair with the tester on sandbox days.
- Refund failures reach an operations queue or alert. If no such queue exists, the developers add a log entry and an alert before testing starts.
- Both cards are charged in sequence: card 1 first, then card 2.
- Minimum amount per card is 1 cent. The customer cannot put the full amount on 1 card in the split flow.
- A PayGate mock exists or can be built by a developer on day 1. Without it, 4 sandbox days are the only days with gateway coverage.
- Single-card checkout has an existing automated regression suite. If it does not, a smoke test of 10 orders replaces it.

## Risks, ranked

| Rank | Risk | Why it matters | Effort |
| --- | --- | --- | --- |
| 1 | Second charge declined, first charge not refunded or refunded late | Customer loses money and the brief sets a 60-second limit | High |
| 2 | Single-card checkout breaks | About 4,000 orders a day stop or double-charge | High |
| 3 | Amounts do not add up to the order total | Rounding, remainder cent, or overcharge on one card | Medium |
| 4 | Partial state after a timeout or crash between the 2 charges | Order paid once but marked unpaid, or paid twice | Medium |
| 5 | PayGate rejects or misreads a request | Only testable on sandbox days, so slips are costly | Medium |
| 6 | Refunds, cancellations and reports for split orders | 2 charges per order may confuse later flows | Low |

## Test approach by risk

### Risk 1: Refund after second card declined

- Test with a mock on non-sandbox days and with PayGate on sandbox days.
- Cases: card 2 declined, card 2 times out, card 2 errors, PayGate down during refund.
- Measure time from decline to refund confirmation. Pass only if under 60 seconds in 10 of 10 runs.
- Confirm the customer sees 1 clear message and the order is not marked paid.
- Confirm a failed refund raises an alert and does not retry forever.

### Risk 2: Single-card checkout regression

- Run the full single-card regression suite after every build that touches checkout.
- Add a 10-order smoke test with real test cards on each sandbox day.
- Check that a customer who does not choose split payment never sees split-payment fields.
- Check order records and receipts for single-card orders are unchanged.

### Risk 3: Amount splitting

- Unit tests by the developers, reviewed by the tester on day 1. Cases: even split, odd split, 1 cent, order total 1 cent, amount on card 1 equal to total minus 1 cent, amount on card 1 of 0 or more than the total.
- Check that card 1 plus card 2 equals the total in cents in every case.
- Check that the remainder cent goes on card 1 for 3 odd totals.
- Check the order total is never rounded as a decimal before splitting.

### Risk 4: Partial state

- Kill the service after charge 1 succeeds and before charge 2 starts. Check the order state and the refund of charge 1.
- Submit the same split payment twice. Check only 1 pair of charges happens.
- Check that a browser refresh between charges does not charge twice.

### Risk 5: PayGate contract

- On the first sandbox day, run 1 happy path, 1 decline on card 1, 1 decline on card 2, 1 refund. Fix contract errors before the second sandbox day.
- Record every PayGate request and response so failures can be reproduced on a non-sandbox day.

### Risk 6: Downstream flows

- Refund a completed split order. Both cards get their own share back.
- Check that reports and the order page show 2 charges.
- Skip if time runs short. Note the gap in the release notes.

## Schedule

| Day | Date | Work |
| --- | --- | --- |
| 1 | Mon 26 Oct | Review unit tests for splitting. Build or confirm the PayGate mock. Write the sandbox checklist. |
| 2 | Tue 27 Oct | Sandbox: contract tests from risk 5. First refund-timing runs. |
| 3 | Wed 28 Oct | Fix findings. Partial-state tests on the mock. |
| 4 | Thu 29 Oct | Sandbox: refund timing, 10 runs. Single-card smoke test. |
| 5 | Fri 30 Oct | Single-card regression suite. Report status. |
| 6 | Mon 2 Nov | Fix findings. Retest on the mock. |
| 7 | Tue 3 Nov | Sandbox: retest fixes. Downstream flows if time allows. |
| 8 | Wed 4 Nov | Regression suite on the release candidate. |
| 9 | Thu 5 Nov | Sandbox: final smoke of split and single-card flows. Go or no-go. |
| 10 | Fri 6 Nov | Release. Monitor refund alerts and single-card order volume for 24 hours. |

The tester works half time, so each day above is about half a day of tester effort. Developers cover the rest of each sandbox day.

## Entry criteria

- The feature is deployed to a test environment by the end of day 1.
- The PayGate mock responds to charge, decline, timeout and refund.
- Sandbox test cards for success and decline are available before 27 October.

## Exit criteria

- All risk 1 and risk 2 tests pass on the release candidate.
- Refund after decline completes in under 60 seconds in 10 of 10 sandbox runs.
- The single-card regression suite passes with no new failures.
- No open defect that charges a customer wrong or leaves an order in an unknown state.
- Risk 6 gaps, if any, are written in the release notes.

## Roles

- **Tester:** owns this plan, runs sandbox sessions, reports status at the end of each sandbox day.
- **Developers:** write unit tests for splitting, build the mock, fix findings within 1 working day, join sandbox sessions.
- **Release owner:** makes the go or no-go call on 5 November. Assumed to be the product owner.

## Out of scope

- Load testing of split payment. Volume is expected to be low at launch.
- More than 2 cards.
- Card types PayGate does not support in the sandbox.

## Known gaps

- Only 4 sandbox days exist. A fix that lands after 3 November gets 1 sandbox retest at most.
- Refund timing on the mock does not prove timing on PayGate. Only the sandbox runs count toward the exit criterion.
- If the sandbox is down on a scheduled day, the release slips 2 working days to the next sandbox day plus 1 day of retest.
