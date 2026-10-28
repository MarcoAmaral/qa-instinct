# Test Plan: Split Payment (Release 5.3)

## 1. Assumptions

| # | Assumption |
|---|---|
| A1 | Today is Sat 24 Oct 2026. Working days are Mon–Fri, so the release is Fri 6 Nov 2026. Sandbox days in the window: Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. |
| A2 | Tester capacity is about 5 person-days total. Developers own unit tests, a local PayGate stub, and test hooks. |
| A3 | PayGate's sandbox has test card numbers that trigger approve, decline, and timeout, plus a refund endpoint. No vendor simulator exists outside sandbox days, so the developers build a stub that mimics recorded sandbox responses. |
| A4 | The UI proposes a 50/50 default split that the customer can edit. The remainder-cent rule applies to that default. Each card must carry at least 1 cent, and the two amounts must sum exactly to the order total. |
| A5 | "Refunded within 60 seconds" means a full refund of the first charge is accepted by PayGate within 60 seconds of receiving the second card's decline. |
| A6 | The feature ships behind a feature flag. If not, this plan treats that as a P1 defect. |
| A7 | Single currency with two decimal places. No 3-D Secure, no more than two cards, no saved-card flows. |
| A8 | An automated regression suite exists for single-card checkout and runs in CI. |
| A9 | Card 1 is charged before card 2. If card 1 is declined, card 2 is never attempted. |

## 2. Risk register

Priority drives effort: P1 risks get sandbox time and sign-off gates, P2 get stub-based coverage, P3 get exploratory coverage only if time remains.

| ID | Risk | Likelihood | Impact | Pri | Coverage |
|---|---|---|---|---|---|
| R1 | Card 2 declined but card 1 not refunded, or refunded after 60s. Customer charged with no order. | Med | Critical | P1 | Sandbox, timed, 10 repetitions |
| R2 | Single-card checkout regresses (4,000 orders/day). | Med | Critical | P1 | Automated suite each build, manual smoke, flag on and off |
| R3 | Split arithmetic wrong: amounts do not sum to total, remainder cent on wrong card, float rounding. | Med | High | P1 | Unit tests, boundary table |
| R4 | Unknown state after timeout on charge 2 or on the refund call. Orphan charge with no order. | Med | High | P1 | Stub (timeouts), sandbox (one real timeout card if available) |
| R5 | Double charge or double refund from retries, double-submit, or page refresh. | Med | High | P1 | Stub with idempotency assertions, manual double-click |
| R6 | Client-side amount tampering so the two charges do not equal the order total. | Low | High | P1 | API tests with altered payloads |
| R7 | Refund call fails. No retry, no alert, order silently confirmed. | Med | High | P2 | Stub (refund 500 / timeout), alert verification |
| R8 | Invalid input accepted: zero, negative, greater than total, three decimals, non-numeric. | High | Med | P2 | Unit and UI tests |
| R9 | Order records, receipts, and reconciliation show one transaction instead of two, or omit the refund. | Med | Med | P2 | Manual check after each sandbox flow |
| R10 | Checkout latency doubles because two sequential gateway calls are made. | Med | Med | P2 | Timing measured during sandbox runs |
| R11 | Same card entered in both slots. | Low | Low | P3 | One exploratory case; assume rejected |
| R12 | Schedule: sandbox only four days, half-time tester, feature may not be ready for the first sessions. | High | High | — | Mitigation in section 5 |

## 3. Test levels and ownership

| Level | Owner | Runs on | Content |
|---|---|---|---|
| Unit | Developers | Every commit | Split calculation, validation, charge/refund state machine |
| Integration against PayGate stub | Developers write, tester reviews and extends | Any day | Decline, timeout, refund failure, retry, idempotency, flag on/off |
| Sandbox end-to-end | Tester, developer on call | Tue/Thu only | Scripted P1 flows with real gateway responses and timing |
| Regression | Tester | Each build and at release candidate | Automated single-card suite plus manual smoke |
| Release safeguards | Developers | Release day | Flag, dashboards, alerting, rollback |

## 4. Test cases

### 4.1 Split calculation (R3, R8) — unit, run daily

| Total | Input | Expected card 1 / card 2 |
|---|---|---|
| 100.00 | default split | 5000 / 5000 |
| 100.01 | default split | 5001 / 5000 |
| 0.03 | default split | 2 / 1 |
| 0.01 | any | Split not offered (A4) |
| 100.00 | first = 0.01 | 1 / 9999 |
| 100.00 | first = 99.99 | 9999 / 1 |
| 100.00 | first = 100.00 | Rejected |
| 100.00 | first = 0, negative, 100.01, 10.005, "abc" | Rejected with message |
| 999,999.99 | first = 500,000.00 | No overflow, no float drift |
| 0.10 + 0.20 style totals | default | Integer cents only, never 0.30000000004 |

### 4.2 Charge and refund flow (R1, R4, R5, R7, R9) — stub daily, sandbox on Tue/Thu

| ID | Scenario | Expected |
|---|---|---|
| F1 | Both cards approved | Order confirmed, two transactions stored, receipt lists both amounts |
| F2 | Card 1 declined | Card 2 never called, no charge, clear message, order not created |
| F3 | Card 2 declined | Card 1 refunded, refund accepted by PayGate within 60s, order not created, customer told both outcomes |
| F4 | Card 2 times out | Treated as failed, card 1 refunded, no orphan charge, alert raised |
| F5 | Refund call fails or times out | Retried, order stays unconfirmed, alert raised, item lands in manual review queue |
| F6 | Same request submitted twice (double-click, retry) | Exactly one charge per card, idempotency key reused |
| F7 | Browser refresh or back between charge 1 and charge 2 | No second charge 1, state recovers or cleanly aborts with refund |
| F8 | Payload altered so card 1 + card 2 ≠ total | Rejected server-side before any charge |
| F9 | Flag off | Split option hidden, single-card flow unchanged |
| F10 | Refund timing under load | F3 repeated 10 times in sandbox; every refund ≤ 60s, p50 recorded |

### 4.3 Single-card regression (R2)

- Full automated suite on every build and on the release candidate, flag on and flag off.
- Manual smoke on each sandbox day: approved, declined, refund of a single-card order.
- Compare checkout latency before and after the change on the single-card path.

## 5. Schedule

| Day | Date | Sandbox | Tester (0.5d) | Developers |
|---|---|---|---|---|
| 1 | Mon 26 Oct | | Confirm assumptions, finalise cases, request sandbox test cards | Build PayGate stub with decline, timeout, refund-fail switches |
| 2 | Tue 27 Oct | Yes | Record real sandbox responses and refund timing baseline, even without the feature | Make stub match recorded responses |
| 3 | Wed 28 Oct | | Review unit tests for 4.1 | Feature build, unit tests |
| 4 | Thu 29 Oct | Yes | First end-to-end on early build: F1, F2, F3 timed | On call for fixes |
| 5 | Fri 30 Oct | | Stub runs: F4–F8; regression suite | Fix defects |
| 6 | Mon 2 Nov | | Verify fixes on stub, exploratory R11, R9 checks | Observability, alerting, retry logic |
| 7 | Tue 3 Nov | Yes | Full P1 sandbox run including F10 (10 timed refunds) | On call |
| 8 | Wed 4 Nov | | Full regression, flag on/off, fix verification. Code freeze at end of day | Final fixes only |
| 9 | Thu 5 Nov | Yes | Release-candidate verification on sandbox. Go/no-go decision | On call |
| 10 | Fri 6 Nov | | Release, monitor dashboards | Staged rollout, rollback ready |

Schedule risk (R12): if the feature is not testable by Thu 29 Oct, Tue 3 Nov becomes the first real run and only one sandbox day remains for fixes. In that case, recommend releasing with the flag off and enabling it after a further sandbox verification the following Tuesday.

## 6. Entry and exit criteria

Entry to sandbox sessions: build deployed to test environment, stub-based P1 cases passing, flag toggles verified.

Exit for release:

- All P1 cases pass on sandbox on Thu 5 Nov.
- F10: 10 of 10 refunds accepted within 60s.
- No open severity 1 or 2 defects.
- Single-card regression suite green with flag on and flag off.
- Alert for refund failure and for orphan charge fires in test.
- Rollback by flag verified.

## 7. Release safeguards

- Feature flag on for a small share of traffic on day 1, widened over the following week.
- Dashboard: split orders, card 2 declines, refund latency, refund failures, orphan charges (charge without confirmed order).
- Daily reconciliation report comparing PayGate transactions against orders for the first week.
- Rollback is flag off. No data migration is involved, so rollback needs no further step.

## 8. Out of scope

Load testing against PayGate, 3-D Secure, multi-currency, more than two cards, mobile-specific UI beyond the shared API, PCI assessment (card data is tokenised by PayGate).

## 9. Residual risks after this plan

- Timeout and refund-failure behaviour is validated mainly on the stub. Real gateway behaviour under those conditions is seen at most once.
- Sandbox refund timing may not match production timing. The 60s target should be monitored in production, not assumed.
- Half-time tester leaves no slack. Any slip of more than one day consumes the final sandbox session.
