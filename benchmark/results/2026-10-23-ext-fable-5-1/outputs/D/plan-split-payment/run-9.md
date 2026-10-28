# Test Plan: Split Payment (Release 5.3)

| Field | Value |
| :-- | :-- |
| Plan ID / version | TP-SPLIT-5.3 v1.0, 2026-10-25 |
| Owner | Tester (test management role and testing role; see item 6) |
| Release date | Friday 2026-11-06 (10 working days from Monday 2026-10-26) |
| PayGate sandbox windows | Tue 2026-10-27, Thu 2026-10-29, Tue 2026-11-03, Thu 2026-11-05 |
| Board | N/A — tracker not named in the brief; assumed JIRA, ticket key SPLIT-5.3, all IDs below are relative to it |

## 1. Context of testing

**Scope.** Release 5.3 adds split payment: one order paid with two cards, the customer sets the first-card amount, the second card carries the rest. Amounts are integers in cents. On an even split of an odd total, the extra cent goes on the first card. Both charges go through PayGate. If the second charge is declined, the first charge is refunded automatically within 60 seconds.

**In scope**

- Split amount entry and validation (custom amount and even split), in the checkout UI and in the API.
- Orchestration of the two PayGate charges and the order outcome for every combination of charge results.
- Automatic refund of the first charge when the second is declined, including the 60-second limit and the failure path of the refund itself.
- Idempotency of the checkout submission (no duplicate charges on retry, double-click or reload).
- Regression of the existing single-card checkout (about 4,000 orders a day), with the feature flag off and on.
- Security of the amount handling (server-side authority over amounts, no card data in logs).
- A latency check of the two-charge flow against the current single-card checkout.

**Out of scope**

- PayGate's own correctness and availability (external; covered by its contract and by R15).
- Refund behaviour on the customer's bank statement timing (outside the system; only the PayGate refund acknowledgement is checked).
- Three or more cards, saved-card wallets, gift cards, currencies without a minor unit (not in the brief; assumed not built).
- Full load testing of checkout (no tool or environment for it in 10 days; latency is measured, not load-tested; recorded as a deviation in item 6).

**Objectives**

1. Show that money is split and charged exactly as the brief states, to the cent, in every outcome combination.
2. Show that a customer is never left charged without an order, and never charged twice.
3. Show that the single-card checkout behaves exactly as before the change.
4. Give the Product Owner a release gate record from a sandbox-verified build before 2026-11-06.

**Test basis.** The feature brief above; PayGate API documentation (charge, decline codes, refund, idempotency key); the existing single-card checkout test suite; the decision table and state model in item 6, which the team reviews on day 1 as the agreed reading of the brief.

## 2. Assumptions and constraints

Assumptions (each stated because the brief is silent; any one proven wrong re-scores the register):

- **A1.** Stack is a web front end over a backend API; the split arithmetic, charge orchestration and refund live in the backend, not in the browser.
- **A2.** The feature ships behind a feature flag that is off by default in production. Off must equal today's checkout.
- **A3.** The customer can either type the first-card amount or choose an even split. The remainder-cent rule applies to even splits of odd totals; a typed amount is used as typed.
- **A4.** Valid first-card amounts are 1 cent to total minus 1 cent inclusive; each card must carry at least 1 cent. Zero and the full total are rejected (otherwise it is a single-card order).
- **A5.** The first charge is captured, not merely authorized, so "refund" is a PayGate refund call. If it is a void of an authorization instead, the same cases apply with the refund call renamed.
- **A6.** Outside sandbox days, the developers provide a PayGate stub whose responses are recorded from the sandbox on 2026-10-27. No such stub exists today (project risk R13).
- **A7.** The PayGate sandbox offers test cards for approve, decline and timeout, and accepts refunds. It cannot force a refund to fail; that path is tested against the stub only.
- **A8.** A single currency with two decimal places; all amounts are integer cents end to end.
- **A9.** A company test card can place one real low-value order in production for the post-release sanity check, with Finance's agreement.
- **A10.** Card data is tokenized by PayGate; the application never holds a card number, so PCI scope is unchanged.

Constraints:

- PayGate sandbox available only on Tuesdays and Thursdays: four windows, the last one the day before release.
- One tester at half time: 10 days × 4 h = 40 person-hours for all system-level testing, analysis and reporting.
- Two developers build the feature and own component and component integration testing.
- Fixed release date 2026-11-06; no slack after the last sandbox window.
- Single-card checkout must keep working; it is the revenue path.

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :-- | :-- | :-- | :-- |
| Product Owner | N/A — name not given; assumed one PO exists | Accepts the decision table on day 1, signs off exceptions, decides go/no-go | Owns the acceptance test on 2026-11-05 and every P1 exception |
| Developer A | N/A — name not given | Backend orchestration, refund, idempotency, unit and integration tests | Builds the PayGate stub; author of the code under test |
| Developer B | N/A — name not given | Checkout UI, amount validation, flag wiring, unit tests | Reviews Developer A's tests (some independence) and vice versa |
| Tester | N/A — name not given | Test plan, cases, sandbox sessions, regression, exploratory, reports | Holds both the test management role and the testing role |
| PayGate support contact | N/A — not named; assumed reachable by email | Sandbox credentials, test card list, decline codes | Needed before 2026-10-27; a missing contact blocks the first window |
| Operations / on-call | N/A — not named | Receives refund-failure alerts in production | Confirms the alert for R01 reaches a person |
| Finance | N/A — not named | Reconciliation of charges and refunds | Reads the daily reconciliation report; agrees to A9 |

## 4. Communication

| Form | Frequency | Content | Template |
| :-- | :-- | :-- | :-- |
| Daily stand-up | Every working day | Blockers, build ready for QA or not, sandbox readiness | Verbal |
| Progress report | After each sandbox window (Tue, Thu) and on Friday 2026-10-30 | Period, gate cases run / passed, refund timings measured, defects by severity, risks re-scored, next window's plan | Progress report format of the package's test reporting reference, posted on the ticket |
| Defect reports | As found | DR-SPLIT-NNN with build, environment, flag state and PayGate mode (sandbox or stub) | `/qa-defect` format |
| Completion report | 2026-11-05 evening, finalized 2026-11-06 morning | Every case one per row, "Not run — resume point", unmitigated risks, go/no-go evidence | Completion report format of the package's test reporting reference |
| Retrospective | Week of 2026-11-09 | Three questions of CTFL §2.1.6, actions with owner and date | Whole team, 45 minutes |

Test cases follow the package's TC-CODE-NNN format (`/qa-cases`), codes TC-SPLIT-NNN for the feature and TC-CHK-NNN for single-card regression.

## 5. Risk register

Score = Likelihood (1–5) × Impact (1–5). CRITICAL 15–25, HIGH 8–14, MEDIUM 4–7, LOW 1–3.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | R01 | Second card declined but the first charge is not refunded, or refund takes longer than 60 s: customer charged with no order | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests at unit level (all transitions); gate cases G03 and G08; refund elapsed time measured on every sandbox run; retry with backoff and an alert to on-call when the refund fails; daily reconciliation report to Finance | Dev A / Tester |
| 2 | R02 | Duplicate charges on retry, double submit or reload, or when the second charge times out with an unknown outcome and is retried | Product | 3 | 5 | 15 | 🔴 CRITICAL | Idempotency key per checkout attempt and per charge; gate case G06; decision table column for timeout (not treated as a decline); error guessing session on retries | Dev A / Tester |
| 3 | R03 | Single-card checkout breaks (4,000 orders a day) | Product | 2 | 5 | 10 | 🟠 HIGH | Feature flag off path tested as today's behaviour; existing single-card automated regression suite in CI on every push; gate case G07; canary enablement of the flag after release | Dev B / Tester |
| 4 | R04 | Split arithmetic wrong: cents do not sum to the total, remainder cent on the second card, float rounding | Product | 3 | 4 | 12 | 🟠 HIGH | Unit tests with BVA on odd and even totals and on the boundaries of A4; branch coverage of the split function at 100%; gate case G02 | Dev A |
| 5 | R05 | Gateway timeout on the second charge treated as a decline: first charge refunded while the second actually went through | Product | 2 | 5 | 10 | 🟠 HIGH | Decision table rules for timeout: query charge status before deciding; integration test against the stub's timeout response; sandbox timeout test card if A7 holds | Dev A / Tester |
| 6 | R06 | Crash or session loss between the two charges (browser closed, server restart) leaves a half-paid order | Product | 2 | 5 | 10 | 🟠 HIGH | Payment state persisted before the second charge; a recovery job finishes or refunds orphaned first charges; integration test that kills the flow after charge 1; exploratory charter | Dev A / Tester |
| 7 | R07 | Amounts tampered client-side (first-card amount or total altered in the request); card data written to logs | Product | 2 | 5 | 10 | 🟠 HIGH | Server recomputes the second amount from the order total, never from the client; API test sending altered amounts; log review for PAN or CVV after a sandbox run; security checklist in item 6 | Dev A / Tester |
| 8 | R08 | Amount validation gaps: 0, negative, more than total, non-numeric, three decimals, pasted thousands separators | Product | 3 | 3 | 9 | 🟠 HIGH | EP and BVA cases at API and UI level; gate case G05; unit tests by Dev B | Dev B / Tester |
| 9 | R09 | First card declined but the second is still attempted, or an order record is left behind | Product | 2 | 4 | 8 | 🟠 HIGH | Decision table rules; gate case G04 | Dev A / Tester |
| 10 | R10 | Two sequential gateway calls double checkout latency; the UI shows nothing for several seconds and customers resubmit | Product | 2 | 3 | 6 | 🟡 MEDIUM | Latency of the two-charge flow measured on each sandbox run and compared with single-card; progress indicator and disabled submit button checked in exploratory session; ties into R02 | Dev B / Tester |
| 11 | R11 | Order confirmation page, email and receipt show the split incorrectly | Product | 2 | 2 | 4 | 🟡 MEDIUM | Checked in the happy-path gate case and in exploratory session 1 | Tester |
| 12 | R12 | PayGate sandbox only on Tue and Thu: four windows, the last one the day before release; a lost window cannot be recovered | Project | 4 | 4 | 16 | 🔴 CRITICAL | Window 1 used to obtain credentials, test cards and recorded responses for the stub; every stub run is a dry run that prepares a sandbox run; fixes after 2026-11-05 keep the flag off in production until the next window (2026-11-10); control directive recorded in item 6 | Tester / PO |
| 13 | R13 | No PayGate stub exists, so nothing can be tested on Mon, Wed and Fri until one does | Project | 3 | 3 | 9 | 🟠 HIGH | Dev A builds the stub from the 2026-10-27 recordings by 2026-10-28; the stub's responses are versioned (item 9) | Dev A |
| 14 | R14 | Feature not ready for QA before the third window (2026-11-03), leaving one window for everything | Project | 3 | 4 | 12 | 🟠 HIGH | Vertical slice (both charges, no UI polish) delivered by 2026-10-29; entry criteria checked daily; if missed, PO decides on 2026-11-02 whether to move the release | Dev A / PO |
| 15 | R15 | Sandbox behaviour differs from production (refund latency, decline codes, forced refund failures not available) | Product | 3 | 3 | 9 | 🟠 HIGH | Decline-code mapping reviewed against PayGate documentation; refund-failure path tested on the stub; canary with the refund alert and reconciliation report as production monitoring | Dev A / Ops |
| 16 | R16 | Tester at half time cannot execute all planned cases plus reporting in 40 h | Project | 4 | 3 | 12 | 🟠 HIGH | Estimate in item 7 with a cut list agreed in advance; developers run retests on the stub; gate cases always run first | Tester / PO |

Monitoring: the register is re-read at every progress report; a row is re-scored in place with a dated note when its facts change (never deleted).

## 6. Test approach

### 6.1 Test levels, who tests and independence

| Level | Test object | Who tests | Degree | Why it fits the risk |
| :-- | :-- | :-- | :-- | :-- |
| Component | Split function, validation, payment state machine, idempotency key logic | Developer who wrote it, tests reviewed by the other developer in the PR | Some | Arithmetic and state logic are cheapest to cover here; the peer review is the independence; the tester reads the branch coverage report of the split and state modules (floor 100% branches, below it the uncovered branch is read before the PR merges) |
| Component integration | Orchestration against the PayGate stub, persistence between charges, refund retry | Developer A, reviewed by Developer B; tester reviews the decision table coverage of the integration tests | Some | The stub's recorded responses come from the tester's sandbox session, which gives the tests an oracle independent of the author's belief |
| System and system integration | Checkout on Staging with the real PayGate sandbox on Tue/Thu, the stub on other days | Tester | Some (same team as the authors; the highest degree available) | The risk level of R01 and R02 would justify High; it is not available with one tester, so the decision table and the gate results are also reviewed by the PO, who has no stake in the implementation |
| Acceptance | Gate run on 2026-11-05 observed by the PO; business rule check of the split and the refund message | Product Owner | Some (business representative) | Validation of the brief's intent, especially A3 and A4, which the tester assumed |

The tester holds both the test management role (this plan, monitoring, reports) and the testing role (cases, execution). Developers hold the testing role at their levels.

### 6.2 Test pyramid and quadrants

Preset: **Backend / API** (70% unit, 20% integration, 10% E2E). The business logic lives in the backend orchestration and arithmetic (A1); the checkout UI is a form. The existing single-card E2E suite is reused as is.

| Quadrant | What this plan puts there |
| :-- | :-- |
| Q1 | Unit tests on split arithmetic, validation and the state machine; integration tests against the stub, run in CI on every push |
| Q2 | TC-SPLIT cases from the decision table and BVA; an API test file for amount tampering; Gherkin scenarios for the four gate outcomes via `/qa-bdd` if time allows (cut list item) |
| Q3 | Two exploratory sessions (charters in 6.4); PO acceptance on 2026-11-05 |
| Q4 | Single-card `@smoke` suite; security checklist (6.4); latency measurement of the two-charge flow. No load test: no tool or environment in 10 days; recorded as a deviation in 6.9 |

### 6.3 Techniques by risk level

| Risk | Technique | Coverage items and target |
| :-- | :-- | :-- |
| R01, R05, R06, R09 (charge outcomes) | Decision table: conditions card 1 result {approved, declined, timeout} × card 2 result {approved, declined, timeout, not attempted}; actions place order, attempt charge 2, refund charge 1, query status, alert. Infeasible columns removed (card 2 attempted after card 1 declined) | Every feasible column exercised: 100% at integration level on the stub; the approved/declined columns also on the sandbox |
| R01, R06 (payment lifecycle) | State transition: Initiated → Card1Charged → Card2Charged → Completed; Card1Charged → Card2Declined → RefundPending → Refunded; RefundPending → RefundFailed → RefundRetry; Card1Declined → Failed | All transitions at unit level (money path treated as mission-critical, invalid transitions attempted one per case); valid transitions at system level |
| R04, R08 (amounts) | EP and 3-value BVA on the first-card amount: 0, 1, 2, total−2, total−1, total, total+1; odd totals 1, 3, 10,001; even total 10,000; invalid partitions non-numeric, negative, three decimals, separators | Every partition and every boundary item exercised; Each Choice for the amount × entry mode (typed, even split) |
| R02, R06, R10 | Error guessing: double submit, back button after charge 1, reload on the processing page, same card used twice, session expiry between charges, network drop after charge 2 request sent | Each item has one case or one exploratory note |
| R07 | Checklist (security): second amount recomputed server-side; total taken from the order, not the request; no PAN, CVV or token in application logs; idempotency key not guessable; rate limit on checkout unchanged | Every item answered yes or a defect filed |
| R03 | Regression: existing single-card suite plus one manual order with the flag off and one with the flag on; impact analysis limits manual scope to checkout, order confirmation and the payment record | Suite green on the release candidate build |
| R10, R11 | Exploratory sessions, 90 minutes each | Charter report with notes, defects, and coverage of the charter |

### 6.4 Exploratory charters

1. **Session 1 (2026-10-30, stub):** "Explore the split entry form and the confirmation page with odd totals, even split, and every invalid amount, to discover display and message defects." Targets R08, R10, R11.
2. **Session 2 (2026-11-04, stub):** "Explore interruptions between charge 1 and charge 2 (reload, back, close tab, expire session, slow network) to discover half-paid or double-charged states." Targets R02, R06.

### 6.5 Entry and exit criteria per level

| Level | Entry | Exit |
| :-- | :-- | :-- |
| Component | Decision table and state model agreed on 2026-10-26 | 100% branch coverage of split and state modules; all unit tests green in CI |
| Component integration | Stub available with versioned recordings (by 2026-10-28) | Every feasible decision table column has a green integration test |
| System and system integration | Build passed CI; deployed to Staging with a recorded SHA; flag state known; fixture set (6.7) present; sandbox credentials valid on the day; a `data-testid` on amount field, even-split control, submit button and outcome message | All gate cases pass on one sandbox-verified build; 100% P0 and P1 cases pass or each P1 failure has a PO exception; zero open Critical or High defects; measured refund time under 60 s on every decline run; single-card suite green on the same build |
| Acceptance | Gate passed on Staging | PO signs the completion report |

Running out of time ends testing only when the PO has reviewed the "Not run — resume point" section and accepted the residual risk in writing.

### 6.6 Release gate

Eight cases. A failure here blocks the release; findings outside this table inform and are filed as DR-SPLIT-NNN tickets.

| ID | What it proves | Risks | Where it runs | Result |
| :-- | :-- | :-- | :-- | :-- |
| G01 / TC-SPLIT-001 | Typed amount, both cards approved: two PayGate charges whose cents sum to the total, order placed, confirmation shows both charges | R04, R11 | Staging + sandbox | N/A — not yet run |
| G02 / TC-SPLIT-002 | Even split of an odd total (10,001 cents): first card 5,001, second card 5,000 | R04 | Staging + sandbox | N/A — not yet run |
| G03 / TC-SPLIT-003 | Second card declined: first charge refunded automatically, elapsed time under 60 s measured from the decline response, no order placed, customer told | R01 | Staging + sandbox | N/A — not yet run |
| G04 / TC-SPLIT-004 | First card declined: second card never charged, no refund issued, no order record | R09 | Staging + sandbox | N/A — not yet run |
| G05 / TC-SPLIT-005 | Amount boundaries: 1 and total−1 accepted; 0, total and total+1 rejected at API and UI | R08 | Staging + stub (validation is pre-gateway) | N/A — not yet run |
| G06 / TC-SPLIT-006 | Resubmitting the same checkout (double submit, reload) creates no additional charge on either card | R02 | Staging + sandbox | N/A — not yet run |
| G07 / TC-CHK-001 | Single-card checkout unchanged: automated suite green on the release build, plus one manual order with flag off and one with flag on | R03 | Staging, CI | N/A — not yet run |
| G08 / TC-SPLIT-007 | Refund call fails: retry succeeds or an alert reaches on-call and the reconciliation entry is written | R01, R15 | Staging + stub only (A7) | N/A — not yet run |

**Execution order** (risk-based, with the resource window and dependencies overriding):

1. G07 automated part runs in CI on every push from day 1, before anything else, because the single-card suite is already automated and R03 needs no sandbox.
2. G05 on the stub on 2026-10-30, because validation needs no gateway and must pass before sandbox time is spent on invalid input.
3. G08 on the stub on 2026-10-30, because the sandbox cannot force a refund failure (A7).
4. G03 first in every sandbox window (2026-10-29, 2026-11-03, 2026-11-05), because R01 is the highest product risk and the refund timer needs the real gateway.
5. G06 second in the sandbox, because R02 is CRITICAL and idempotency against the real gateway is the only proof.
6. G01 third in the sandbox; G02 right after it, since G02 reuses G01's customer and cart fixture (dependency).
7. G04 last in the sandbox, lowest score of the sandbox cases.
8. G07 manual part on 2026-11-02 and again on the release candidate on 2026-11-05, after the flag-on gate cases, because it must run on the same build the gate passed on.

Control directive recorded in advance: any code change merged after the 2026-11-05 window means the flag stays off in production until the gate is re-run in the next sandbox window (2026-11-10), unless the PO records an exception. The code can still deploy on 2026-11-06 with the flag off.

### 6.7 Test data and environment

Fixture set (one document, kept with the cases):

| Record | State assumed | May tests write to it | Rebuild |
| :-- | :-- | :-- | :-- |
| PayGate sandbox test cards: approve, decline (insufficient funds), decline (do not honour), timeout | As PayGate documents them; credentials in the team vault, never in the cases | Read only | From PayGate documentation |
| Customer SPLIT-CUST-01 on Staging with an address and an empty cart | Empty cart before each case; a case empties it after | Write (cart only) | Script `seed-split-customer` (to be written by Dev B, assumption) |
| Products P-ODD (10,001 cents) and P-EVEN (10,000 cents) | Published, in stock | Read only | Same seed script |
| Feature flag `split_payment` | Off on Staging except during a split run; the run records the state it set and restores it | Write, logged | Flag admin screen |
| Stub recordings v1 (2026-10-27) | Versioned with the code | Read only | Re-record in a sandbox window |

Environments: Dev (stub only), Staging (sandbox on Tue/Thu, stub on other days; PayGate mode is recorded in every result), Production (flag off at deploy, canary afterwards). CI runs unit and integration tests on every push; the single-card E2E suite on every push to main. Sandbox-dependent E2E cases cannot run in CI on every push; they run as a scripted run by the tester in the windows, and are not reported as automated.

### 6.8 Metrics

| Metric | Decision it answers |
| :-- | :-- |
| Gate cases run / passed, per build and PayGate mode | Is the build releasable on 2026-11-06 |
| Refund elapsed time on every decline run (max must be under 60 s) | Does R01 hold against the real gateway |
| Open defects by severity, and retests pending | Can the exit criteria be met before the last window |
| Risk coverage: register rows with at least one executed case | Which risks are still untested before each window |
| Sandbox windows used as planned / lost | Trigger for the PO decision in R14 |
| Tester hours spent against the estimate in item 7 | When to apply the cut list |

### 6.9 Deviations from the test policy and strategy

- No load or performance test beyond a latency measurement (no tool, no environment, 10 days).
- Sandbox cases run manually outside CI, on fixed days, instead of in the nightly job.
- One gate case (G08) is proven on a stub only; residual risk recorded in the completion report and covered by the production refund alert and reconciliation report.
- Independence at system level is "some", not "high"; compensated by PO review of the decision table and the gate results.

**Deliverables:** this plan; decision table and state model; TC-SPLIT and TC-CHK cases; fixture set; exploratory session reports; DR-SPLIT defect reports; progress reports after each window; completion report; retrospective actions.

## 7. Estimate

Technique: **three-point estimation** (one estimator, margin of error must be shown; no history for a split-payment feature in this organization is assumed). Tester effort only; developers' testing is part of their build effort, assumed at roughly a 3:2 development-to-test ratio inside their own days.

| Task | a (h) | m (h) | b (h) |
| :-- | :-- | :-- | :-- |
| Analysis and design: decision table, state model, BVA sets, cases, fixture set | 6 | 8 | 12 |
| Stub-based dry runs on Staging (Mon, Wed, Fri) | 4 | 6 | 9 |
| Three sandbox sessions incl. preparation and refund timing | 10 | 12 | 15 |
| Single-card regression (suite trigger, manual flag-off and flag-on orders, twice) | 3 | 4 | 6 |
| Two exploratory sessions with session reports | 3 | 4 | 6 |
| Defect reports, retests, progress and completion reports | 3 | 5 | 8 |
| **Total** | **29** | **39** | **56** |

E = (29 + 4×39 + 56) / 6 = 40.2 h; SD = (56 − 29) / 6 = 4.5 h. Reported as **40 ± 4.5 person-hours (between 36 and 45)** against 40 available.

Assumptions behind the figure: the vertical slice is testable by 2026-10-29 (R14); the stub exists by 2026-10-28 (R13); the sandbox credentials arrive before 2026-10-27; no more than two High defects need a sandbox retest. The pessimistic case exceeds capacity by 5 hours; the agreed cut list, in order, is: Gherkin scenarios, exploratory session 2 (its charter moves to a developer), then the API tampering test is run by Developer B with the tester reviewing the evidence. The PO records which cuts were taken.

## 8. Budget and schedule

Budget: 40 tester hours; developer test effort within the feature's build; no tool purchase; no sandbox cost assumed. Any PayGate sandbox fee is N/A — not stated in the brief.

| Day | Date | Sandbox | Tester (≈4 h) | Developers |
| :-- | :-- | :-- | :-- | :-- |
| 1 | Mon 2026-10-26 | No | Review of the brief with the team (assumptions A1–A10 confirmed or corrected), decision table and state model agreed, PayGate contact chased | Start build; unit tests on split arithmetic |
| 2 | Tue 2026-10-27 | Yes | Window 1: credentials, test cards, decline codes, refund latency, timeout behaviour; responses recorded for the stub | Build continues |
| 3 | Wed 2026-10-28 | No | Cases written; fixture set; `data-testid` list given to Dev B | Stub delivered from the recordings (R13) |
| 4 | Thu 2026-10-29 | Yes | Window 2: G03, G06, G01, G02, G04 on the vertical slice if ready; otherwise sandbox decline-code checks against the decision table | Vertical slice on Staging (R14) |
| 5 | Fri 2026-10-30 | No | Entry criteria checked; G05 and G08 on the stub; exploratory session 1; progress report 1 | Fixes; idempotency and refund retry |
| 6 | Mon 2026-11-02 | No | G07 manual part (flag off, flag on); retests on the stub; PO checkpoint on R14 | Fixes |
| 7 | Tue 2026-11-03 | Yes | Window 3: full sandbox gate run on Staging; refund timings; progress report 2 | Fixes from the run |
| 8 | Wed 2026-11-04 | No | Retests on the stub; exploratory session 2; security checklist and log review; latency comparison | Release candidate cut |
| 9 | Thu 2026-11-05 | Yes | Window 4: gate run on the release candidate with the PO present; G07 repeated on the same build; completion report drafted | Code freeze after the run |
| 10 | Fri 2026-11-06 | No | Go/no-go on the completion report; deploy with flag off; sanity on production; canary plan handed to Ops | Deploy; monitor |

Canary after release (non-test measure for R01, R03, R15): flag on for 5% of checkouts, watched signals are the refund-failure alert, charge error rate, checkout conversion and reconciliation mismatches; any refund failure not recovered within 60 s halts the rollout and Ops turns the flag off.

## 9. Configuration management of testware

- All testware (this plan, decision table, cases, fixture set, stub recordings, session reports, reports) lives in the product repository under a `docs/qa/5.3-split-payment` folder (assumed location) and is versioned with the code; each item carries its ID and version in its front matter.
- Every result names the build SHA, the environment, the feature flag state and the PayGate mode (sandbox or stub recording version). A result without all four is not recorded.
- The Staging environment baseline for the gate is recorded on 2026-11-05: application SHA, stub version, flag value, PayGate sandbox API version; it changes only through the PO-approved freeze exception.
- The 2026-11-03 baseline is kept so its results can be reproduced if the 2026-11-05 run differs.
- Unit and integration tests run in the CI pipeline, which records the SHA and run ID for each result; sandbox runs are linked from the ticket to the same SHA.
- Corrections to this plan after it is shared are made in place with a dated, attributed note or a strike-through with a reason; nothing is deleted.
