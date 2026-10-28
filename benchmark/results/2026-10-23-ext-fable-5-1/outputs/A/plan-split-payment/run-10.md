# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** paying one order with two cards, amount entry and validation, cent-level arithmetic, two PayGate charges, automatic refund of the first charge when the second is declined, and regression of the existing single-card checkout.

**Out of scope:** more than two cards, split across non-card methods, partial refunds initiated by support, and PayGate's own behaviour beyond its documented responses.

**Assumptions** (stated because the brief does not say):

- A1. The customer may either enter an explicit amount for card 1 or pick "split evenly". The remainder-cent rule applies only to the even split. An explicit amount is used as entered.
- A2. All orders are in a single currency with two decimal places.
- A3. Valid card 1 amounts are 1 cent to (order total minus 1 cent). Zero or full amount on card 1 is rejected, since that is a single-card order.
- A4. The 60-second refund window runs from the moment PayGate returns the decline to the moment PayGate acknowledges the refund request.
- A5. A PayGate stub (or recorded responses) can be run locally on non-sandbox days. If none exists, the developers build one on day 1. This is the single most important enabler for the plan.
- A6. Release date is Friday 6 November 2026. Sandbox days inside the window are Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov.
- A7. The tester has about 5 working days of effort in total. Developers own unit and contract tests and take the test cases marked "Dev" below.

## 2. Risk register

Risks are ranked by likelihood times impact. Test effort follows this order. If time runs out, the lowest rows are dropped first.

| # | Risk | Impact | Likelihood | Priority |
|---|------|--------|------------|----------|
| R1 | Second card declined, refund of first card never happens or happens late. Customer is charged with no order. | Critical: money taken, chargebacks, support load | Medium | P1 |
| R2 | Second charge neither succeeds nor is declined (timeout, 5xx, network drop). System does not know whether card 2 was charged. Risk of double charge or refund of a charge that should stand. | Critical | Medium | P1 |
| R3 | Cent arithmetic wrong: the two charges do not sum to the order total, or the remainder cent lands on card 2. | High: ledger mismatch, reconciliation failures | Medium | P1 |
| R4 | Single-card checkout regresses. Around 4,000 orders a day are exposed. | Critical at volume | Low to medium | P1 |
| R5 | Refund request itself fails (PayGate rejects it, or the job crashes). No alert, no retry, no manual queue. | High | Medium | P2 |
| R6 | Duplicate submission or retry creates a third charge or a second refund. Idempotency keys missing. | High | Medium | P2 |
| R7 | Invalid inputs accepted: zero, negative, more than total, non-cent values, same card entered twice. | Medium | High | P2 |
| R8 | Order, receipt, admin, and reporting show one transaction instead of two, or show a refunded order as paid. | Medium | Medium | P3 |
| R9 | Card 1 declined. Expected: stop immediately, charge nothing on card 2. | Medium | Low | P3 |
| R10 | Sandbox unavailable on a planned day, or sandbox behaviour differs from production. | Schedule risk | Medium | Mitigated by A5 and the schedule in section 5 |

## 3. Test approach by risk

**R1 Refund on decline (P1).**
Dev: unit tests on the decline handler and the refund job, including the 60-second timer. Tester: end-to-end on sandbox using PayGate's decline test cards for card 2. Measure time from decline to refund acknowledgement over at least 10 runs. Pass if every run is under 60 seconds and the order ends in a "not paid, refunded" state. Also test with the refund worker stopped and then restarted, to confirm the refund is persisted and not lost.

**R2 Ambiguous second charge (P1).**
Mostly on the stub, because the sandbox cannot produce timeouts on demand. Scenarios: timeout before response, 5xx, connection reset after PayGate has actually taken the charge. Expected behaviour must be defined by the developers before testing starts. Recommended: query PayGate for the charge status before deciding to refund, never refund blindly. This risk needs a design decision on day 1.

**R3 Cent arithmetic (P1).**
Dev: table-driven unit tests covering odd totals, 1 cent, 3 cents, large totals, and the even-split remainder rule. Tester: on sandbox, place even-split orders with odd totals and verify in PayGate's dashboard that card 1 carries the extra cent and the two charges sum to the total. Verify that explicit amounts are not rounded.

**R4 Single-card regression (P1).**
Run the existing single-card regression suite on every build. On each sandbox day, place at least five single-card orders end to end as a smoke check. Confirm the split-payment UI is hidden or inert when one card is entered. Before release, compare error rate and checkout latency on staging against the current baseline.

**R5 Refund failure (P2).**
Stub returns refund rejected or refund endpoint down. Expected: retry with backoff, an alert to the operations channel, and the order flagged for manual review. Confirm the alert actually fires.

**R6 Idempotency (P2).**
Double-click submit, browser back and resubmit, and a replayed API request. Expected: exactly two charges, at most one refund. Verify by charge count in the stub and in sandbox.

**R7 Input validation (P2).**
Boundary cases from A3, including 0, 1 cent, total minus 1 cent, total, total plus 1 cent, negative, three decimal places, blank, and the same card number on both inputs. Covered by developer unit tests plus a short manual pass on the UI.

**R8 Downstream display (P3).**
Check order detail, customer receipt email, admin panel, and the daily finance export for one successful split order and one refunded split order.

**R9 Card 1 declined (P3).**
One sandbox run with a decline card on card 1. Expected: no call to PayGate for card 2.

## 4. Environments and data

- **Local stub** for all non-sandbox days. Must support: success, decline, timeout, 5xx, refund success, refund failure. Must count calls so idempotency can be asserted.
- **PayGate sandbox** on the four Tuesday and Thursday slots for anything that depends on real gateway behaviour: R1 timing, R3 verification in the PayGate dashboard, R9, and smoke tests for R4.
- **Staging** with the release build for the final regression and the sandbox sessions.
- **Test data:** PayGate's published test card numbers for success and decline, plus a set of orders with odd and even totals, a 1-cent order, and a high-value order.

## 5. Schedule

Tester effort is half days unless stated.

| Date | Day | Activity |
|------|-----|----------|
| Mon 26 Oct | 1 | Agree expected behaviour for R2 and R5 with developers. Confirm the stub exists or is being built. Write the R3 and R7 unit test table with developers. |
| Tue 27 Oct | 2 | **Sandbox.** Confirm access, test cards, and dashboard. Smoke-test single-card checkout. Record a baseline charge and refund to learn real latency. |
| Wed 28 Oct | 3 | Stub-based testing: R6, R7, early R2 as code lands. |
| Thu 29 Oct | 4 | **Sandbox.** First end-to-end split orders. R3 verification. First R1 timing runs if the refund path is ready. |
| Fri 30 Oct | 5 | Stub: R2 and R5 in full. Review developer unit test results. |
| Mon 2 Nov | 6 | Stub: regression on single-card flow against the integrated build. R8 checks. |
| Tue 3 Nov | 7 | **Sandbox.** Full R1 timing set (10+ runs). R9. Single-card smoke. |
| Wed 4 Nov | 8 | Retest fixes on stub. Buffer. |
| Thu 5 Nov | 9 | **Sandbox.** Final end-to-end pass on the release candidate. All P1 scenarios rerun. Go/no-go evidence collected. |
| Fri 6 Nov | 10 | Release. Monitor refund job, charge-count metrics, and single-card error rate for the first hours. |

Anything found on Thu 5 Nov that touches a P1 risk cannot be retested on sandbox before release. The fallback is to retest on the stub and, if the fix touches gateway interaction, delay release to the following Tuesday.

## 6. Entry and exit criteria

**Entry:** stub available, R2 and R5 behaviour agreed and written down, feature deployable to staging by Wed 28 Oct.

**Exit (release go):**

- All P1 scenarios pass on sandbox on the release candidate build.
- Refund time under 60 seconds in every measured run.
- No open P1 or P2 defects. Open P3 defects have an owner and a date.
- Single-card regression suite green, and staging error rate within the current baseline.
- Alerting for failed refunds verified to fire.

**Release monitoring:** a dashboard or query that shows, per hour, split orders attempted, second-charge declines, refunds issued, and refunds older than 60 seconds still pending. Any non-zero count in the last column is treated as an incident.

## 7. Known gaps

- Timeout and partial-failure behaviour (R2) is tested only against the stub. Real PayGate behaviour under network failure is not observed before release.
- Four sandbox sessions of half a day each leave no slack. One lost session removes the final rerun of P1 scenarios on the release candidate.
- Load behaviour of the refund worker at production volume is not tested. Assumed low risk because split orders are expected to be a small fraction of the 4,000 daily orders.
