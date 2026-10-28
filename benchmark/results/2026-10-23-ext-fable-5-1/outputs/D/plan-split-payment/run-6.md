# Test Plan: Split Payment (Release 5.3)

**Document ID:** TP-SPLIT-5.3 · **Version:** 1.0 · **Date:** 2026-10-25 · **Author:** QA (test management and testing roles) · **Status:** Draft for review

## 1. Context of Testing

**Scope, in:**

- Split of one order across two cards: first-card amount chosen by the customer, remainder on the second card, integer cents, remainder cent to the first card.
- Two sequential PayGate charges and the automatic refund of the first charge when the second is declined, within 60 seconds.
- Order, receipt and payment-record consistency after a split payment (paid, refunded, failed).
- Server-side validation of the split amounts and protection against client-side tampering.
- Regression of the existing single-card checkout (about 4,000 orders a day).

**Scope, out:**

- More than two cards, saved-card wallets, instalments, or splitting across non-card methods: not in the brief.
- Refund of a *completed* split order after the fact (customer-service refunds): existing behavior, covered only by one regression check that a split order can still be refunded manually.
- Load and soak testing of PayGate: the sandbox is shared and time-boxed; a latency check on the two-call sequence replaces it (see item 6, Q4).
- Chargebacks, disputes and PayGate's reporting portal: outside the team's control.

**Objectives:**

1. Show that no customer can be left charged without an order, or charged twice, for any combination of PayGate outcomes on the two charges.
2. Show that the split arithmetic is exact in cents for all boundaries, including the remainder-cent rule.
3. Show that the single-card checkout behaves exactly as before the change.
4. Give the release decision on 2026-11-06 a written record of what passed, what did not run, and what risk remains.

**Test basis:** the feature brief above; PayGate API documentation (charge, refund, idempotency key, sandbox test cards and decline codes); the existing single-card checkout test cases and automated suite; the order payment state model in the codebase; PCI DSS SAQ scope the team already operates under.

## 2. Assumptions and Constraints

**Assumptions** (each one stated because the brief does not settle it):

- A1. Today is Sunday 2026-10-25. The ten working days are 2026-10-26 to 2026-11-06, and the release is Friday 2026-11-06.
- A2. The PayGate sandbox windows inside that period are Tue 2026-10-27, Thu 2026-10-29, Tue 2026-11-03 and Thu 2026-11-05. "Available on Tuesdays and Thursdays" means the full working day.
- A3. The split arithmetic rule means: the customer may enter an exact first-card amount, or choose a proportional split (for example "half and half"); when a proportional split yields a fractional cent, the extra cent goes to the first card. If the UI offers only an exact amount, the remainder-cent cases become unit tests of the shared rounding helper and the proportional gate case is marked `N/A`.
- A4. Split payment ships behind a feature flag. Flag off is the production state until the release decision, and is the rollback.
- A5. Charges are sequential: card 1 first, then card 2. A declined card 1 means card 2 is never attempted.
- A6. The backend calls PayGate with an idempotency key per charge, and PayGate's sandbox supports forcing a decline, a timeout and a refund failure through documented test cards or amounts. If it does not, risk R16 becomes an issue and the stub carries those paths.
- A7. The existing single-card checkout has an automated regression suite that runs in CI against a PayGate stub, plus a live sandbox smoke. If it does not, the first sandbox window includes recording responses to build one.
- A8. Orders are single-currency, two-decimal. Minimum order total is 0.01; maximum is the checkout's existing maximum (assumed 999,999.99). Minimum charge per card is PayGate's minimum (assumed 0.01).
- A9. The test environment is a staging deployment of the checkout that can target PayGate sandbox or a local PayGate stub by configuration.
- A10. Developers own component and component integration tests and pay for them out of their own build time; the tester's half-time is spent on design, system-level execution, defect handling and reporting.

**Constraints:**

- C1. Live gateway behavior can be observed only on four days. Anything not proven on 2026-11-05 cannot be proven live before release.
- C2. One tester at half time: about 40 hours in total, roughly 4 hours per working day.
- C3. The release date is fixed by the brief; scope and the flag state are the variables, not the date.
- C4. The single-card flow must not regress; 4,000 orders a day means a defect reaches thousands of customers before a rollback.

## 3. Stakeholders

| Role | Who (assumed) | Responsibility | Relevance to testing |
| :--- | :--- | :--- | :--- |
| Product Owner | PO for checkout | Accepts the feature, owns exceptions to exit criteria, decides go/no-go | Runs acceptance cases on 2026-11-05; signs the completion report |
| Developers (2) | Feature pair | Build the feature, write unit and integration tests, build the PayGate stub, fix defects | Hold the testing role at component and component integration level |
| Tester (1, half time) | QA | Test management role (this plan, monitoring, reporting) and testing role at system level | Designs cases, runs sandbox sessions, files defects, writes reports |
| PayGate integration contact | Vendor support | Confirms sandbox test cards, decline codes, refund latency | Needed before the first sandbox window; blocks R16 if silent |
| Payments operations / Finance | Reconciliation owner | Reconciles charges and refunds against orders | Reviews the refund-failure path and the ledger output of split orders |
| Customer support lead | Support | Receives customer complaints after release | Reviews the customer-facing messages for a declined second card |

## 4. Communication

| Form | Frequency | Content | Template |
| :--- | :--- | :--- | :--- |
| Stand-up | Daily, 10 min | Blockers, which sandbox cases are queued for the next window | N/A — verbal |
| Progress report | End of each sandbox day (10-27, 10-29, 11-03, 11-05) | Gate table with results per build, defects by severity, risk changes, next window's queue | Progress report, `qa-reference` test-reporting |
| Defect reports | As found | DR-SPLIT-NNN with severity, steps, build, flag state, PayGate request IDs | `/qa-defect` |
| Register review | At each progress report | Re-scored rows with dated notes | This document, item 5 |
| Completion report | 2026-11-05 evening, updated 11-06 if a fix lands | Every case one per row, "Not run — resume point", residual risks | Completion report, `qa-reference` test-reporting |
| Go/no-go record | 2026-11-06 morning | Evidence per gate case and exit criterion, exceptions, open defects | `/qa-release` |
| Retrospective | Within 5 working days after release | What to keep, what to change, actions with owners | Retrospective, `qa-reference` test-reporting |

Channel for all of the above: the team chat channel for release 5.3 and the tracker epic for split payment (assumed to exist; the plan links to it once the ID is known).

## 5. Risk Register

Scale: Likelihood 1–5, Impact 1–5, Score = L × I. Levels: 15–25 CRITICAL, 8–14 HIGH, 4–7 MEDIUM, 1–3 LOW.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| :-- | :-- | :--- | :--- | :-: | :-: | :-: | :--- | :--- | :--- |
| 1 | R01 | Second charge declined and the first charge is not refunded, or is refunded after 60 s: customer pays with no order | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests on the payment state machine (integration, stub); gate case G03 live on sandbox with timing captured from PayGate timestamps; refund-failure path alerts ops (G03b in analysis set) | Dev / QA |
| 2 | R02 | Split arithmetic wrong: cents do not sum to the total, remainder cent on the wrong card, float rounding | Product | 3 | 5 | 15 | 🔴 CRITICAL | 3-value BVA and EP unit tests on the integer-cent helper; property test that card1 + card2 = total for random totals; gate cases G01, G02 | Dev |
| 3 | R03 | Single-card checkout regresses (4,000 orders/day) | Product | 2 | 5 | 10 | 🟠 HIGH | Feature flag (A4) with flag-off tested as today's behavior; existing automated regression on every build; gate case G06 live on sandbox; post-release sanity | Dev / QA |
| 4 | R04 | Duplicate charge on retry after a PayGate timeout or on double-submit | Product | 3 | 5 | 15 | 🔴 CRITICAL | Idempotency key per charge verified in integration tests with a stub that times out then succeeds; gate case G05 live; code review of retry logic | Dev / QA |
| 5 | R05 | First card declined but second card is still charged, or order left half-paid | Product | 2 | 4 | 8 | 🟠 HIGH | Decision table rule 4 at integration level; gate case G04 live | Dev / QA |
| 6 | R06 | Amount validation gaps: first-card amount 0, equal to total, above total, negative, fractional cent, below PayGate minimum, same card twice | Product | 4 | 3 | 12 | 🟠 HIGH | EP and 2-value BVA cases at unit and API level; gate case G07 for the overcharge boundary; the rest in the analysis set | Dev / QA |
| 7 | R07 | Refund call fails or is asynchronous at PayGate, so the 60 s target is missed or the refund is silently lost | Product | 3 | 4 | 12 | 🟠 HIGH | Confirm refund semantics with PayGate contact before 10-27; retry with backoff and an ops alert; analysis case measuring refund latency over 10 runs on sandbox | Dev / Ops |
| 8 | R08 | Customer closes the browser or double-submits between charge 1 and charge 2, leaving a partial state | Product | 3 | 4 | 12 | 🟠 HIGH | Server-side orchestration independent of the client session; integration test that kills the client mid-flow; exploratory charter on sandbox day 3 | Dev / QA |
| 9 | R09 | Receipt, order history or ledger shows one charge, wrong amounts, or a refund not linked to the order; reconciliation breaks | Product | 3 | 3 | 9 | 🟠 HIGH | Analysis cases checking receipt, order record and ledger export after G01, G02, G03; Finance reviews one real sandbox export | QA / Finance |
| 10 | R10 | Client can tamper with the first-card amount or the total; two card tokens widen PCI exposure | Product | 2 | 5 | 10 | 🟠 HIGH | Server recomputes card-2 amount from the stored order total; gate case G08 sends a tampered request via API; security checklist (tokens never logged, no PAN in requests) | Dev / QA |
| 11 | R11 | Two sequential gateway calls double checkout latency; timeouts tuned for one call fire on the second | Product | 2 | 3 | 6 | 🟡 MEDIUM | Timing captured on every sandbox gate run; timeout values reviewed; no load test (out of scope, see item 6) | Dev |
| 12 | R12 | Flag-off path differs from pre-change behavior because shared checkout code was refactored | Product | 2 | 4 | 8 | 🟠 HIGH | Impact analysis of the diff on shared modules; regression suite run with flag off on every build | Dev / QA |
| 13 | R13 | Sandbox available only on 4 days: a window lost to a broken build or an unready feature removes 25% of live test time | Project | 4 | 4 | 16 | 🔴 CRITICAL | Window 1 used for a gateway spike that needs no feature build; stub built from window-1 recordings for all other days; a queue of sandbox cases prepared the day before each window; control directive in item 6 for fixes landing after 11-05 | QA |
| 14 | R14 | Tester half-time capacity (about 40 h) is below the pessimistic estimate (44 h) | Project | 3 | 4 | 12 | 🟠 HIGH | Developers own all unit and integration execution; analysis set ordered by risk so the tail can be dropped with a recorded exception; PO pre-agrees the drop list | QA / PO |
| 15 | R15 | Feature not "Ready for QA" before window 2 (10-29), leaving two live windows for gate, fixes and retest | Project | 3 | 4 | 12 | 🟠 HIGH | Entry criteria relaxed for window 2 to "deployed behind flag, happy path works"; devs commit to a 10-28 deploy; otherwise the schedule shifts to the contingency in item 8 | Dev lead |
| 16 | R16 | Sandbox cannot force a decline, timeout or refund failure, so R01 and R04 cannot be proven live | Project | 3 | 4 | 12 | 🟠 HIGH | Ask the PayGate contact on 10-26; verify on window 1; if unsupported, those paths are proven on the stub and the register records the residual risk as accepted by the PO | QA / PO |
| 17 | R17 | No PayGate stub exists, so nothing gateway-related can run on 6 of the 10 days | Project | 3 | 3 | 9 | 🟠 HIGH | Devs build a stub on 10-26 and 10-27 from PayGate docs and window-1 recordings; contract check of stub against recordings | Dev |

Risk control: each sandbox-day progress report re-scores rows whose facts changed, with a dated note; a risk that becomes an issue reprioritizes the next window's queue.

## 6. Test Approach

**Where the logic lives:** in the backend orchestration and arithmetic, with a thin checkout UI. Preset: **Backend / API: 70% Unit · 20% Integration · 10% E2E.** The sandbox constraint reinforces this: everything that can be proven below system level is, so the four live windows are spent only on what needs the real gateway.

### Test levels, who tests, and independence

| Level | Test object | Techniques | Who tests | Independence | Why that degree |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Component | Cent-split helper, amount validator, idempotency key builder | 3-value BVA, EP, property test (sum invariant), branch coverage ≥ 80% on the helper and orchestrator | Author developer, peer-reviewed by the other developer | None, raised to Some by review | Arithmetic defects are cheap to find here and the developers know the code; QA reviews the BVA table so the boundaries are not the author's own guess |
| Component integration | Orchestrator with PayGate stub: charge 1 → charge 2 → refund, timeouts, retries, client disconnect | Decision table (below), state transition (valid transitions, plus invalid ones attempted one per case), error guessing on timeouts | Developers write and run; QA reviews the decision table and state table for completeness | Some | The interaction defects (R01, R04, R05) show here first; QA's review of the tables is the independent view, since QA cannot spend hours in the integration suite |
| System and system integration | Deployed checkout against PayGate sandbox (Tue/Thu) and stub (other days) | Gate cases, API cases (tampering, boundaries), exploratory charters | Tester | Some (same team, not the author) | A higher degree is not available with this staffing; the money risk is offset by the PO acceptance step and by Finance reviewing the ledger output |
| Acceptance | Gate cases G01 and G03 on sandbox, customer-facing messages | Checklist of acceptance criteria | Product Owner, with Support lead reviewing messages | Business representative | Validates that a declined second card is explained in a way the customer accepts |

### Decision table for charge outcomes (integration level, every feasible column exercised)

| Condition / Action | Rule 1 | Rule 2 | Rule 3 | Rule 4 | Rule 5 | Rule 6 |
| :--- | :-: | :-: | :-: | :-: | :-: | :-: |
| Charge 1 result | OK | OK | OK | Declined | OK | Timeout |
| Charge 2 result | OK | Declined | Declined | N/A | Timeout | N/A |
| Refund of charge 1 result | – | OK ≤ 60 s | Fails | – | – | – |
| Order placed and paid | X | | | | | |
| Charge 2 attempted | X | X | X | | X | |
| Charge 1 refunded, customer told | | X | | | X after status query shows no charge 2 | |
| Order in "refund pending", ops alerted | | | X | | | |
| No duplicate charge after retry | | | | | X | X |
| Customer sees decline, nothing charged | | | | X | | X |

### Testing quadrants check

- **Q1** (technology, supports the team): unit and integration tests above, in CI on every push, flag on and flag off.
- **Q2** (business, supports the team): gate and analysis cases TC-SPLIT-NNN, API cases for tampering and boundaries, acceptance checklist.
- **Q3** (business, critiques the product): one 60-minute exploratory charter per sandbox window 3 and 4 ("abandon and retry between the two charges"; "what does the customer see and receive by email when card 2 declines"); PO acceptance on 11-05.
- **Q4** (technology, critiques the product): smoke suite per build; security checklist (tokens, logging, tampering); latency of the two-call sequence recorded on every sandbox gate run. No load test: the sandbox is shared and time-boxed, and the change adds one gateway call per order rather than new throughput. Residual risk is R11, MEDIUM, accepted.

### Deliverables

Test cases TC-SPLIT-NNN (gate and analysis, tagged), fixture set, PayGate stub recordings, defect reports DR-SPLIT-NNN, four progress reports, completion report, go/no-go record, retrospective actions.

### Entry criteria

| Level | Entry criteria |
| :--- | :--- |
| Component and integration | Helper and orchestrator merged to main behind the flag; stub available; CI green |
| System, sandbox window 2 (10-29) | Feature deployed to staging behind the flag; happy path works on the stub; sandbox decline codes confirmed; fixture set seeded; `data-testid` on the split form fields |
| System, windows 3 and 4 | Full "Ready for QA" state; build identified by commit and pipeline run; all CI suites green on that build, flag on and off |
| Acceptance | Gate cases G01 to G08 passed at least once on sandbox; customer messages final |

### Exit criteria (measured against the release gate)

- Every gate case passed on the release candidate build on sandbox, on 2026-11-05 or later.
- 100% of P0 analysis cases executed and passing; P1 failures each have a recorded PO exception.
- Zero open Critical defects; zero open High defects or a PO exception each.
- Single-card regression suite green with the flag off and with the flag on, on the release candidate.
- Residual risks (R07 timing, R16 if unsupported, R11) recorded in the completion report and accepted in the go/no-go record.
- Completion report signed by the tester and the PO.

If time runs out, testing stops only when the PO has reviewed the "Not run — resume point" list and accepted the risk of releasing without it, in writing in the go/no-go record.

### Release gate

| ID | What it proves | Risk | Needs | Result |
| :--- | :--- | :--- | :--- | :--- |
| G01 | Even split (10.00 → 5.00 / 5.00): both charges succeed, order paid, receipt and ledger show both | R02, R09 | Sandbox | N/A — not yet run |
| G02 | Odd-cent split (10.01 → 5.01 / 5.00): remainder cent on card 1, sum equals total | R02 | Sandbox | N/A — not yet run |
| G03 | Card 2 declined: card 1 refunded within 60 s (PayGate timestamps), order not placed, customer told | R01, R07 | Sandbox with decline card | N/A — not yet run |
| G04 | Card 1 declined: card 2 never charged, order not placed | R05 | Sandbox with decline card | N/A — not yet run |
| G05 | Charge 2 times out then retries: exactly one charge on card 2, no duplicate | R04 | Sandbox with timeout card, or stub if R16 is an issue | N/A — not yet run |
| G06 | Single-card checkout, flag on and flag off, unchanged end to end | R03, R12 | Stub in CI plus one live sandbox run | N/A — not yet run |
| G07 | First-card amount above the total, or second card below 0.01, is rejected server-side with no charge | R06 | Stub (API), confirmed once on sandbox | N/A — not yet run |
| G08 | Tampered request (client sends card-2 amount lower than remainder) is rejected; server recomputes from the stored total | R10 | Stub (API) | N/A — not yet run |

Findings not caused by this change are logged as their own defects and linked here; they do not gate. If an analysis finding proves to be caused by the change, its case moves into this table with a dated note.

### Execution order (risk-based, with overrides)

1. **G06 on stub, flag off** first on every build, before anything else: largest blast radius, and no sandbox needed. Resource override: it runs daily rather than waiting for a window.
2. **G01** at the start of each sandbox window: dependency override, since every other live case needs a working happy path to prove the environment and build.
3. **G03** (R01, score 15).
4. **G02** (R02, score 15).
5. **G05** (R04, score 15). Runs after G03 because the timeout card, if PayGate provides one, may leave a pending charge the tester must clear before the next cases.
6. **G08** then **G07** (R10, R06): stub on any day, one confirmation on sandbox.
7. **G04** (R05, score 8).
8. **G06 live** on sandbox, last in each window, so a gateway hiccup late in the day cannot block the critical cases above.
9. **Analysis cases** in register order, stub first, sandbox-only ones queued for the next window; the tail (R09 ledger detail, R11 latency) is the pre-agreed drop list under R14.

### Metrics to collect

- Gate cases passed / failed / not run per build and per window (answers: can we release?).
- Open defects by severity, daily (answers: do we need a fix window before 11-05?).
- Risk coverage: register rows with at least one executed case, per window (answers: what is still unproven live?).
- Sandbox utilization: hours used of 16 available (answers: is R13 becoming an issue?).
- Effort spent against the estimate in item 7, weekly (answers: does R14 trigger the drop list?).

**Control directive, recorded in advance:** a fix that changes gateway-facing code after the 2026-11-05 window cannot be verified live before 11-06. Either it ships with the flag off and is verified on Tue 2026-11-10, or the release of the split feature moves to 2026-11-10. The PO decides at go/no-go.

### Test data and environment

Fixture set (document kept with the cases; no credentials, pointer to the team vault):

| Record | State assumed | May be changed? | Rebuild |
| :--- | :--- | :--- | :--- |
| PayGate sandbox merchant account | Active, refunds enabled | Read only; charges are writes, voided at end of each window | Vendor contact; nobody on the team can |
| Sandbox test cards: success, decline, timeout, refund-fail | As documented by PayGate, verified on 10-27 | Read only | From PayGate docs |
| Orders O-001 (10.00), O-002 (10.01), O-003 (0.01), O-004 (0.02), O-005 (maximum total), O-006 (single-card baseline) | Unpaid, in staging catalogue | Written to by tests; reset by seed script after each window | Seed script in the repo |
| Flag `split_payment` | Off by default; on for split cases | Set per case and recorded in its precondition | Flag service |
| PayGate stub recordings from 10-27 | Versioned in the repo with the recording date | Read only | Re-record on the next window |

Environment: staging deployment, build identified by commit SHA and pipeline run; PayGate sandbox API version recorded in each result; stub version recorded when used.

**Deviations from test policy and strategy:** N/A — no organizational test policy or strategy was provided; this plan stands alone.

## 7. Estimate

Technique: **three-point estimation** (one estimator, margin of error required). E = (a + 4m + b) / 6, SD = (b − a) / 6, in tester hours.

| Task | a | m | b | E | SD |
| :--- | :-: | :-: | :-: | :-: | :-: |
| Static review of brief, test design (BVA table, decision table, state table, gate and analysis cases, fixture set) | 6 | 8 | 12 | 8.3 | 1.0 |
| Sandbox execution, 4 windows (gate runs, exploratory charters, timing capture) | 10 | 14 | 18 | 14.0 | 1.3 |
| Stub-based execution on non-sandbox days (API cases, regression runs, retests) | 4 | 6 | 10 | 6.3 | 1.0 |
| Single-card regression review and live run | 3 | 4 | 6 | 4.2 | 0.5 |
| Defect reports, retests, progress and completion reports, go/no-go record | 4 | 6 | 10 | 6.3 | 1.0 |
| **Total** | | | | **39 h** | **± 5 h** (SDs summed, conservative) |

Reported as **39 ± 5 tester hours (between 34 and 44)**, against about 40 hours available. The pessimistic end exceeds capacity, which is risk R14 and why the drop list exists.

Developer test effort, same technique, both developers combined: unit and integration tests plus stub, a = 12, m = 16, b = 24, giving **17 ± 2 hours (15 to 19)**.

Assumptions behind the figures: A2 (four full sandbox days), A6 (decline and timeout can be forced), A7 (a regression suite exists), A10 (developers own levels below system). If A6 fails, subtract about 3 sandbox hours and add 2 stub hours; if A7 fails, add 6 to 8 tester hours and the estimate no longer fits.

## 8. Budget and Schedule

Budget: N/A — no monetary budget was given; the effort in item 7 stands in for it. No tool purchase is needed.

| Day | Date | Sandbox | Tester (about 4 h) | Developers |
| :-- | :-- | :-: | :--- | :--- |
| 1 | Mon 10-26 | | Static review of the brief, ask PayGate contact about decline, timeout and refund semantics, start test design, fixture set | Build cent helper and validator with unit tests; start stub |
| 2 | Tue 10-27 | ✓ | **Window 1: gateway spike.** Verify test cards, refund latency, timeout behavior, idempotency on sandbox; record responses for the stub | Finish stub from recordings; orchestrator |
| 3 | Wed 10-28 | | Finish cases; review developers' BVA and decision tables; G06 on stub flag off | Integration tests; deploy to staging behind flag |
| 4 | Thu 10-29 | ✓ | **Window 2:** G01 to G06 on first build (relaxed entry); file defects | Fix on the spot where possible |
| 5 | Fri 10-30 | | Progress report review, retests on stub, G07 and G08 via API | Fixes; CI green flag on and off |
| 6 | Mon 11-02 | | Analysis cases on stub; prepare window-3 queue | Fixes; code review of retry logic |
| 7 | Tue 11-03 | ✓ | **Window 3:** full gate on release candidate 1, exploratory charter 1, latency capture | Fixes |
| 8 | Wed 11-04 | | Retests on stub, ledger review with Finance, completion report draft | Final fixes; RC2 tagged by end of day |
| 9 | Thu 11-05 | ✓ | **Window 4:** full gate on RC2, exploratory charter 2, PO acceptance of G01 and G03, completion report | Standby; no gateway-facing changes after this day |
| 10 | Fri 11-06 | | Go/no-go record; release with flag off, then flag on; post-release sanity with the company test card on production, voided (assumed allowed) | Release; monitor refund alerts and error rate |

Contingency: if R15 occurs and window 2 is lost, windows 3 and 4 carry the first and final gate runs with no live retest between them; the PO is told on 10-29 that a Critical defect found on 11-03 means either a flag-off release or a slip to 11-10.

## 9. Configuration Management of Testware

- This plan, the test cases, the fixture set, the stub and its recordings, and the reports live in the repository under the release 5.3 QA folder, versioned with the code; each is a configuration item with an ID (TP-SPLIT-5.3, TC-SPLIT-NNN, DR-SPLIT-NNN, FX-SPLIT-001, STUB-PAYGATE-<recording date>).
- Every result names the build (commit SHA and pipeline run), the environment (staging), the gateway (sandbox API version or stub recording date) and the flag state. A result without all four is not recorded.
- The staging environment with RC2 deployed, the sandbox merchant configuration and the flag values form the baseline for the release decision; changes after 2026-11-05 go through the control directive in item 6.
- Previous baselines (RC1) remain tagged so a result from window 3 can be reproduced.
- CI runs the unit, integration and regression suites on every push and records the run against the commit; the stub recordings are checked in and selected by date, never "the latest".
- Corrections to this plan after it is shared are made in place with a dated, attributed note; nothing is deleted.
