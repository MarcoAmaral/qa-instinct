# Test plan: Split payment, release 5.3

This plan tests the split payment feature so that release 5.3 can ship on Friday 6 November 2026 without breaking single-card checkout. It puts the most effort on the 2 things that can cost customers money: wrong amounts and a missing refund.

## Scope and assumptions

**In scope.** Choosing a split at checkout, the cent arithmetic, both PayGate charges, the automatic refund when the second charge is declined, order records and receipts for split orders, and regression of single-card checkout.

**Out of scope.** Refunds of a split order after it completes, more than 2 cards, PayGate's own uptime, and checkout performance tuning. Any of these found broken is logged, not fixed in 5.3.

**Assumptions.** Each one is stated so the team can correct it on day 1.

- Today is Saturday 24 October 2026. The 10 working days run from Monday 26 October to Friday 6 November. PayGate's sandbox is open on 27 and 29 October and 3 and 5 November. That is 4 sandbox days.
- The checkout offers a **Split evenly** option as well as a field for the first card's amount. The remainder cent rule only matters for **Split evenly**, because a typed amount already defines both halves.
- All supported currencies have 100 minor units. Currencies without cents, such as JPY, are not sold in 5.3.
- PayGate rejects charges under 50 cents. The checkout must therefore reject any split that leaves either card under 50 cents.
- The feature ships behind a feature flag that can be turned off in production without a deploy.
- The developers can build a PayGate stub that returns scripted responses, including declines, timeouts and refund failures. Without it, 6 of the 10 days have no gateway to test against.
- The tester has about 4 hours a day, which is 40 hours in total. Developers own unit tests and the stub, and each gives about 2 hours a day to testing in the second week.
- The 60-second refund limit is measured from PayGate's decline response to PayGate's refund confirmation.

## Risks and how we test them

Risks are ranked by likelihood and by what the customer loses. Priority 1 items are tested first and block release if they fail.

| # | Risk | Likelihood | Impact | Priority |
|---|------|-----------|--------|----------|
| 1 | Second card declined and the first charge is not refunded, or is refunded late | Medium | Customer loses money | 1 |
| 2 | Cent arithmetic wrong, so the 2 charges do not add up to the order total | Medium | Over- or under-charge on every odd order | 1 |
| 3 | Single-card checkout broken by the change, at about 4,000 orders a day | Low | Revenue stops | 1 |
| 4 | Second charge times out, so the order is in an unknown state | Medium | Duplicate charge or lost order | 2 |
| 5 | Refund call itself fails or PayGate is down after the first charge | Low | Customer loses money, no one is told | 2 |
| 6 | Customer submits twice, or closes the browser between the 2 charges | Medium | Duplicate charges | 2 |
| 7 | Bad input accepted: 0, negative, more than the total, 3 decimals, under 50 cents | High | Failed charges, support tickets | 3 |
| 8 | Receipts, order history and emails show only 1 charge | High | Support tickets, chargebacks | 3 |
| 9 | Card data appears in logs or error messages | Low | Compliance breach | 3 |

**Risk 1, automatic refund.** Test on the stub first, then on the sandbox. On the sandbox, run the decline case at least 10 times in a row and record the time to refund confirmation for each run. All 10 must be under 60 seconds. Also test the decline arriving while PayGate is slow, so the refund starts late. Check that the customer sees one clear message and that the order is marked as not paid.

**Risk 2, cent arithmetic.** Developers write unit tests and the tester reviews the cases. Minimum cases, with amounts in cents:

- Total 10000 split evenly gives 5000 and 5000.
- Total 10001 split evenly gives 5001 on the first card and 5000 on the second.
- Total 1 cent and total 3 cents, split evenly, are rejected because one card falls under 50 cents.
- Typed first amount of 9999 on a total of 10000 leaves 1 cent and is rejected.
- Typed first amount equal to the total is rejected or falls back to single-card checkout. The team decides which on day 1.
- Amounts are stored and sent to PayGate as integers. No floating point anywhere on the path.
- Both charges plus any refund add up to the order total in the order record.

**Risk 3, single-card regression.** The existing automated checkout suite runs on every build. If no such suite exists, the tester writes a 10-case smoke script on day 1 and runs it on each sandbox day. The feature flag off state must behave exactly like release 5.2. One developer compares the single-card request sent to PayGate before and after the change, byte for byte.

**Risks 4 to 6, failure states.** Tested on the stub, because the sandbox cannot be made to time out on demand. Cases: second charge times out, second charge returns an unknown error, refund returns an error, PayGate unreachable after the first charge, the same request sent twice with the same idempotency key, and the browser closed after the first charge succeeds. For each case the expected result is one of: the order completes, or the first charge is refunded and the customer is told. Any case that leaves money taken and no order is a blocker. Each failed refund must raise an alert that someone will see.

**Risks 7 to 9, input, records and logging.** The tester covers these by hand in the first week on the stub. Input cases: 0, blank, negative, letters, 3 decimal places, exactly the total, more than the total, and the same card entered twice. Records: the order page, the confirmation email and the admin order view show 2 charges with the last 4 digits of each card. Logging: search application logs after a full test run for any full card number or CVV.

## Schedule, roles and release decision

| Day | Date | Gateway | Work |
|-----|------|---------|------|
| 1 | Mon 26 Oct | None | Confirm assumptions. Tester writes the test cases above. Developers build the PayGate stub and confirm sandbox credentials and decline test cards. |
| 2 | Tue 27 Oct | Sandbox | Run single-card smoke on the sandbox to set a baseline. Prove the decline test cards and refund call work on their own. |
| 3 | Wed 28 Oct | Stub | Review cent arithmetic unit tests. Test input validation and **Split evenly** on the stub. |
| 4 | Thu 29 Oct | Sandbox | First end-to-end split order and first decline-and-refund run, if the build is ready. Otherwise single-card regression. |
| 5 | Fri 30 Oct | Stub | Failure cases for risks 4 to 6. Log search for card data. |
| 6 | Mon 2 Nov | Stub | Retest fixes. Full single-card regression with the flag off and on. |
| 7 | Tue 3 Nov | Sandbox | Full split suite on the sandbox. 10 timed refund runs. Receipts and emails checked. |
| 8 | Wed 4 Nov | Stub | Fix and retest. Code freeze at end of day. |
| 9 | Thu 5 Nov | Sandbox | Release candidate run: full split suite, timed refunds, single-card smoke. Go or no-go meeting. |
| 10 | Fri 6 Nov | Production | Release with the flag off. Turn the flag on for staff accounts. Place 3 real split orders with small amounts, including 1 forced decline. Turn on for customers if all pass. |

**Roles.** The tester owns this plan, the manual cases, the sandbox runs and the timing log. Developer A owns the stub and the unit tests. Developer B owns the single-card regression and the production smoke. Both developers each take 1 risk from 4 to 6 to test by hand on day 5.

**Release goes ahead when** all priority 1 cases pass on the sandbox on 5 November, all 10 timed refunds are under 60 seconds, the single-card suite passes with the flag off and on, and no open bug leaves money charged without an order.

**Release is held when** the build is not on the sandbox by 3 November. That leaves 1 sandbox day, which is not enough to time refunds and retest a fix. The fallback is to ship 5.3 with the flag off and turn split payment on after the next sandbox day with a passing run.

**Risks to this plan.** The stub is the main dependency. If it is not ready by day 3, the first week loses most of its value and the plan slips to the hold condition. The 60-second limit is measured on the sandbox, which may be slower or faster than production. The 3 production orders on day 10 are the only real check, so they must include the forced decline.
