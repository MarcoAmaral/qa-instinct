# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** paying one order with two cards, amount split chosen by the customer, cent-level rounding, two PayGate charges, automatic refund of the first charge when the second is declined, and non-regression of single-card checkout.

**Assumptions made where the brief is silent:**

- Today is Saturday 24 Oct 2026. Working days run Mon 26 Oct to Fri 6 Nov 2026. Release is Fri 6 Nov. Sandbox days are Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov.
- "Half time" means roughly 2.5 tester days per week, about 5 tester days in total.
- The customer enters the first-card amount in whole cents, and the system validates it against the order total before any charge is made.
- "Remainder cent goes on the first card" applies when a percentage or half split produces a fractional cent. It is not a rounding rule for arbitrary customer-entered amounts.
- Refund of the first charge is a PayGate refund API call, not a void. The 60-second target is measured from the second decline response to the refund request being accepted by PayGate.
- A PayGate mock or stub can be built by the developers and used on non-sandbox days. If this is not possible, the schedule in section 6 slips by at least two days.
- Partial refunds, more than two cards, saved-card wallets, and currency conversion are out of scope.
- Single-card checkout has an existing automated regression suite. If it does not, building a minimal one becomes the first task of the plan.

## 2. Risk analysis

Risks are ranked by likelihood times impact. Test effort follows this order.

| # | Risk | Likelihood | Impact | Priority |
|---|------|-----------|--------|----------|
| R1 | Second charge declines and the first charge is not refunded, is refunded twice, or is refunded late. Customer loses money. | High | Critical | 1 |
| R2 | Split-payment change breaks single-card checkout, affecting ~4,000 orders a day. | Medium | Critical | 2 |
| R3 | Cent rounding is wrong, so the two charges do not sum to the order total. | Medium | High | 3 |
| R4 | Double charging: retry, refresh, or back button submits a charge twice. | Medium | Critical | 4 |
| R5 | Partial failure leaves the order in an inconsistent state, for example paid-in-full with only one successful charge. | Medium | High | 5 |
| R6 | Invalid split amounts are accepted: zero, negative, more than total, non-integer cents. | Medium | Medium | 6 |
| R7 | First charge declines and the second card is still charged. | Low | Critical | 7 |
| R8 | PayGate timeouts or ambiguous responses during either charge or the refund. | Medium | High | 8 |
| R9 | Sandbox available only two days a week, so integration defects are found late. | High | High | Schedule risk |
| R10 | Reporting, receipts, and reconciliation show one charge instead of two, or wrong amounts. | Medium | Medium | 9 |

## 3. Test approach by risk level

**Critical (R1, R2, R4, R7):** automated tests at unit and service level against a PayGate mock, plus manual end-to-end verification on every sandbox day. Every build must pass these before any other testing.

**High (R3, R5, R8):** developer-written unit tests for rounding and state transitions, reviewed by the tester. Fault injection with the mock for timeouts and ambiguous responses.

**Medium (R6, R10):** manual exploratory testing with a checklist, run once on a stable build.

**Regression (R2):** the existing single-card suite runs on every build. One manual smoke of single-card checkout on each sandbox day against real PayGate.

## 4. Test conditions

### 4.1 Refund on second-card decline (R1)

- Second card declined with a hard decline code. First charge refunded, refund accepted by PayGate within 60 seconds, order marked unpaid, customer notified.
- Second card declined with a soft decline code. Same outcome, no automatic retry of the second charge.
- Refund call to PayGate fails once. System retries and still meets 60 seconds, or raises an alert and queues the refund.
- Refund call to PayGate fails repeatedly. Refund is queued, an operator alert fires, and no second refund is issued when the queue later succeeds.
- Timing is measured with timestamps logged at decline response and refund acceptance, across at least 20 runs on the mock and 5 on the sandbox.
- Refund amount equals the first charge amount exactly, including when it carried the remainder cent.

### 4.2 Single-card non-regression (R2)

- Full existing automated regression suite on every build.
- Manual smoke on sandbox days: successful card, declined card, 3-D Secure if used, receipt email, order status.
- Confirm that the single-card path does not call any new split-payment code when only one card is given.
- Confirm no change to the single-card database schema, or that migrations are backward compatible.

### 4.3 Rounding and amounts (R3, R6)

Boundary values, all in cents, using an order total T:

- T = 1, T = 2, T = 3, odd T, even T, T = 99,999,999.
- First-card amount = 0, 1, T minus 1, T, T plus 1, negative, non-numeric, fractional cent.
- Even split of odd T: first card gets the extra cent, second gets the rest, sum equals T.
- Percentage split that yields a fractional cent, for example 33.33% of 100 cents: first card 34, second 66.
- Assert in every case that charge1 plus charge2 equals T before any gateway call is made.

### 4.4 Idempotency and double submission (R4)

- Submit the payment form twice quickly. Only one pair of charges is created.
- Refresh or use the browser back button after the first charge succeeds. No second first-charge.
- Each PayGate call carries a unique idempotency key per order and per card position.
- Replay the same request to the backend. Gateway is not called again.

### 4.5 Order state and partial failure (R5, R7)

- First card declined. Second card is never charged. Order remains unpaid.
- First card succeeds, process crashes before the second charge. On recovery, the system either completes the second charge or refunds the first, never neither.
- Both succeed. Order paid, two payment records, receipt shows both cards and amounts.
- Same card number entered for both. Assumed allowed. Two separate charges are created.

### 4.6 Gateway faults (R8)

Using the mock: timeout on first charge, timeout on second charge, timeout on refund, HTTP 500, malformed response, slow response at 59 and 61 seconds. In every case the order ends in a known state and no money is lost or taken twice.

### 4.7 Reporting and reconciliation (R10)

- Order detail, admin payment list, and daily settlement export show two charges with correct amounts and the refund where applicable.
- Reconciliation totals for a test day match PayGate sandbox totals.

## 5. Automation and tooling

- Developers build a PayGate mock on day 1 that supports: success, hard decline, soft decline, timeout, HTTP 500, and configurable latency. This is the single most important enabler because of R9.
- Rounding, validation, and state-machine tests live in the unit suite and run in CI.
- Refund-timing test runs against the mock in CI with a 60-second assertion.
- Sandbox runs are manual, scripted in a checklist, with evidence captured as PayGate transaction IDs.

## 6. Schedule

| Day | Date | Activity | Who |
|-----|------|----------|-----|
| 1 | Mon 26 Oct | Review design, agree state machine and idempotency approach, start mock. | Tester, Dev A, Dev B |
| 2 | Tue 27 Oct | **Sandbox.** Confirm sandbox credentials, decline codes, refund API behaviour, and timing baseline. Single-card smoke. | Tester, Dev A |
| 3 | Wed 28 Oct | Unit tests for rounding and validation written and reviewed. | Devs write, tester reviews |
| 4 | Thu 29 Oct | **Sandbox.** First end-to-end run of happy path and second-card decline on whatever is built. Single-card smoke. | Tester |
| 5 | Fri 30 Oct | Fault injection on the mock: timeouts, 500s, crash between charges. | Tester |
| 6 | Mon 2 Nov | Double-submission and idempotency testing. Fix turnaround. | Tester, Dev B |
| 7 | Tue 3 Nov | **Sandbox.** Full critical-risk pass: R1, R2, R4, R7 with real PayGate. Refund timing measured. | Tester, Dev A |
| 8 | Wed 4 Nov | Reporting and reconciliation checks. Exploratory session on validation. Full regression suite. | Tester |
| 9 | Thu 5 Nov | **Sandbox.** Final verification of all fixes. Single-card smoke. Go/no-go evidence collected. | Tester, both devs |
| 10 | Fri 6 Nov | Release. Post-release monitoring of refund latency and single-card error rate. | Devs |

Code freeze for new functionality is end of day 6. Days 7 to 9 are fixes and verification only.

## 7. Entry and exit criteria

**Entry to sandbox testing:** build deployed to a test environment, mock-based critical tests passing, PayGate sandbox credentials confirmed.

**Exit for release:**

- All critical-risk conditions in sections 4.1, 4.2, 4.4, and 4.5 pass on the Thu 5 Nov sandbox run.
- Refund accepted within 60 seconds in every measured sandbox run.
- Existing single-card regression suite passes with no new failures.
- No open defects of severity critical or high. Medium defects may ship with a documented workaround.
- Alerting exists for failed or queued refunds and is verified to fire.

## 8. Roles

- **Tester:** owns this plan, the sandbox checklists, fault injection, exploratory testing, and the go/no-go evidence.
- **Developer A:** PayGate mock, integration code, pairs with the tester on sandbox days.
- **Developer B:** unit tests for rounding, validation, state machine, and idempotency. Fix turnaround on non-sandbox days.

## 9. Residual risks and mitigations

- **Only four sandbox days.** Any sandbox defect found on Thu 5 Nov cannot be re-verified against real PayGate before release. Mitigation: feature flag so split payment can be disabled in production without a deploy, and the Tue 3 Nov run is treated as the real acceptance run.
- **Tester capacity is about 5 days.** Reporting and reconciliation testing is the first thing cut if critical-risk testing slips.
- **Mock fidelity.** The mock may not match PayGate decline codes or refund latency. Mitigation: Tue 27 Oct is used to capture real responses and encode them in the mock.
- **Production load.** No performance test is planned. Split payment is expected to be a small share of the 4,000 daily orders. Mitigation: release behind the feature flag to a small percentage of customers first, and watch refund latency and single-card error rate for 24 hours before full rollout.
- **Recommended release-day monitoring:** refund queue depth, time from decline to refund acceptance, single-card success rate compared with the prior week, and count of orders with exactly one successful charge and no refund.
