# Test Plan: Split Payment (Release 5.3)

**Status:** Draft v1, 2026-10-24
**Release date:** Friday 2026-11-06 (10 working days: Mon 26 Oct to Fri 6 Nov)
**PayGate sandbox days in window:** Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov (four sessions)
**Test effort available:** one tester at roughly 4 hours/day (about 40 hours), plus two developers

## 1. Scope and assumptions

**In scope**

- Split checkout: amount entry, even-split default, both PayGate charges, order confirmation.
- Compensation path: second card declined, first charge refunded automatically within 60 seconds.
- Regression of the existing single-card checkout (about 4,000 orders/day).
- Security and PCI hygiene of the new path (no card data stored or logged).
- Monitoring and alerting for refund SLA breaches.

**Out of scope for 5.3** (assumed; confirm at kickoff)

- More than two cards, split by percentage, split across card plus gift card or wallet.
- Multi-currency and zero-decimal currencies (JPY). Single currency with two decimal places assumed.
- 3-D Secure / strong customer authentication on either card. Assumed PayGate handles or it is disabled in this market.
- Partial refunds and returns on split orders after fulfilment. Assumed to be a follow-up release.

**Assumptions where the brief is silent**

| # | Assumption | Why it matters |
|---|---|---|
| A1 | The UI offers "split evenly" as the default and a free-text amount for card 1. The remainder-cent rule applies to even split. | Determines the math test set. |
| A2 | Card 1 amount must be at least PayGate's minimum charge and strictly less than the order total, so both cards get a non-zero charge. | Boundary rules. If devs allow 0 or total, tests change. |
| A3 | PayGate uses direct charge (not auth then capture), with idempotency keys supported on charge and refund. If auth/capture is available, it is the preferred design and tests shift to "void the auth". | Core double-charge risk. |
| A4 | The feature ships behind a feature flag that can be turned off without a deploy. | Primary rollback mechanism. |
| A5 | Developers can build a local PayGate stub by Day 2 that replays sandbox responses and can inject declines, timeouts, and refund failures. | Only four real sandbox days exist. |
| A6 | Charges run sequentially: card 1 first, card 2 second. | Defines the failure matrix. |
| A7 | The same card may be used for both halves. | Edge case included, not blocked. |
| A8 | A refund that fails or exceeds 60 seconds is retried and raises an alert to a manual queue. | Defines SLA-breach behavior to test. |

## 2. Risk assessment

Risks are scored Likelihood x Impact (1 to 3 each). Score 6 or higher is P1 and gets real-sandbox coverage. Score 3 to 4 is P2 and is covered on the stub with one sandbox confirmation. Score 2 or lower is P3 and gets exploratory coverage only.

| ID | Risk | L | I | Score | Priority |
|---|---|---|---|---|---|
| R1 | Customer charged on card 1, card 2 declines, refund does not happen or takes over 60 s. Money held, support load, chargebacks. | 2 | 3 | 6 | P1 |
| R2 | Double charge: retry, timeout, or crash between the two charges re-sends a charge or the refund fires twice. | 2 | 3 | 6 | P1 |
| R3 | Rounding error: cents miscalculated, card totals do not equal order total, or remainder cent lands on card 2. Affects ledger and reconciliation. | 2 | 3 | 6 | P1 |
| R4 | Single-card checkout regresses (shared checkout code, new DB columns, changed PayGate client). 4,000 orders/day at stake. | 2 | 3 | 6 | P1 |
| R5 | Unknown outcome from PayGate (timeout on card 2 or on refund) treated as a decline, leading to refund of a charge that did not exist or no refund of one that did. | 2 | 3 | 6 | P1 |
| R6 | Order total changes between split entry and charge (coupon, tax, stock change) so the amounts no longer sum. | 2 | 2 | 4 | P2 |
| R7 | Input validation: negative, zero, over-total, three decimals, non-numeric, scientific notation. | 3 | 1 | 3 | P2 |
| R8 | Card data or full PAN leaks into logs, error messages, or order records on the new path. PCI scope. | 1 | 3 | 3 | P2 |
| R9 | Order marked paid or confirmation email sent before card 2 succeeds, or inventory not released after refund. | 2 | 2 | 4 | P2 |
| R10 | Checkout latency doubles because of two sequential gateway calls, raising abandonment. | 2 | 2 | 4 | P2 |
| R11 | Downstream systems (accounting export, refunds UI, reporting) cannot represent two payments on one order. | 2 | 2 | 4 | P2 |
| R12 | No observability: SLA breaches on refund go unnoticed in production. | 2 | 2 | 4 | P2 |
| R13 | UI and accessibility defects: confusing labels, keyboard navigation, screen reader on the new fields. | 2 | 1 | 2 | P3 |
| R14 | Plan risk: a sandbox day is lost to a PayGate outage or a blocking bug. | 2 | 3 | 6 | Plan |

## 3. Test approach by level

**Unit tests (developers, reviewed by tester; no sandbox needed)**
Target: split math, validation, state machine of the two-charge flow.

- Even split: 10000 -> 5000 / 5000; 10001 -> 5001 / 5000; 1 -> reject (card 2 would be 0); 3 -> 2 / 1.
- Custom amount: card1 = total - 1 (valid); card1 = total (reject per A2); card1 = 0 (reject); card1 = minimum charge (valid); card1 = minimum - 1 (reject).
- Input parsing: "12.345", "12,34", "-5", "1e3", "", whitespace, largest order total in the catalogue plus one cent.
- Invariant property test: for any total T in cents and any valid card1 amount, card1 + card2 == T and both >= minimum.
- State machine: every transition in the matrix in section 4, including "unknown" outcomes, has exactly one defined next state and never a second charge call without a fresh idempotency key.

**Integration tests against the PayGate stub (developers and tester; any day)**
The stub replays sandbox responses captured on Day 2 and can inject: card decline with each decline code, HTTP 5xx, connection timeout, slow response (over 60 s), refund decline, refund timeout, and duplicate idempotency key reply. All P1 and P2 failure scenarios run here first, nightly, in CI.

**End-to-end against the real PayGate sandbox (tester; Tue and Thu only)**
Confirms the stub is faithful and that real timing meets the 60 s SLA. Each session has a fixed script (section 6) so no sandbox hours are wasted deciding what to run.

**Regression (tester, automated suite plus targeted manual)**
Existing single-card automated suite runs on every build. Manual focus on shared surfaces: order record, payment record, emails, admin refund screen, accounting export, with the feature flag both on and off.

**Non-functional**
- Latency: p95 split checkout time versus single-card baseline, measured on the stub with realistic gateway delay. Acceptance: split p95 no more than 2x single-card p95.
- Refund SLA: 20 declined-card-2 trials on the real sandbox; all refunds confirmed by PayGate within 60 s of the decline. Record min, median, max.
- Load regression: run the existing load test (if any) with the flag on; if none exists, run 30 minutes of mixed single and split traffic at 3x the daily peak hourly rate against the stub.

**Security**
- Grep application logs, error tracker, and DB after a full sandbox session for any 13 to 19 digit sequences, CVV fields, or card holder names.
- Confirm tokens, not PANs, are passed between front end and server for both cards.
- Confirm amounts are validated server-side; tamper the card 1 amount in the request so the two amounts exceed or fall short of the total.
- Confirm a customer cannot trigger a refund of card 1 by replaying the card 2 decline response.

## 4. Failure matrix (core of P1 coverage)

| Card 1 result | Card 2 result | Expected outcome | Env |
|---|---|---|---|
| Success | Success | Order paid, two payment records, one confirmation, inventory committed | Stub + sandbox |
| Declined | Not attempted | No charge anywhere, clear message, user can retry with another card | Stub + sandbox |
| Success | Declined | Refund card 1 within 60 s, order unpaid, inventory released, customer told both outcomes | Stub + sandbox x20 |
| Success | Timeout / unknown | No blind refund. System queries PayGate for charge status, then refunds or completes. Never a second card 2 charge without new idempotency key | Stub + sandbox |
| Timeout / unknown | Not attempted | Status query before any retry; no duplicate card 1 charge | Stub + sandbox |
| Success | Declined, then refund declined | Retry with backoff, alert raised, order in "refund pending" state visible to support | Stub |
| Success | Declined, then refund times out | Same as above; SLA breach alert fires | Stub |
| Success | App crashes before card 2 | On restart, recovery job finds orphan charge and refunds or resumes; verified by killing the process mid-flow | Stub |
| Success | Success, then confirmation step fails | Order still paid, no refund, retry of post-payment steps is idempotent | Stub |
| Same card both halves | Success / Decline | Treated as two independent charges; refund targets the correct charge ID | Sandbox |

## 5. Entry and exit criteria

**Entry to sandbox E2E**
- Build deployed to test environment with flag on.
- Unit tests for math and state machine passing.
- Stub integration suite passing for the happy path and the card 2 decline path.

**Exit (go for release)**
- All P1 scenarios passed on the real sandbox, not only on the stub.
- Refund SLA met in 20 of 20 sandbox trials.
- No open Sev 1 or Sev 2 defects; Sev 3 defects have an owner and a target release.
- Single-card regression suite green on the release candidate with flag on and flag off.
- Log scan shows no card data.
- Dashboard and alert for "refund pending over 60 s" verified by firing it on the stub.
- Rollback rehearsed: flag turned off in test environment and single-card checkout confirmed working within 5 minutes.

## 6. Schedule

| Day | Date | Sandbox | Tester (about 4 h) | Developers |
|---|---|---|---|---|
| 1 | Mon 26 Oct | No | Kickoff, confirm assumptions A1 to A8, draft unit and failure-matrix cases, request PayGate test card list and decline codes | Start stub; agree idempotency and status-query design |
| 2 | Tue 27 Oct | Yes | Record real responses: success, each decline code, refund, timeout behavior; validate test cards; feed captures into stub | Finish stub with captures; math unit tests |
| 3 | Wed 28 Oct | No | Review unit tests, run stub integration suite, start regression on shared surfaces | Build flow and state machine |
| 4 | Thu 29 Oct | Yes | First E2E: happy path, card 1 decline, card 2 decline with refund timing (5 trials), same-card case | Fix findings live during session |
| 5 | Fri 30 Oct | No | Failure matrix on stub: timeouts, refund failure, crash recovery; security log scan | Fixes; recovery job |
| 6 | Mon 2 Nov | No | Non-functional: latency and load on stub; alert verification; downstream checks (accounting export, admin refund UI) | Fixes; monitoring |
| 7 | Tue 3 Nov | Yes | Full E2E regression of all P1 and P2 scenarios; 15 more refund-SLA trials (total 20); order-total-change scenario | Fixes |
| 8 | Wed 4 Nov | No | Retest fixes on stub; single-card regression with flag on and off; rollback rehearsal | Code freeze end of day |
| 9 | Thu 5 Nov | Yes | Release candidate sign-off run: happy path, card 2 decline with refund, card 1 decline, one timeout case; final log scan | On call for blockers only |
| 10 | Fri 6 Nov | No | Go/no-go with exit criteria; production smoke after deploy with flag on for internal users only: one real split order at minimum amount, one forced decline if PayGate supports a production test card | Deploy; monitor |

Rollout recommendation: flag on for internal users on release day, then 5% of customers for two days, then 100%. Alert thresholds: any refund over 60 s, split error rate above 2%, single-card error rate above baseline plus 0.5 points.

## 7. Roles

- **Tester:** test design, sandbox sessions, regression, security scan, defect triage, sign-off report.
- **Developer 1:** PayGate stub, unit tests for math and state machine, latency fixes.
- **Developer 2:** recovery job, monitoring and alerts, downstream export changes, pairing with tester on sandbox days.
- **Product owner (assumed to exist):** decides A2, A4, A7 on Day 1 and makes the go/no-go call.

## 8. Plan risks and contingencies

- **Sandbox outage on a planned day (R14):** the stub suite is the fallback; the Nov 5 session is reserved as sign-off, so if Nov 3 is lost, Nov 5 runs the full suite and the sign-off subset is reduced to the P1 rows. If two sessions are lost, recommend releasing with the flag off and enabling after a post-release sandbox session.
- **Stub infidelity:** every stub scenario that can run on sandbox is confirmed there at least once on Day 7. Discrepancies found are logged as defects against the stub and the affected tests re-run.
- **Half-time tester capacity:** developers own all unit tests and run the stub suite in CI; the tester's hours go to sandbox sessions, failure matrix, regression, and security. If capacity runs short, P3 items (R13) are dropped first, then load testing is reduced to a smoke run.
- **Late design change (for example moving to auth/capture):** the failure matrix is re-baselined on the next sandbox day and the schedule slips one day; release date holds only if the change lands by Day 5.
- **Blocking bug found on Day 9:** fix is allowed only if it is isolated to the split path and can be re-verified on the stub plus one targeted production smoke on Day 10. Otherwise ship with the flag off.

## 9. Deliverables

- Test case set covering sections 3 and 4, with priority and environment per case.
- Stub scenario catalogue and captured PayGate responses (owned by developers, reviewed by tester).
- Sandbox session logs with refund-SLA timing table.
- Regression report for single-card checkout, flag on and flag off.
- Security scan results.
- Sign-off report against the exit criteria, delivered by midday Fri 6 Nov.
