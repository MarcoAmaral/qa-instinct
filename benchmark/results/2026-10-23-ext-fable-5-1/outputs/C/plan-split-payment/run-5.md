# Test plan: Split payment (release 5.3)

**Summary.** This plan tests paying for one order with 2 cards, with the highest effort on the 2 things that can take a customer's money wrongly: the automatic refund after a declined second charge, and the cent arithmetic. Testing runs from Monday 2026-10-26 to Friday 2026-11-06. Real PayGate sandbox runs are limited to 4 days, so most testing happens against a PayGate stub and the sandbox days are used to confirm what the stub showed.

## Assumptions

- **Release date** is Friday 2026-11-06, which is 10 working days from today (2026-10-24).
- **Sandbox days** are Tuesday 2026-10-27, Thursday 2026-10-29, Tuesday 2026-11-03 and Thursday 2026-11-05.
- **Tester capacity** is about 4 hours a day, 40 hours in total.
- **The interface** has a **Split payment** option at checkout with an **Amount on first card** field and a **Split evenly** choice. The remainder-cent rule applies to **Split evenly**.
- **PayGate sandbox** provides test card numbers that force an approval, a decline and a timeout, and lets us see refunds. If it does not, the decline and timeout cases run on the stub only, and this is a release risk.
- **A PayGate stub** can be built by the developers in 1 day. It returns approve, decline, timeout and refund failure on demand.
- **The 60-second limit** is measured from the moment PayGate returns the decline to the moment PayGate accepts the refund request.
- **Split payment ships behind a feature flag** so it can be turned off without a new release. If there is no flag, adding one is the first developer task.
- **An automated single-card checkout suite exists.** If it does not, a manual smoke test of 10 single-card orders replaces it on each regression run.

## Risks, ranked

| # | Risk | Likelihood | Impact | Priority |
| --- | --- | --- | --- | --- |
| 1 | Second card declines and the first charge is not refunded, or is refunded late | Medium | Customer pays and gets nothing | P1 |
| 2 | The 2 charges do not add up to the order total (rounding, remainder cent) | Medium | Wrong amounts charged, accounting errors | P1 |
| 3 | Single-card checkout breaks (4,000 orders a day) | Low | Revenue loss on every order | P1 |
| 4 | Second charge times out with no answer: order left half paid | Medium | Money taken, order unclear | P1 |
| 5 | Refund sent twice on retry (no idempotency) | Medium | Customer refunded more than charged | P2 |
| 6 | Bad input accepted: 0, full total, more than total, negative, same card twice | High | Failed or odd charges | P2 |
| 7 | Double submission creates 3 or 4 charges | Low | Overcharge | P2 |
| 8 | Receipt, order history and refund records show the wrong amounts | Medium | Support load | P2 |
| 9 | Sandbox unavailable on a planned day, or test cards missing | Medium | Untested integration | P2 |
| 10 | Slower checkout because of 2 sequential PayGate calls | Low | Abandoned orders | P3 |

## Test approach

**Three layers, cheapest first.**

1. **Developer unit tests** cover the cent arithmetic (risk 2) and input validation (risk 6). The tester reviews the cases, not the code. These run on every build.
2. **Stub-based tests** cover every PayGate response path (risks 1, 4, 5, 7) on Monday, Wednesday and Friday. The stub lets us force a decline, a timeout and a refund failure at will.
3. **Sandbox tests** on the 4 Tuesday and Thursday slots confirm the real integration: happy path, decline and refund, timing, and single-card regression.

**Rule:** no P1 case counts as passed until it has passed on the real sandbox at least once. Stub results are evidence, not sign-off.

## Test cases by priority

### P1: refund after decline (risk 1)

1. First card approved, second declined. Refund of the first charge is requested within 60 seconds. Run 20 times on the sandbox, record each time.
2. Same as case 1, but the refund call itself fails once. The system retries and still finishes within 60 seconds, or raises an alert and a support task.
3. First card declined. The second card is never charged, nothing to refund.
4. Both cards declined. No charge and no refund.
5. Customer sees a clear message that the order failed and the first card will be refunded.

### P1: amounts (risk 2)

Totals to use, in cents: 1, 2, 3, 1001, 9999, 100000, 123457.

1. **Split evenly** on an odd total: first card gets the extra cent (1001 → 501 and 500).
2. **Split evenly** on an even total: equal halves.
3. Custom amount: first card plus second card equals the total in every case above.
4. Amount entered with decimals (10.005, 10.5, "10,50") is rejected or rounded in one documented way, never silently.
5. Order with tax, discount or shipping applied after the split is entered. The split still matches the final total.

### P1: single-card regression (risk 3)

1. Full automated checkout suite passes with the flag on and with the flag off.
2. 10 manual single-card orders on the sandbox on each sandbox day, including 1 decline.
3. Flag off hides **Split payment** entirely.

### P1: timeouts (risk 4)

1. Second charge times out. The system checks the charge status with PayGate before deciding to refund or complete.
2. First charge times out. The second card is not charged until the first is known.
3. The order is never shown as paid while either charge is unknown.

### P2

- **Idempotency:** replaying the refund request or the checkout submit creates no extra charge or refund.
- **Validation:** first-card amount of 0, the full total, more than the total, negative, blank. Same card number on both. Expired second card.
- **Double submission:** 2 rapid submits produce exactly 2 charges.
- **Records:** receipt email, order history and the admin order page show both charges, both last-4 digits and any refund.
- **Partial refund later:** a staff refund on a split order after release refunds the right card. If this is out of scope for 5.3, the admin page must say so.

### P3

- Checkout time for a split order compared with a single-card order on the sandbox, 10 runs each.
- Mobile layout of the **Split payment** controls.

## Schedule

| Day | Date | Sandbox | Tester (4 h) | Developers |
| --- | --- | --- | --- | --- |
| 1 | Mon 26 Oct | No | Review brief, write cases, agree stub behaviour and test data | Build stub, add feature flag |
| 2 | Tue 27 Oct | Yes | Confirm sandbox access and test cards, baseline 10 single-card orders | Deliver first build |
| 3 | Wed 28 Oct | No | Review unit tests for amounts and validation, run P1 amounts on stub | Fix findings |
| 4 | Thu 29 Oct | Yes | P1 refund and decline cases on sandbox, first timing measurements | On call for fixes |
| 5 | Fri 30 Oct | No | Timeout and idempotency cases on stub, log bugs | Fix P1 bugs |
| 6 | Mon 2 Nov | No | Retest fixes on stub, P2 validation and records | Fix P2 bugs |
| 7 | Tue 3 Nov | Yes | 20 timed refund runs, single-card regression, double submission | On call |
| 8 | Wed 4 Nov | No | Retest, P3 cases if time allows | Final fixes, code freeze end of day |
| 9 | Thu 5 Nov | Yes | Full P1 pass on sandbox, go or no-go report | Prepare release |
| 10 | Fri 6 Nov | No | Production smoke: 1 real split order, 1 real single-card order, monitor | Release, watch alerts |

If a sandbox day is lost, the next sandbox day takes its P1 cases and P2 and P3 work is dropped. If 2 sandbox days are lost, the feature ships with the flag off.

## Who does what

- **Tester** owns this plan, the stub and sandbox test runs, bug reports and the go or no-go report.
- **Developer 1** owns the stub, unit tests for amounts and the feature flag.
- **Developer 2** owns the refund and timeout handling, the retry logic and the alert for refunds older than 60 seconds.
- **Both developers** run the automated single-card suite before every build they hand over.

## Exit criteria

- All P1 cases pass on the real sandbox on Thursday 5 November.
- All 20 timed refund runs finish within 60 seconds. One failure blocks release.
- No open P1 or P2 bugs. Open P3 bugs are listed in the release notes.
- The single-card suite passes with the flag on and off.
- A production alert fires when any refund is outstanding for more than 60 seconds, and someone is named to answer it.
- The flag can be turned off in production and this has been tried once on staging.

## Out of scope

- More than 2 cards.
- Split between a card and a non-card method such as a gift card or store credit.
- Load testing of PayGate. The sandbox does not reflect production limits.
- Currency conversion. All orders are assumed to be in one currency.

## Known gaps

- Decline and timeout behaviour on the real sandbox depends on PayGate test cards. If they are missing, those cases are confirmed on the stub only and this is stated in the go or no-go report.
- 40 tester hours is not enough for the P3 cases. They run only if P1 and P2 finish early.
- The first week of production use should be watched daily for split orders with a refund older than 60 seconds and for any order whose charges do not add up to its total.
