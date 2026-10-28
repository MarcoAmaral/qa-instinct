# Test Plan: Split Payment (release 5.3)

| Field | Value |
| :-- | :-- |
| Project / version | Checkout, release 5.3, feature "Split payment" |
| Plan owner | Tester (holds the test management role and the testing role) |
| Plan date | 2026-10-25 |
| Release date | 2026-11-06 (working day 10; day 1 is Monday 2026-10-26) |
| Board URL | N/A — not provided; placeholder ticket ID `SPLIT-53` is used below |
| Tech stack | N/A — not provided; assumed a web checkout backed by a payment service that calls PayGate over HTTPS |
| Environments | Local, CI, Staging (connected to PayGate sandbox on Tuesdays and Thursdays), Production |

## 1. Context of testing

**Scope, in:**

- Split rules: customer-entered amount for card 1, remainder to card 2; integer cents; the "split evenly" option puts the odd cent on card 1.
- Two sequential PayGate charges, and automatic refund of charge 1 within 60 s when charge 2 is declined.
- Failure handling around PayGate: declines, errors, timeouts, duplicate submissions, process crash between the two charges.
- Order, receipt and ledger records for a split order and for a refunded split attempt.
- Regression of the existing single-card checkout (about 4,000 orders a day).
- Existing post-purchase refund flow applied to a split order (analysis only, see R09).

**Scope, out:** more than two cards; mixing a card with vouchers or wallets; 3-D Secure flows (assumed handled by PayGate unchanged); currencies without 100 minor units; native mobile apps; a PCI audit; load testing of PayGate; a full accessibility audit (a keyboard-only check of the new field is included in the exploratory session).

**Objectives:**

1. Show the split arithmetic is correct to the cent for every partition and boundary, and that the two charges always sum to the order total.
2. Show the charge-2-declined path refunds charge 1 automatically, every time, within 60 s, and that no path leaves money taken without an order.
3. Show the single-card checkout behaves exactly as before, with the feature flag off and on.
4. Give the Product Owner a go/no-go record on 2026-11-06 built from results obtained against the real PayGate sandbox.

**Test basis:** the feature brief above; the PayGate API documentation (version N/A — not provided; to be pinned on day 1); the existing single-card checkout test suite; the assumptions in item 2 until the Product Owner confirms or corrects them.

## 2. Assumptions and constraints

Assumptions (each one is a question for the Product Owner on day 1; testing proceeds on the stated value until answered):

- A1. One currency with 100 minor units. Amounts travel as integer cents from the browser to PayGate; no floating point on the path.
- A2. The UI offers both "enter amount for card 1" and "split evenly". The remainder-cent rule applies to "split evenly" and to any server-side rounding.
- A3. Each card must carry at least 1 cent; an amount of 0 or of the full total is rejected as "not a split". PayGate's own minimum charge, if higher, replaces 1 cent.
- A4. Card 1 is charged first. If card 1 is declined, card 2 is never charged and nothing is refunded.
- A5. "Declined" for charge 2 covers an explicit decline, a PayGate error, and a timeout whose status query returns "not charged". A status still unknown after the retry budget is treated as declined and charge 1 is refunded.
- A6. The 60 s is measured from the application receiving the decline of charge 2 to PayGate acknowledging the refund request, read from application logs.
- A7. The feature ships behind a feature flag, off in production until the go decision. The off state must equal today's behaviour.
- A8. Card data is tokenised by PayGate hosted fields; no card number touches the application.
- A9. Feature-complete build on Staging by Monday 2026-11-02 (day 6); partial builds are deployable earlier.
- A10. A working day is 8 h; half time is 40 h over the ten days, and the tester may concentrate hours on sandbox days.
- A11. An automated single-card checkout smoke suite exists and runs in CI. If it does not, TC-CHK-001 below becomes a manual run of the five main single-card scenarios and R03 is re-scored.
- A12. Both developers are full time on this feature.

Constraints: PayGate sandbox reachable only on 2026-10-27, 10-29, 11-03 and 11-05 (four windows, none on release day); one half-time tester; ten working days; no history of similar work for estimation.

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :-- | :-- | :-- | :-- |
| Product Owner | N/A — name not provided | Confirms assumptions A1 to A9, grants P1 exceptions, makes the go/no-go decision | Receives the gate evidence; witnesses TC-SPLIT-003 on 2026-11-05 |
| Developers (2) | N/A — names not provided | Build the feature, unit and component integration tests, the PayGate recorded fake, fixes | Hold the testing role at component and component integration level |
| Tester | N/A — name not provided | This plan, test design, system and system integration execution, reports, go/no-go record | Test management role and testing role |
| Finance / reconciliation | N/A — assumed to exist | Confirms a split order and a refunded attempt reconcile in the ledger | Acceptance check of TC-SPLIT-008 evidence |
| Support / on-call | N/A — assumed to exist | Receives refund-failure alerts in production | Confirms the alert from TC-SPLIT-007 reaches them |
| PayGate support | N/A — contact not provided | Sandbox test cards, decline and timeout simulation, API version | Needed on day 1 for R12 |

## 4. Communication

- **Daily stand-up**: test status in one line, blockers named.
- **Progress report** at the end of each sandbox day (10-27, 10-29, 11-03, 11-05) and on 10-30, in the tracker, using the progress report content of CTFL §5.3.2: period, progress against this plan, impediments, metrics from item 6, new or re-scored risks, next period.
- **Defect reports**: one `DR-SPLIT-NNN` per finding, filed the same day it is found, linked from the progress report.
- **Go/no-go meeting**: 2026-11-06, 09:00, Product Owner, both developers, tester. Input: the completion report with every case on one row and the "Not run — resume point" section.
- **Templates**: test cases `TC-SPLIT-NNN` and `TC-CHK-NNN`; defect reports `DR-SPLIT-NNN`; completion report in the row format of the reporting reference.

## 5. Risk register

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Charge 2 declined and charge 1 not refunded, or refunded after 60 s: customer's money held with no order | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition testing, all-transitions criterion; timing measured on sandbox over at least 10 runs; crash-between-charges test on the fake; production alert on refund age > 60 s | Dev/QA |
| 2 | R02 | Charge 2 outcome unknown (timeout, PayGate error) treated wrongly: refund issued for a charge that went through, or no refund when it failed | Product | 3 | 5 | 15 | 🔴 CRITICAL | Decision table over charge-2 outcomes × status query result; fake simulates timeout then "charged" and timeout then "not charged"; status query before any refund | Dev/QA |
| 3 | R03 | Single-card checkout (about 4,000 orders a day) regresses through shared checkout code | Product | 2 | 5 | 10 | 🟠 HIGH | Impact analysis of changed modules on day 5; existing smoke suite run with flag off and on; p95 checkout latency compared before and after on Staging; feature flag as rollback | Dev/QA |
| 4 | R04 | Remainder cent or rounding wrong: the two charges do not sum to the order total | Product | 3 | 4 | 12 | 🟠 HIGH | Unit tests with EP and 2-value BVA on amount and total; property test "charge1 + charge2 = total" over random totals; ledger check of a split order | Dev |
| 5 | R05 | Duplicate submission (double click, browser retry, network retry) charges a card twice | Product | 3 | 4 | 12 | 🟠 HIGH | Idempotency key per order attempt; test with two concurrent submits on the fake and one on sandbox; button disabled after first submit | Dev/QA |
| 6 | R06 | Tampered request: card 1 amount edited in the browser so the sum differs from the total, is negative, or is non-integer | Product | 2 | 5 | 10 | 🟠 HIGH | Server recomputes and validates both amounts against the server-side order total; API tests sending tampered bodies | Dev/QA |
| 7 | R07 | Refund request fails or times out at PayGate and nobody is told: orphan charge | Product | 2 | 5 | 10 | 🟠 HIGH | Retry with backoff, then alert to on-call; fake returns refund error and refund timeout; alert delivery confirmed with support | Dev/QA |
| 8 | R08 | Order, receipt, e-mail and ledger show one charge or wrong amounts for split orders | Product | 3 | 3 | 9 | 🟠 HIGH | API and UI checks of order detail, receipt and ledger entries for a paid split order and a refunded attempt; finance reviews one of each | QA |
| 9 | R09 | Existing post-purchase refund or cancellation assumes one charge per order and refunds only charge 1 of a split order | Product | 3 | 4 | 12 | 🟠 HIGH | Analysis case TC-SPLIT-010 on sandbox; if 5.3 claims post-purchase refunds of split orders, the case moves into the gate (dated note) | Dev/QA |
| 10 | R10 | Input validation gaps: 0, full total, more than total, non-integer, comma decimal, same card twice | Product | 3 | 2 | 6 | 🟡 MEDIUM | EP and BVA cases at unit level, one API negative run on Staging, exploratory session on the field | Dev/QA |
| 11 | R11 | Two attempts on the same order interleave (customer retries while refund of charge 1 is pending): inconsistent order state | Product | 2 | 4 | 8 | 🟠 HIGH | Invalid transitions in the state table attempted one per case; order locked while a refund is pending | Dev |
| 12 | R12 | Only four sandbox windows; a build that misses a window loses two days of real-gateway testing, and no window exists on release day | Project | 4 | 4 | 16 | 🔴 CRITICAL | Record real PayGate responses on 10-27 and build a fake from them for the other days; each window has a named case list; a PayGate-touching fix after 11-05 means no-go or ship with flag off | QA/PO |
| 13 | R13 | PayGate sandbox lacks test cards for decline, refund failure or timeout, or behaves unlike production | Project | 3 | 4 | 12 | 🟠 HIGH | Ask PayGate support on day 1; what the sandbox cannot simulate is covered on the fake and listed as residual risk in the completion report | QA |
| 14 | R14 | Tester capacity (40 h) is below the pessimistic estimate (61 h) | Project | 3 | 3 | 9 | 🟠 HIGH | Risk-based order; developers run the unit and fake-based levels; pre-agreed drop list in item 7 | QA/PO |
| 15 | R15 | Feature-complete build arrives after 2026-11-02, leaving one full sandbox window instead of two | Project | 3 | 4 | 12 | 🟠 HIGH | Partial builds deployed to Staging before each window; 10-29 window tests whatever exists; control directive in item 6 | Dev/PO |

Register reviewed at every progress report; re-scores recorded as dated notes, never overwritten.

## 6. Test approach

**Pyramid preset:** Backend / API (70% unit, 20% integration, 10% end-to-end). The business logic (split arithmetic, validation, charge and refund state machine) lives in the payment service, not in the UI.

**Quadrant check:** Q1 unit and component integration tests in CI (developers). Q2 API cases and the gate cases, written as `TC-SPLIT-NNN` from the acceptance criteria. Q3 one exploratory session on the split UI on 2026-11-03 (charter: amount field, even-split option, error messages, keyboard-only use, two browsers) and the Product Owner and finance acceptance checks. Q4 smoke suite, security checks (R05, R06), reliability and time behaviour (R01, R02, R07), and a light performance check (R03). Usability lab and compatibility matrix are not in Q3/Q4: the UI change is one field and one option, and the two-browser exploratory session is the accepted coverage.

**Levels, who tests, independence:**

| Level | Test object | Who tests | Degree | Why it fits |
| :-- | :-- | :-- | :-- | :-- |
| Component | Split calculator, validators, state machine | Author, reviewed by the other developer | Some | Logic is exhaustively testable here and cheap; tester reviews the case list against the BVA and decision-table items below |
| Component integration | Payment service + PayGate recorded fake, order and ledger writers | Developers; tester pairs on failure scenarios | Some | Needs code-level control of timeouts, crashes and retries that the sandbox cannot inject |
| System and system integration | Staging + PayGate sandbox, UI and API | Tester | Some (same delivery team) | A high degree is not available with one tester in the team; compensated by the Product Owner witnessing TC-SPLIT-003 and finance checking the ledger |
| Acceptance | Gate evidence, ledger of one split order and one refunded attempt | Product Owner, finance | Some | Validates the business need (money correct, customer never left charged) |

**Types:** functional (all levels); non-functional: time behaviour (refund ≤ 60 s, timeout budgets), reliability (crash and retry), security (tampering, idempotency), performance efficiency (single-card p95 unchanged on Staging); usability through the exploratory session only.

**Techniques and coverage items:**

- Equivalence partitioning and 2-value BVA on card 1 amount for total T: 0, 1, T−1, T (A3), plus T+1, negative, non-integer, comma decimal, empty; totals T = 1, 2, 3 (even split gives 2/1), 1001 (even split gives 501/500), and a large value near the gateway maximum. Coverage: every partition and boundary item exercised, at unit level, with one API negative run on Staging.
- Decision table on charge-2 outcome (approved, declined, error, timeout) × status query result (charged, not charged, unknown) → actions (mark paid, refund charge 1, alert). Every feasible column exercised; infeasible columns deleted and listed.
- State transition testing of the order attempt (Created → Charge1Authorised → Paid; Charge1Authorised → Charge2Declined → RefundRequested → Refunded; RefundRequested → RefundFailed → alerted; Charge1Declined → Failed). Criterion: all transitions, invalid ones attempted one per case (R11), because the object is money.
- Error guessing: double submit, back button after charge 1, process killed between the charges, same card for both halves, refund arriving before the decline is persisted.
- Exploratory testing: one 90-minute session, charter above.
- Checklist-based: receipt, e-mail, order detail, ledger, each showing two charges with the right amounts.

**Coverage floors:** 100% of register rows R01 to R11 with at least one executed case; branch coverage of the split calculator and state machine 80% or higher (read the uncovered branches, do not chase the number).

**Deliverables:** this plan; `TC-SPLIT-001` to about `TC-SPLIT-030` and `TC-CHK-001`; the PayGate recorded fake with its recording date; five progress reports; defect reports; the completion report; the go/no-go record.

**Entry criteria, component and component integration:** test basis item and ticket in "In development"; fake recorded from the 2026-10-27 window; CI green on the branch.

**Entry criteria, system and system integration:** ticket "Ready for QA"; build deployed to Staging with commit SHA and deployment ID recorded; CI green for that SHA; flag state recorded; sandbox test cards and credentials available in the secrets store; it is a Tuesday or Thursday.

**Exit criteria, component and component integration:** all BVA, decision-table and all-transitions items have a test; branch floor met or deviations read and accepted by the tester.

**Exit criteria, system level and release:** every gate case passed on a sandbox day against the release candidate SHA; 100% P0 cases passed; 100% P1 cases passed or each failure holds a recorded Product Owner exception; zero open Critical, zero open High without exception; single-card smoke green with flag off and on; refund timing max ≤ 60 s over at least 10 sandbox runs; completion report signed by tester and Product Owner. Stopping for lack of time is allowed only with the Product Owner's recorded acceptance of the named residual risks.

**Release gate** (failure of any row stops the release):

| ID | What it proves | Where | Technique | Result |
| :-- | :-- | :-- | :-- | :-- |
| TC-SPLIT-001 | Manual split, both approved: order paid, two PayGate charges whose amounts sum to the total | Staging + sandbox | EP | N/A — not yet run |
| TC-SPLIT-002 | Even split of an odd total gives the extra cent to card 1 (1001 → 501 / 500) | Staging + sandbox | BVA | N/A — not yet run |
| TC-SPLIT-003 | Charge 2 declined: charge 1 refunded automatically, refund acknowledged ≤ 60 s, order not paid, customer told | Staging + sandbox, 10 repetitions | State transition | N/A — not yet run |
| TC-SPLIT-004 | Charge 1 declined: charge 2 never attempted, no refund, order not paid | Staging + sandbox | State transition | N/A — not yet run |
| TC-SPLIT-005 | Card 1 amount of 0, T, T+1, negative and non-integer rejected by the server with a clear message | Staging API | BVA | N/A — not yet run |
| TC-SPLIT-006 | Request whose amounts do not sum to the server-side total is rejected; nothing charged | Staging API | Error guessing | N/A — not yet run |
| TC-SPLIT-007 | Refund request fails at PayGate: retried, then on-call alerted; charge 1 never silently orphaned | CI (fake) + alert check on Staging | Decision table | N/A — not yet run |
| TC-CHK-001 | Single-card checkout smoke suite passes with flag off and with flag on; p95 latency within 10% of the pre-feature baseline | Staging | Regression | N/A — not yet run |

Execution order of the gate (risk-based, with overrides):

1. TC-CHK-001 flag off, on day 8 (Wednesday 2026-11-04): needs no sandbox, so it leaves the windows for the others.
2. TC-SPLIT-001 on the sandbox day, before TC-SPLIT-003 although it ranks lower: 003 depends on a working charge-1 path.
3. TC-SPLIT-003, ten repetitions, timings recorded.
4. TC-SPLIT-004.
5. TC-SPLIT-002.
6. TC-SPLIT-007: the fake part runs in CI any day; the alert check runs on Staging the same sandbox day.
7. TC-SPLIT-005 and TC-SPLIT-006: API-only, run at the end of the window or on the fake if the window closes.
8. TC-CHK-001 flag on, on the release candidate, 2026-11-05.

Analysis cases (inform, do not gate): timeout-then-charged and timeout-then-not-charged (R02), double submit (R05), crash between charges (R01), concurrent retry during pending refund (R11), receipt, e-mail and ledger checks (R08), post-purchase refund of a split order (R09, TC-SPLIT-010), same card twice, large totals, the exploratory session. A finding here moves into the gate only when it is caused by the change, with a dated note.

**Metrics collected:** gate cases passed / 8; register rows with an executed case / 15; cases planned vs executed per sandbox window; open defects by severity; refund timing max and p95 over the sandbox runs; tester hours spent against the estimate.

**Control directives agreed in advance:** if the feature-complete build misses 2026-11-02, the 2026-11-03 window runs the gate on the partial build and 2026-11-05 becomes the only full run (R15). If a fix after 2026-11-05 touches any PayGate call, the Product Owner chooses no-go or release with the flag off (R12). If hours exceed 36 by day 8, the drop list in item 7 applies.

**Test data (fixture set):** sandbox test cards for approve, decline, insufficient funds and, if PayGate provides them, timeout and refund failure (credentials in the team secrets store, never in testware); one test customer; orders with totals 1, 2, 3, 1001 and 10000 cents, writable by tests and rebuilt from a seed script; the recorded PayGate fake, read-only, dated with its recording window; ledger entries for the finance check, read-only once created. A missing fixture blocks a case; it does not fail it.

**Environment:** Staging with the release candidate SHA, its deployment ID, flag state, PayGate sandbox API version and the fake version recorded on every result. Local runs are dry runs and produce no results.

**Deviations from test policy and strategy:** N/A — no written policy or strategy was provided; the one deviation from this package's default is that component integration results obtained on the fake count as evidence on non-sandbox days, while system integration results count only from sandbox days.

## 7. Estimate

Technique: three-point estimation, one estimator, no history for ratios. Tester effort in person-hours, decomposed:

| Task | a | m | b | E |
| :-- | --: | --: | --: | --: |
| Test analysis and design (cases, decision table, state table, charter) | 4 | 6 | 9 | 6.2 |
| Recording the fake with the developers, reviewing unit cases | 2 | 4 | 8 | 4.3 |
| Sandbox execution over four windows, including timing runs | 12 | 18 | 28 | 18.7 |
| Single-card regression, latency comparison, flag off and on | 3 | 4 | 7 | 4.3 |
| Defect reports, retests, progress and completion reports, go/no-go record | 3 | 5 | 9 | 5.3 |
| **Total** | **24** | **37** | **61** | **38.8** |

Reported as 39 ± 6 person-hours (between 33 and 45) against 40 available. The pessimistic case does not fit. Drop list, in order, if hours run out: the exploratory session, receipt and e-mail checks (ledger stays), TC-SPLIT-010, large-total cases. Developer test effort is assumed at 16 to 24 person-hours for unit tests and the fake (A12).

Assumptions behind the figures: A9 to A12 hold; PayGate support answers on day 1; each sandbox window yields at least 6 productive hours; no more than two Critical defects are found.

## 8. Budget and schedule

Budget: N/A — no monetary budget provided; cost is the tester's 40 h and the developers' 16 to 24 h above.

| Day | Date | Sandbox | Planned work |
| :-- | :-- | :-- | :-- |
| 1 | Mon 2026-10-26 | No | Assumptions to Product Owner; PayGate support asked for test cards; test design starts; developers start the fake scaffold |
| 2 | Tue 2026-10-27 | Yes | Record real responses (approve, decline, refund, error) for the fake; check which outcomes the sandbox can simulate; baseline single-card p95 |
| 3 | Wed 2026-10-28 | No | Test cases finished and reviewed; unit and fake-based tests in CI |
| 4 | Thu 2026-10-29 | Yes | First system integration run on the partial build: TC-SPLIT-001, 004, 005, 006 and whatever of 003 exists |
| 5 | Fri 2026-10-30 | No | Impact analysis for regression; defects filed; progress report |
| 6 | Mon 2026-11-02 | No | Feature complete on Staging (A9); fake-based analysis cases (R02, R05, R11, crash) |
| 7 | Tue 2026-11-03 | Yes | Full gate run plus analysis cases; 10 timing runs; exploratory session |
| 8 | Wed 2026-11-04 | No | Fixes; retests on the fake; TC-CHK-001 flag off; finance ledger check |
| 9 | Thu 2026-11-05 | Yes | Confirmation testing of fixes and full gate re-run on the release candidate SHA; Product Owner witnesses TC-SPLIT-003; TC-CHK-001 flag on |
| 10 | Fri 2026-11-06 | No | Completion report; go/no-go at 09:00; release with flag on, or flag off per R12 |

## 9. Configuration management of testware

- Test cases, this plan, the register, the fake recordings and the reports live in the product repository under a `docs/qa/5.3-split-payment/` folder, versioned with the code; each item has an identifier (`TC-SPLIT-NNN`, `DR-SPLIT-NNN`) and links to `SPLIT-53`.
- Every result names the commit SHA, Staging deployment ID, flag state, PayGate sandbox API version and fake recording date. A result without them is not reported.
- The Staging environment approved on 2026-11-03 is the baseline; changes to it after that go through the Product Owner, and the previous baseline stays restorable so 2026-11-03 results can be reproduced.
- Unit and fake-based tests run in the CI pipeline on every push; the gate cases needing the sandbox are manual on this release, so release 5.3 is continuous delivery, with the gate evidence going to the Product Owner.
- Corrections to any shared item are made in place with a dated, attributed note, never by deletion.
