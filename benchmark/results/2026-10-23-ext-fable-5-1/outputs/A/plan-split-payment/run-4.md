# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** paying one order with two cards, amount entry and split calculation, two PayGate charges, automatic refund of the first charge when the second is declined, and protection of the existing single-card checkout.

**Out of scope:** more than two cards, split across non-card methods, PayGate's own internals, and changes to refunds initiated by support staff.

**Assumptions, applied where the brief is silent:**

- Today is Saturday 24 October 2026. Working days run Monday 26 October to Friday 6 November. Release is Friday 6 November.
- PayGate sandbox windows are Tuesday 27 October, Thursday 29 October, Tuesday 3 November and Thursday 5 November. That is four windows in total.
- The tester has about 4 hours per working day, roughly 40 hours in total.
- Charges are authorised and captured in one step, so "refund" means a PayGate refund call, not a void.
- Orders are in a single currency with two decimal places. Zero-decimal currencies are not supported in 5.3.
- "Split evenly" refers to a default 50/50 suggestion shown in the checkout. The customer can overwrite the first-card amount.
- The refund runs from an asynchronous job with retries, and the 60-second limit is measured from the decline response to the refund being accepted by PayGate.
- The feature ships behind a feature flag that can be switched off without a deploy.
- The existing single-card checkout has an automated regression suite that can run against a PayGate stub.
- The developers will build and maintain a local PayGate stub. Without it, testing is limited to two days a week and this plan does not fit the schedule.

## 2. Risk analysis

Likelihood and impact are rated High, Medium or Low. Priority drives how much test effort each risk gets.

| ID | Risk | Likelihood | Impact | Priority |
|----|------|-----------|--------|----------|
| R1 | Second card declined but first charge not refunded, or refunded late. Customer pays with no order. | High | High | 1 |
| R2 | Single-card checkout regresses. About 4,000 orders a day are affected. | Medium | High | 1 |
| R3 | Second charge times out or returns an unknown state. System cannot tell whether to refund. | High | High | 1 |
| R4 | Split arithmetic wrong. Total charged differs from order total by a cent or more. | Medium | High | 2 |
| R5 | Refund succeeds but the order is still created, or refund fails and the order is cancelled silently. Order and payment records disagree. | Medium | High | 2 |
| R6 | Double submission or retry charges a card twice. | Medium | High | 2 |
| R7 | Client-side amount tampering lets a customer underpay. | Low | High | 2 |
| R8 | Amount validation gaps: zero, negative, more than total, exactly total, non-numeric, sub-cent values. | High | Medium | 3 |
| R9 | Same card entered twice, or first card declined before the second is attempted. | Medium | Medium | 3 |
| R10 | PayGate behaves differently from the stub, so defects appear only on sandbox days. | High | Medium | 3 |
| R11 | Reconciliation, receipts and reports show one charge instead of two, or wrong amounts. | Medium | Medium | 3 |
| R12 | Refund job fails under load or when PayGate is slow, missing the 60-second limit. | Medium | Medium | 3 |
| R13 | Usability: customer does not understand which card gets the remainder cent. | Medium | Low | 4 |

Priority 1 and 2 risks get scripted tests, run on both stub and sandbox, and must pass before release. Priority 3 risks get scripted tests on the stub and one sandbox pass. Priority 4 risks get exploratory coverage only if time remains.

## 3. Test approach by level

**Unit tests, owned by developers.** Split calculation is pure arithmetic and is fully covered here, covering R4 and R8. Cases:

- Total 1 cent: first card 1, second card 0 or rejected, depending on design. Flag the decision.
- Total 999 cents, even split: first card 500, second card 499.
- Total 1000 cents, even split: 500 and 500.
- Customer-chosen first amount of 1 cent and of total minus 1 cent.
- First amount equal to total: treated as single-card or rejected. Flag the decision.
- First amount of zero, negative, greater than total, with fractional cents, and non-numeric input.
- Largest supported order value to check for integer overflow.
- Sum of both charges always equals the order total for a randomised set of totals and splits.

**Integration tests against the PayGate stub, owned by developers with tester review.** The stub replays fixtures captured from the sandbox on the first sandbox day. Cases cover R1, R3, R5, R6, R12:

- Both charges approved.
- First approved, second declined, refund approved within 60 seconds.
- First approved, second declined, refund declined by PayGate. Expected: alert raised, order held, no silent failure.
- First approved, second times out. Expected: status query or idempotent retry, then either completion or refund. No double charge.
- First declined. Expected: second card never attempted, no refund needed.
- Refund call times out, then succeeds on retry. Refund must still land within 60 seconds.
- Duplicate submission with the same idempotency key. Expected: one set of charges.
- Stub returns slow responses of 30 seconds or more to check the refund budget.

**End-to-end tests on the PayGate sandbox, owned by the tester.** Run on each of the four sandbox days. Cases cover R1, R3, R9, R10, R11:

- Happy path with two real sandbox cards, then check order record, receipt and both transactions in PayGate.
- Second card decline using PayGate's decline test card. Measure time from decline to refund acceptance with timestamps from logs and the PayGate dashboard.
- Second card with insufficient-funds, expired and fraud-flagged test cards, if PayGate provides them.
- Same card number on both slots.
- Receipt and order history show two charges and a refund where one happened.

**Regression, owned by the tester with developer help on automation.** Covers R2:

- Full automated single-card suite against the stub on every build.
- Manual single-card sandbox smoke on each sandbox day: approve, decline, refund by support.
- Confirm the feature flag off path is byte-for-byte the old checkout flow.

**Security and tampering, owned by the tester.** Covers R7:

- Modify the first-card amount in the request after the page renders. Server must recompute from the order total and reject mismatches.
- Replay a completed request with a different order ID.

**Exploratory sessions.** Two sessions of one hour each, covering R8, R9 and R13: browser back button mid-payment, refreshing between charges, switching cards after entering an amount, and checkout on a small screen.

## 4. Schedule

| Day | Date | Sandbox | Tester activity | Developer activity |
|-----|------|---------|-----------------|--------------------|
| 1 | Mon 26 Oct | No | Confirm assumptions, review design, agree on undefined cases from the unit list | Unit tests for split arithmetic, start stub scaffold |
| 2 | Tue 27 Oct | Yes | Explore PayGate: decline cards, refund API, timeout behaviour. Capture fixtures for the stub | Pair on fixture capture, implement charge flow |
| 3 | Wed 28 Oct | No | Review stub fixtures, write integration cases | Finish stub, implement refund job |
| 4 | Thu 29 Oct | Yes | First end-to-end run: happy path and second-card decline with refund timing | Fix findings |
| 5 | Fri 30 Oct | No | Single-card regression run, tampering tests | Fix findings, add idempotency |
| 6 | Mon 2 Nov | No | Failure modes on stub: timeouts, refund decline, slow PayGate | Fix findings |
| 7 | Tue 3 Nov | Yes | Full scripted sandbox pass, retest fixed defects, refund timing | Fix findings |
| 8 | Wed 4 Nov | No | Regression rerun, exploratory sessions, code freeze at end of day | Final fixes only |
| 9 | Thu 5 Nov | Yes | Release candidate run on sandbox, go/no-go report | Standby |
| 10 | Fri 6 Nov | No | Release with flag off. Enable for internal users. Production smoke with two low-value real cards and one forced decline | Monitor refund job and error rates |

If a sandbox day is lost, the next sandbox day absorbs its cases and the exploratory sessions are dropped.

## 5. Entry and exit criteria

**Entry to sandbox testing:** stub exists, unit tests pass, build deployed to a test environment with PayGate sandbox credentials and log access.

**Exit for release:**

- All priority 1 and 2 cases pass on the sandbox on Thursday 5 November.
- No open defect in R1, R2, R3 or R4.
- Refund observed within 60 seconds in every sandbox decline test, with the slowest time recorded.
- Single-card regression suite green on the release candidate build.
- Refund job has an alert for any refund not accepted within 60 seconds, verified by triggering it on the stub.
- Feature flag off path confirmed identical to the current checkout.

## 6. Residual risks and mitigations

- **Only four sandbox windows.** Anything PayGate does that the stub does not model will be found late. Mitigation: day 2 is spent entirely on capturing real behaviour, and the stub is built from those fixtures rather than from documentation.
- **Half-time tester.** Scripted coverage is prioritised over exploratory work. Developers own all unit and most integration tests.
- **No load test.** The 4,000 orders a day are protected by regression and the feature flag, not by load testing. Mitigation: enable the feature gradually in production and watch single-card error rates and latency for the first day.
- **Production behaviour of refunds.** Sandbox refund timing may not match production. Mitigation: the production smoke on release day includes one forced decline and a timed refund before the flag is opened to customers.
- **Undefined cases.** The brief does not define a 1-cent order, a first amount equal to the total, or the same card used twice. These are raised on day 1 and the chosen behaviour is tested, whichever it is.
