# Test Plan: Split Payment (Release 5.3)

**Release target:** Friday 6 November 2026 (10 working days from Saturday 24 October 2026).
**PayGate sandbox days in the window:** Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. Four days total.
**Test effort available:** roughly 5 tester-days, plus developer time for unit tests, the gateway mock, and pairing on sandbox days.

## 1. Scope and assumptions

In scope: choosing a split at checkout, validation of the split, two PayGate charges, automatic refund of the first charge on second-charge decline, and regression of single-card checkout.

Out of scope for 5.3 unless the brief changes: more than two cards, splitting across non-card methods, customer-initiated refunds on split orders after fulfilment, and mobile native apps.

Assumptions made where the brief is silent:

- **A1.** Single currency with two decimal places. Amounts are integers in cents end to end.
- **A2.** The customer enters the first-card amount; the UI also offers a "split evenly" shortcut. The remainder-cent rule applies to that shortcut and to any percentage input.
- **A3.** Each card must carry at least 1 cent. A total of 1 cent cannot be split and is rejected.
- **A4.** Charges are authorise-and-capture in one call, made sequentially, first card then second. Refund of the first charge uses PayGate's refund or void endpoint.
- **A5.** The 60-second clock starts when the second-charge decline is received and stops when PayGate acknowledges the refund.
- **A6.** The feature ships behind a feature flag with a kill switch that reverts to single-card checkout.
- **A7.** Every PayGate call carries an idempotency key.
- **A8.** PayGate sandbox provides test card numbers that trigger specific outcomes such as decline, insufficient funds, timeout, and 3-D Secure challenge.
- **A9.** The same card number may be used for both halves. If product disagrees, one test case changes.

## 2. Risk analysis

Ranked by likelihood times impact. Priority drives test depth and ordering.

| # | Risk | Impact | Likelihood | Priority |
|---|------|--------|------------|----------|
| R1 | Second charge declined and first charge is not refunded, refunded late, or refunded twice | Customer charged with no order. Chargebacks, support load, trust | High: new async path, external dependency | P1 |
| R2 | Single-card checkout regresses | Affects about 4,000 orders a day; biggest blast radius | Medium: shared checkout code is being changed | P1 |
| R3 | Orphan first charge when the system fails between the two charges, or when PayGate times out with unknown outcome | Same as R1 but harder to detect | Medium | P1 |
| R4 | Duplicate charges from retries, double submit, or back-button resubmission | Customer overcharged | Medium | P1 |
| R5 | Split arithmetic wrong: rounding, remainder cent, float conversion, sum not equal to total | Under or over collection on every affected order; accounting mismatch | Medium | P1 |
| R6 | Validation gaps: zero, negative, over-total, non-numeric, more than two decimals, locale separators | Bad charges or server errors | High: many inputs | P2 |
| R7 | Ledger, order record, receipts, and reports show one transaction or the wrong amounts | Finance reconciliation fails | Medium | P2 |
| R8 | Checkout latency doubles because of two sequential gateway calls; timeouts cascade | Abandonment, more R3 cases | Medium | P2 |
| R9 | 3-D Secure or fraud screening on the second card interrupts the flow after the first charge succeeded | Stuck orders, orphan charges | Medium | P2 |
| R10 | Card data or full card numbers logged or exposed in new code paths | PCI breach | Low | P2 |
| R11 | Sandbox unavailable on a planned day, or sandbox behaviour differs from production | Untested paths at release | Medium | Process risk, see section 6 |

## 3. Test approach

Testing is layered so that only the real gateway integration depends on sandbox days.

- **Unit tests (developers, every day).** Split calculator and validation. Includes property-based tests asserting that first plus second always equals total and the remainder goes to the first card. Covers 1 cent, 2 cents, 3 cents, odd and even totals, maximum order value, and the largest safe integer boundary.
- **Component tests against a PayGate mock (developers and tester, every day).** A local stub that returns scripted outcomes: approved, declined with each known reason code, HTTP 5xx, connection timeout, slow response, duplicate idempotency key, and refund failure. This is where most failure-path testing lives. The mock is calibrated on the first sandbox day against real sandbox responses.
- **Sandbox integration (tester plus one developer, Tuesdays and Thursdays only).** Real end-to-end runs: happy paths, real decline cards, real refund, 60-second timing, 3-D Secure challenge. Each sandbox day has a fixed script so nothing is wasted.
- **Regression of single-card checkout (automated suite plus manual smoke).** Run the existing automated checkout suite on every build. Manual smoke on each sandbox day with the feature flag both on and off.
- **Exploratory testing (tester).** UI validation, error messaging, browser back and refresh behaviour, accessibility of the new form fields.
- **Non-functional (shared).** Latency measurement with the mock at realistic response times, refund timing, and concurrent-submission tests.
- **Production safeguards (developers, verified by tester).** Feature flag, percentage rollout, alert when a refund has not completed within 60 seconds, and a daily reconciliation report listing first charges with no matching second charge or refund.

## 4. Test cases

IDs map to the risks in section 2. Priority P1 cases are the exit gate.

**Split arithmetic and validation (R5, R6)**

| ID | Case | Expected | Pri |
|----|------|----------|-----|
| T01 | Even split of an odd total, for example 1001 cents | First 501, second 500 | P1 |
| T02 | Even split of an even total | Equal halves | P1 |
| T03 | Manual amount for first card, remainder computed | Second equals total minus first, sum equals total | P1 |
| T04 | Total of 1 cent | Split rejected with clear message | P1 |
| T05 | First card amount equal to total, zero, negative, or above total | Rejected | P1 |
| T06 | First card amount with three decimals, letters, comma separator, leading plus sign | Rejected or normalised consistently with the rest of checkout | P2 |
| T07 | Order total changes after split entered, for example coupon applied | Split re-validated, no stale amounts charged | P1 |
| T08 | Maximum supported order value | No overflow, sum correct | P2 |
| T09 | Property test: random totals and splits | Sum invariant holds, remainder always on first card | P1 |

**Gateway flows (R1, R3, R4, R9)**

| ID | Case | Expected | Pri |
|----|------|----------|-----|
| T10 | Both charges approved | Order placed, two transactions recorded with correct amounts | P1 |
| T11 | First charge declined | No second charge attempted, no refund, customer can retry | P1 |
| T12 | Second charge declined, each decline reason code | First charge refunded, order not placed, customer told which card failed | P1 |
| T13 | Refund completes within 60 seconds, measured on sandbox for every T12 variant | All under 60 seconds, timestamps recorded | P1 |
| T14 | Refund call fails or times out | Retry with backoff, alert raised, order marked for manual review, no duplicate refund | P1 |
| T15 | Second charge times out with unknown outcome | System queries status before deciding; no orphan, no double charge | P1 |
| T16 | Application crash or restart between first and second charge | Recovery job detects the orphan first charge and refunds it | P1 |
| T17 | Double submit, back button, and page refresh after first charge | Idempotency keys prevent duplicate charges | P1 |
| T18 | Two concurrent submissions of the same order | Exactly one pair of charges | P1 |
| T19 | 3-D Secure challenge on second card, completed and abandoned | Completed: order placed. Abandoned: first charge refunded | P2 |
| T20 | Same card used for both halves | Behaviour matches assumption A9 | P3 |
| T21 | Duplicate idempotency key reply from PayGate | Treated as success, not as a new charge | P2 |

**Records, reporting, and security (R7, R10)**

| ID | Case | Expected | Pri |
|----|------|----------|-----|
| T22 | Order record, customer receipt, admin view, and finance export | Two transactions, correct amounts, refund shown when applicable | P2 |
| T23 | Log and database inspection after T10 and T12 | No full card number, CVV, or expiry in logs or error messages | P2 |
| T24 | Audit trail for automatic refund | Reason, timestamps, gateway references present | P2 |

**Regression and non-functional (R2, R8)**

| ID | Case | Expected | Pri |
|----|------|----------|-----|
| T25 | Existing automated single-card suite, flag on and flag off | All pass on every build | P1 |
| T26 | Manual single-card smoke on sandbox, flag on and flag off | Order placed, amounts and receipts unchanged | P1 |
| T27 | Kill switch flipped while split orders in flight | In-flight orders complete or refund; new sessions see single-card only | P1 |
| T28 | Checkout latency with mock at the gateway's 95th-percentile response time | Within the agreed budget; assume double the single-card budget until product sets one | P2 |
| T29 | Alert fires when a refund exceeds 60 seconds; reconciliation report lists a seeded orphan | Alert received, report row present | P1 |

## 5. Schedule

| Day | Date | Sandbox | Focus |
|-----|------|---------|-------|
| 1 | Mon 26 Oct | No | Plan review with developers, build PayGate mock, prepare test data and timing harness |
| 2 | Tue 27 Oct | Yes | Confirm sandbox access and test cards. Record real response shapes for every outcome to calibrate the mock. Run T26 baseline |
| 3 | Wed 28 Oct | No | Unit and property tests (T01 to T09). Component tests on mock as code lands |
| 4 | Thu 29 Oct | Yes | First end-to-end run: T10, T11, T12 with at least one decline code, T13 timing |
| 5 | Fri 30 Oct | No | Failure paths on mock: T14 to T18, T21. Regression T25 |
| 6 | Mon 2 Nov | No | Exploratory UI, T06, T07, T22, T23. Defect triage |
| 7 | Tue 3 Nov | Yes | Full sandbox pass: all T12 variants, T13, T19, T27, T29 |
| 8 | Wed 4 Nov | No | Fix verification on mock, T25 rerun, T28 latency |
| 9 | Thu 5 Nov | Yes | Release-candidate sandbox regression: all P1 cases, T26 |
| 10 | Fri 6 Nov | No | Go or no-go, production smoke plan, rollout at low percentage |

The tester works roughly half of each day. Developers own unit tests, the mock, and recovery-job testing. On sandbox days one developer pairs with the tester for the full day so the four sandbox days are fully used.

## 6. Entry and exit criteria

Entry to sandbox testing on Thu 29 Oct: feature flag works, the mock-based happy path and decline path pass, sandbox credentials confirmed on 27 Oct.

Exit for release:

- All P1 cases pass on the Thu 5 Nov sandbox run.
- Every T12 variant shows a refund under 60 seconds, with timestamps attached to the test record.
- No open severity 1 or 2 defects. Severity 3 defects have an owner and a date.
- Single-card regression green with the flag on and off.
- Alerting and reconciliation report verified in a pre-production environment.
- Kill switch tested within the last two days before release.

## 7. Risks to this plan and mitigations

- **Sandbox lost on a planned day.** The mock carries all failure paths, so only timing and 3-D Secure cases are blocked. If Thu 5 Nov is lost, the Tue 3 Nov run becomes the release-candidate run and no code changes are accepted after it.
- **Feature not ready for Thu 29 Oct.** That day shifts to a single-card baseline and mock calibration. Both remaining sandbox days then carry the split-flow load, which leaves no slack. Flag this to the release owner on Wed 28 Oct if it is likely.
- **Sandbox differs from production.** Rollout starts at a low percentage with the alert and reconciliation report in place. The first production split orders are checked by hand on release day.
- **Tester capacity.** If defects exceed what half-time can verify, exploratory and P3 cases are dropped first. P1 cases are never dropped.
