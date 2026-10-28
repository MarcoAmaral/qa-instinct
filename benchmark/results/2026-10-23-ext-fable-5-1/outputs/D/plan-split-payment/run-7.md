# Test Plan: Split Payment (Release 5.3)

| Field | Value |
| :--- | :--- |
| Plan ID / version | TP-SPLIT-5.3, v1.0, 2026-10-25 |
| Owner | Tester (test management role and testing role, one person) |
| Board | N/A — no tracker URL given; assumed Jira project PAY, epic PAY-530 |
| Release date | 2026-11-06 (Friday), 10 working days from 2026-10-26 |
| Environments | Local, Dev (PayGate simulator), Staging (PayGate sandbox on Tue/Thu; simulator otherwise), Production |

## 1. Context of Testing

**Test basis.** The feature brief for Split payment, decomposed into these requirements. The brief is the only source given; the IDs below are this plan's.

| Req | Statement |
| :--- | :--- |
| REQ-01 | A customer pays one order with two cards. |
| REQ-02 | The customer chooses the amount on card 1; card 2 takes the rest. |
| REQ-03 | Amounts are integers in cents. |
| REQ-04 | When the total cannot be split evenly, the remainder cent goes on card 1. |
| REQ-05 | Both charges go through PayGate. |
| REQ-06 | If the second charge is declined, the first charge is refunded automatically within 60 seconds. |
| REQ-07 | The existing single-card checkout keeps working (about 4,000 orders a day). |

**Objectives.**

- Show that a split order charges exactly the order total across the two cards, with the remainder cent on card 1.
- Show that a decline on card 2 leaves the customer with no net charge within 60 seconds.
- Show that single-card checkout behaves as before, with the feature flag on and off.
- Give the go/no-go decision a written record of what passed, what did not run, and the risks still open.

**In scope.**

| Area | Test levels | Priority |
| :--- | :--- | :--- |
| Split amount entry, validation, even-split control (REQ-02, REQ-03, REQ-04) | Component, system | P0 |
| Charge orchestration: card 1 then card 2, decline paths, timeout paths, idempotency (REQ-05, REQ-06) | Component integration, system integration | P0 |
| Automatic refund on card 2 decline, timed (REQ-06) | System integration | P0 |
| Server-side recomputation of card 2 amount; tampering via API | System (API) | P0 |
| Order state, receipt and order history showing two charges | System | P1 |
| Single-card checkout regression, flag on and flag off (REQ-07) | System, CI regression | P0 |
| Exploratory testing of the checkout UI with a split | System | P2 |

**Out of scope, and why.**

- Three or more cards: not in the brief.
- Saved cards, new payment methods, PayGate contract or API version changes: not changed by this release.
- Partial refunds issued later by support: existing behavior, not changed.
- Load or performance testing beyond timing the refund: no load environment, and 4,000 orders a day is within current capacity.
- Full accessibility audit: a half-time tester cannot fit it; a keyboard-only pass of the split form is part of exploratory session 1.
- Reconciliation and settlement reports in finance systems: verified by finance ops as acceptance, not by this plan's cases.

## 2. Assumptions and Constraints

**Constraints (given).**

- PayGate sandbox is available only on Tuesdays and Thursdays: 2026-10-27, 2026-10-29, 2026-11-03, 2026-11-05. Four windows in total.
- Release on 2026-11-06.
- One tester at half time, 40 hours over the 10 days, plus two developers who build the feature.
- Single-card checkout must keep working.

**Assumptions (stated where the brief is silent).**

| ID | Assumption |
| :--- | :--- |
| A1 | Working days run Monday 2026-10-26 to Friday 2026-11-06; the release goes out on day 10. |
| A2 | The stack is a web checkout front end with a backend payment service that calls PayGate over a REST API. The split arithmetic and the refund orchestration live in the backend. |
| A3 | Outside sandbox days, PayGate is replaced by a local HTTP simulator owned by the developers, with scenarios selected by amount or by test card number. |
| A4 | The feature ships behind a feature flag, off by default in production, so release and enablement are separate decisions. |
| A5 | The amount on card 1 must be at least 1 cent and at most total minus 1 cent; anything else is a validation error. The UI also offers an "split evenly" control; for an odd total it puts the extra cent on card 1. |
| A6 | The 60 seconds are measured from PayGate's decline response on card 2 to PayGate's acceptance of the refund request, not to settlement. |
| A7 | Card 1 is charged first. If card 1 is declined, card 2 is never charged and the order is not placed. |
| A8 | Single currency; no currency conversion. |
| A9 | Tracker is Jira; test cases are TC-SPLIT-NNN and TC-SINGLE-RNN; defects are DR-SPLIT-NNN. |
| A10 | An automated regression suite for single-card checkout exists in CI. Verified on day 1; if false, risk R19 applies. |
| A11 | A timeout or unknown result on card 2 is resolved by a status query to PayGate before any refund is decided. The product owner confirms this on day 1. |
| A12 | Both charges and the refund carry idempotency keys so a retry cannot charge or refund twice. |
| A13 | PayGate sandbox offers test cards for approve, decline and, if available, timeout and refund failure. Confirmed on 2026-10-27. |
| A14 | The PayGate sandbox merchant account is shared with other teams. |
| A15 | Production verification after release uses a company card and a low-value order that is refunded afterwards, under an existing procedure. |

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :--- | :--- | :--- | :--- |
| Product owner | N/A — name not given | Confirms A5, A6, A11; accepts the feature; signs exceptions | Decides P1 exceptions and the go/no-go |
| Backend developer | Dev A (assumed) | Split arithmetic, orchestration, refund, idempotency; unit and integration tests; simulator | Tests at component and component integration level |
| Frontend developer | Dev B (assumed) | Split form, validation messages, even-split control; component tests | Tests the form at component level; adds `data-testid` attributes |
| Tester | One person, half time | Plan, design, sandbox sessions, API tests, exploratory, reporting, go/no-go record | Test management role and testing role |
| Finance operations | N/A — name not given | Confirms that two charges and a refund reconcile correctly | Acceptance on 2026-11-03 |
| Release manager / DevOps | N/A — name not given | Builds, deployments, feature flag, canary and rollback | Owns entry criterion "deployed and accessible" and the release day canary |
| PayGate account contact | N/A — name not given | Sandbox access, test cards, an extra window if asked | Project risk R14 |
| Customer support | N/A — name not given | Handles customers charged without an order | Receives the manual refund runbook from R01 |

## 4. Communication

| Form | Frequency | Content | Template |
| :--- | :--- | :--- | :--- |
| Stand-up | Daily, 10 minutes | Blockers, which gate cases are runnable today | None |
| Progress report | After each sandbox window (Tue/Thu, end of day), 4 in total | Period, progress against plan, impediments, metrics in item 6, new or re-scored risks, next period | Progress report, `qa-reference` test-reporting |
| Defect reports | As found | Severity, steps, expected vs actual, build, environment, flag state | DR-SPLIT-NNN via `/qa-defect` |
| Go/no-go meeting | 2026-11-05, after the last sandbox window | Gate table, exit criteria, exceptions, residual risks | Go/no-go record via `/qa-release` |
| Completion report | 2026-11-06, after release and post-release sanity | Every case one per row, "Not run — resume point", lessons learned | Completion report, `qa-reference` test-reporting |
| Retrospective | Week of 2026-11-09 | What to keep, what to change, actions with owners | Three questions, CTFL §2.1.6 |
| Chat channel | Continuous | Sandbox status, simulator changes, flag changes on staging | N/A — no template |

## 5. Risk Register

Score = Likelihood (1–5) × Impact (1–5). CRITICAL 15–25, HIGH 8–14, MEDIUM 4–7, LOW 1–3. Rows are re-scored at each progress report, with a dated note.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Card 2 declined but the refund of card 1 fails, is never sent, or takes longer than 60 s: customer charged with no order | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests at all-transitions coverage on the orchestration; integration test with simulator forcing decline then refund failure, with retry; timed sandbox run (TC-SPLIT-003) in windows 3 and 4; alert on refund failure plus a manual refund runbook for support; flag as kill switch | Dev A / Tester |
| 2 | R02 | Cent arithmetic wrong: the two charges do not sum to the total, the remainder cent lands on card 2, or floating point creeps in | Product | 3 | 5 | 15 | 🔴 CRITICAL | Unit tests with EP and BVA on integer cents; property test that card1 + card2 = total for every total tried; decision table custom/even × odd/even total; code review for integer-only arithmetic | Dev A |
| 3 | R03 | Double charge: a retry after a timeout charges the same card twice | Product | 3 | 5 | 15 | 🔴 CRITICAL | Idempotency keys (A12); integration test with simulated timeout then retry; sandbox run if PayGate can simulate a timeout (TC-SPLIT-006) | Dev A |
| 4 | R14 | Sandbox only Tue/Thu: four windows, and a defect found on 2026-11-05 cannot be re-verified on sandbox before release | Project | 4 | 4 | 16 | 🔴 CRITICAL | Simulator on all other days; full gate run on 2026-11-03 so 2026-11-05 is confirmation only; ask PayGate for one extra window; contingency: release with the flag off | Tester / Release manager |
| 5 | R07 | Timeout or unknown result on card 2 handled wrongly: refund issued although the charge succeeded, or no refund at all | Product | 3 | 4 | 12 | 🟠 HIGH | Confirm A11 with the product owner on day 1; status query before refund; integration tests for timeout then "succeeded" and timeout then "declined"; one sandbox attempt if PayGate supports it | Dev A / Product owner |
| 6 | R15 | Tester has 40 hours for the whole release | Project | 4 | 3 | 12 | 🟠 HIGH | Developers own unit and integration automation and the simulator; tester owns gate, sandbox sessions, API tests and exploratory; LOW items are exploratory only | Tester |
| 7 | R16 | Feature reaches staging late, leaving one sandbox window | Project | 3 | 4 | 12 | 🟠 HIGH | Entry deadline 2026-10-30 end of day; control directive if missed: release 5.3 with flag off, split in 5.3.1 | Product owner / Developers |
| 8 | R17 | Simulator disagrees with real PayGate (codes, decline reasons, refund latency), so simulator passes mean little | Project | 3 | 4 | 12 | 🟠 HIGH | Record real sandbox responses on 2026-10-27 against the current checkout and copy them into the simulator stubs; every mocked boundary gets at least one sandbox run | Dev A / Tester |
| 9 | R04 | Single-card checkout regresses: shared checkout code or payment service changed | Product | 2 | 5 | 10 | 🟠 HIGH | Impact analysis of changed modules on day 1; CI regression suite on every push; flag-off smoke on staging (TC-SINGLE-R01); canary at 5% with error-rate threshold and rollback | Dev B / Tester |
| 10 | R05 | Card 1 declined but card 2 is charged, or the order is left half paid | Product | 2 | 5 | 10 | 🟠 HIGH | Same state table as R01; TC-SPLIT-004 on sandbox | Dev A |
| 11 | R11 | Client sends a tampered card 2 amount so charges sum to less than the total; or card 2 bypasses tokenization | Product | 2 | 5 | 10 | 🟠 HIGH | Server recomputes card 2 = total − card 1 and rejects mismatches; API test with tampered body (TC-SPLIT-005); review that card 2 uses the same tokenized path as card 1 | Dev A / Tester |
| 12 | R06 | Validation boundaries wrong on the card 1 amount: 0, 1 cent, total − 1, total, total + 1, negative, three decimals, non-numeric | Product | 3 | 3 | 9 | 🟠 HIGH | 3-value BVA at unit level and at the UI; EP for invalid formats | Dev B / Tester |
| 13 | R09 | Receipt, order history or PayGate records show one charge, wrong amounts, or no refund | Product | 3 | 3 | 9 | 🟠 HIGH | Checklist with finance ops; after each sandbox split, compare order record, receipt and PayGate dashboard entry | Tester / Finance ops |
| 14 | R18 | Sandbox test cards for decline, timeout or refund failure unknown or shared with other teams | Project | 3 | 3 | 9 | 🟠 HIGH | Fixture set written on 2026-10-27; all QA orders tagged with prefix QA53- | Tester |
| 15 | R08 | After a refund, the customer retries: duplicate order, stale cart, or a second refund | Product | 2 | 4 | 8 | 🟠 HIGH | State transition cases for retry after decline; exploratory session 2 | Tester |
| 16 | R10 | Double submit starts two split payments for the same order | Product | 2 | 4 | 8 | 🟠 HIGH | Error guessing case at integration level; UI disables submit during processing | Dev B |
| 17 | R19 | No automated single-card regression exists (A10 false) | Project | 2 | 4 | 8 | 🟠 HIGH | Verify day 1; if missing, six manual smoke cases on single-card checkout run on 2026-11-03 and 2026-11-05 | Tester |
| 18 | R12 | Split form is confusing: error messages, even-split control, remainder shown wrongly | Product | 3 | 2 | 6 | 🟡 MEDIUM | Exploratory session 1 with a usability charter | Tester |
| 19 | R13 | Flag off still shows split UI or changes single-card flow | Product | 2 | 3 | 6 | 🟡 MEDIUM | Flag-off case in the gate (TC-SINGLE-R01); read flag values from staging, not from code defaults | Tester |
| 20 | R20 | Estimate inaccurate: no history for this kind of feature | Project | 3 | 2 | 6 | 🟡 MEDIUM | Three-point estimate with range; re-estimate after 2026-10-29 | Tester |

## 6. Test Approach

### Pyramid and quadrants

**Where does the business logic live?** In the backend payment service: split arithmetic, orchestration, refund. The UI holds one amount field and a control. Preset: **Backend / API: 70% unit, 20% integration, 10% E2E.** The E2E share is small on purpose because every E2E run against real PayGate costs a sandbox window.

| Quadrant | What this plan puts there |
| :--- | :--- |
| Q1 technology facing, supports the team | Unit tests on the split calculator and validation; component integration tests on the orchestration against the simulator; all in CI |
| Q2 business facing, supports the team | Gherkin scenarios for the seven requirements as acceptance criteria; API tests on the checkout endpoint; the release gate cases |
| Q3 business facing, critiques the product | Two exploratory sessions; product owner and finance ops acceptance on 2026-11-03 |
| Q4 technology facing, critiques the product | CI smoke on single-card checkout; security checks (tampered amount, tokenization path); refund timing measured against 60 s. No load test: see out of scope |

### Levels, who tests, independence

| Level | Test object | Techniques | Who tests | Independence | Why this degree |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Component | Split calculator, validation, form component | EP, 3-value BVA, decision table (custom/even × odd/even total), branch coverage ≥ 80% on calculator and orchestration | Dev A, Dev B; each reviews the other's tests | Some | Developers find arithmetic defects fastest in their own code; the peer review catches the stub that agrees with a wrong belief |
| Component integration | Payment service with PayGate simulator | State transition, all-transitions coverage of the order payment states; error guessing on timeout and retry | Dev A writes; tester reviews the state table | Some | The tester's review of the state table is where R01, R05 and R07 get a second pair of eyes before any sandbox time is spent |
| System (API and UI) | Checkout on staging, simulator | API tests with tampered bodies; BVA at the UI; exploratory sessions | Tester | Some (same squad, not the author) | The tester is in the squad, so independence is "some"; it is enough because PayGate's sandbox gives an external oracle for the money paths |
| System integration | Checkout on staging against PayGate sandbox | Gate cases, timed refund, record comparison with PayGate dashboard | Tester, with Dev A present on sandbox days | Some | Dev A present shortens the fix loop inside a four-hour window; the tester runs and records |
| Acceptance | Split order end to end on sandbox | Walkthrough of the Gherkin scenarios | Product owner, finance ops | High (outside the development team) | Finance ops judge reconciliation, which nobody in the squad can |

### Test types

Functional at every level. Non-functional: security (R11) and the 60-second refund timing (reliability and performance of one path). No usability lab, no load test, no compatibility matrix; one browser (assumed Chrome stable) plus the keyboard pass in exploratory session 1.

### Deliverables

- This plan, versioned.
- Gherkin scenarios for REQ-01 to REQ-07 (`/qa-bdd`), 2026-10-28.
- Test cases TC-SPLIT-001 to about 030 and TC-SINGLE-R01 to R06 (`/qa-cases`), 2026-10-28.
- Fixture set document (below), first version 2026-10-27.
- Four progress reports, one go/no-go record, one completion report.
- Defect reports as found.

### Entry criteria

| Level | Entry |
| :--- | :--- |
| Component and component integration | Simulator stubs updated from real sandbox responses recorded on 2026-10-27; state table reviewed by the tester |
| System and system integration | Feature on staging with flag on, state "Ready for QA" in Jira, CI green on that build including the single-card regression suite, by 2026-10-30 end of day; sandbox test cards listed in the fixture set; `data-testid` attributes on the amount field, even-split control, submit button and error message |
| Acceptance | Gate cases G1 to G4 passed on sandbox on 2026-11-03 |

### Exit criteria

| Level | Exit |
| :--- | :--- |
| Component and component integration | Branch coverage ≥ 80% on calculator and orchestration; every decision table column and every transition in the state table has a passing test in CI |
| System and system integration | Every gate case passed on sandbox on the release candidate build; 100% of P0 cases run and passed; 100% of P1 passed or each failure has a recorded product owner exception; zero open Critical or High defects without exception; refund latency ≤ 60 s on every timed run |
| Acceptance | Product owner and finance ops sign the go/no-go record |
| Release | Single-card regression suite green on the release build; post-release sanity on production passed |

Time running out ends testing only if the product owner records acceptance of the risk of going live without further testing (CTFL §5.1.3). The contingency written here is to release with the flag off.

### Release gate

Result column is filled per build; `Pending` until run.

| ID | What it proves | Level and environment | Result |
| :--- | :--- | :--- | :--- |
| TC-SPLIT-001 | Custom split, both approved: two PayGate charges summing to the total, order placed, receipt shows both | System integration, sandbox | Pending — build not yet available |
| TC-SPLIT-002 | Even split of an odd total puts the remainder cent on card 1 (unit test in CI plus one sandbox order of 10.01) | Component in CI, then sandbox | Pending — build not yet available |
| TC-SPLIT-003 | Card 2 declined: card 1 refunded, PayGate accepts the refund within 60 s, order not placed, customer told | System integration, sandbox, timed | Pending — build not yet available |
| TC-SPLIT-004 | Card 1 declined: card 2 never charged, order not placed | System integration, sandbox | Pending — build not yet available |
| TC-SPLIT-005 | Tampered card 2 amount in the API body is rejected; server recomputes from the total | System (API), simulator | Pending — build not yet available |
| TC-SPLIT-006 | Timeout on card 2 then retry: exactly one charge per card, idempotency holds | Component integration with simulator; sandbox only if PayGate can time out | Pending — build not yet available |
| TC-SINGLE-R01 | Single-card checkout unchanged with flag off and with flag on, on staging | System, sandbox | Pending — build not yet available |
| TC-SINGLE-R02 | CI single-card regression suite green on the release build | CI regression | Pending — build not yet available |

A failed gate case blocks the release. Findings outside the gate inform; one that turns out to be caused by this change moves into the gate with a dated note. Findings not caused by this change get their own ticket and never gate 5.3.

**Execution order.** The gate uses risk-based ordering; the sandbox window overrides it where noted.

1. TC-SINGLE-R02, on every push from day 1: CI, no window needed, and it must be green before any staging session starts.
2. TC-SPLIT-002 unit part and TC-SPLIT-006, from 2026-10-28 on the simulator: no sandbox needed, and they catch R02 and R03 before a window is spent.
3. TC-SPLIT-005, 2026-10-30 on the simulator: API only.
4. TC-SPLIT-001, first in the 2026-11-03 window: TC-SPLIT-003 depends on a successful charge on card 1, so the happy path runs first despite R01 outranking it.
5. TC-SPLIT-003, same window, timed with a stopwatch and the PayGate dashboard timestamp.
6. TC-SPLIT-004, same window.
7. TC-SPLIT-002 sandbox part, same window, order of 10.01.
8. TC-SINGLE-R01, end of the same window: flag toggled last so it does not disturb the split runs.
9. Full gate re-run on the release candidate in the 2026-11-05 window, same order.

Analysis cases outside the gate run requirements-based, REQ-06 first, then REQ-04, REQ-02, on the simulator from 2026-10-30, and as sandbox time allows.

### Metrics

| Metric | Decision it supports |
| :--- | :--- |
| Gate cases passed / 8, per build and environment | Go/no-go |
| Risk coverage: CRITICAL and HIGH rows with at least one executed case | Whether a sandbox window must be re-prioritized |
| Maximum refund latency over all timed runs, in seconds | Pass/fail of REQ-06 |
| Open defects by severity, with age | Exceptions needed |
| Sandbox windows used / 4, and cases blocked for lack of sandbox | Whether to ask PayGate for an extra window or fall back to flag off |
| Tester hours used / 40, against the estimate in item 7 | Whether developers take over simulator runs |

**Pre-agreed control directives.** Entry deadline missed on 2026-10-30: release 5.3 with the flag off and plan split for 5.3.1. Sandbox outage on 2026-11-03: request an extra window; if refused, run the gate on the simulator, mark sandbox cases blocked, and the go/no-go decides with the flag off. Refund latency above 60 s on any run: defect at Critical, re-run in the next window only after a fix.

### Test data and environment

**Fixture set** (first written 2026-10-27, kept in the repo next to the cases).

| Fixture | Description | State assumed / left | May be written? | Rebuild |
| :--- | :--- | :--- | :--- | :--- |
| FX-CARD-OK-1, FX-CARD-OK-2 | Two PayGate sandbox approve cards | Always approve | Read only | From PayGate documentation |
| FX-CARD-DECL | Sandbox decline card | Always declines | Read only | From PayGate documentation |
| FX-CARD-TIMEOUT, FX-CARD-REFUNDFAIL | Sandbox timeout and refund-failure cards | N/A — availability confirmed 2026-10-27 | Read only | N/A — PayGate decides |
| FX-SIM-* | Simulator scenarios keyed by amount: ending .98 declines card 2, .97 times out, .96 fails the refund | As listed | Developers only, versioned | From stub files in the repo |
| FX-CUST-QA53 | Staging customer account for split orders | Empty cart at start and end | Write, restore cart | Re-create via admin |
| FX-SKU-ODD, FX-SKU-EVEN, FX-SKU-MIN, FX-SKU-MAX | Products priced 10.01, 10.00, 0.02, 9,999.99 | Available, in stock | Read only | Seed script |
| Sandbox merchant account | Shared with other teams (A14) | N/A — shared state | Write only orders prefixed QA53-; never touch others' transactions | N/A — nobody can |
| Staging feature flag | split_payment_enabled | On, except during TC-SINGLE-R01 | Write, announce in chat, restore to On | Flag admin |

A case whose fixture is missing or in the wrong state is blocked, not failed.

**Environment.** Staging must record build (commit and pipeline run), simulator stub version, flag state and, on sandbox days, PayGate API version and the date of the window. Developer and tester machines are dry runs; results are recorded only from staging and CI.

### Deviations from policy and strategy

- Sandbox E2E cases are manual this release; automating against a resource available two days a week would spend the windows on tooling. Logged as debt for 5.4.
- No accessibility audit; keyboard pass only. Reason: tester capacity.
- The release gate contains two regression cases instead of a full regression run on staging, because the CI suite carries the rest.
- Independence at system level is "some" rather than "high"; there is no tester outside the squad.

## 7. Estimate

Technique: three-point estimation, one estimator, no history for a two-card flow.

| Who | a (optimistic) | m (likely) | b (pessimistic) | E | SD | Range |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Tester | 32 h | 44 h | 68 h | 46 h | 6 h | 40 to 52 h |
| Developers, test work only, both together | 16 h | 24 h | 40 h | 25 h | 4 h | 21 to 29 h |

Tester decomposition at the likely value: planning and static review 4 h, Gherkin and cases 7 h, four sandbox sessions 16 h, API and simulator runs 6 h, two exploratory sessions 4 h, defect reports and progress reports 4 h, go/no-go and completion 3 h.

**Assumptions behind the figure.** The feature reaches staging by 2026-10-30; the simulator exists on day 1; sandbox is up on all four days; at most two Critical defects are found. The available 40 hours sit at the low end of the range, so the plan already moves simulator runs and the gate dry run to the developers; if more than two Critical defects appear, the shortfall becomes the control directive "release with flag off". Re-estimate after 2026-10-29.

## 8. Budget and Schedule

**Budget.** Tester 40 h, developers about 25 h of test work inside their build time. PayGate sandbox and the simulator are assumed free. No tool purchase.

| Day | Date | Activity | Owner |
| :--- | :--- | :--- | :--- |
| 1 | Mon 2026-10-26 | Kickoff; static review of the brief with product owner and developers, confirming A5, A6, A11; impact analysis of changed modules; verify CI regression suite (A10) | Tester, all |
| 2 | Tue 2026-10-27, sandbox 1 | Record real PayGate responses on current single-card checkout: approve, decline, refund, timeout if possible; list test cards; write fixture set; update simulator stubs | Tester, Dev A |
| 3 | Wed 2026-10-28 | Gherkin scenarios; test cases; review of the state table; developers' unit tests | Tester, Dev A |
| 4 | Thu 2026-10-29, sandbox 2 | Whatever is built against sandbox, at least the two-charge path; TC-SPLIT-006 on simulator; re-estimate | Tester, Dev A |
| 5 | Fri 2026-10-30 | Entry deadline for staging; TC-SPLIT-005 on simulator; gate dry run on simulator | Tester, Dev B |
| 6 | Mon 2026-11-02 | Exploratory session 1 (form, validation, keyboard); flag-off regression on simulator | Tester |
| 7 | Tue 2026-11-03, sandbox 3 | Full gate run on sandbox, refund timed; finance ops and product owner acceptance; progress report | Tester, Dev A, PO, Finance |
| 8 | Wed 2026-11-04 | Fixes; confirmation on simulator; exploratory session 2 (retry after decline, double submit) | Tester, developers |
| 9 | Thu 2026-11-05, sandbox 4 | Gate re-run on the release candidate; go/no-go meeting end of day | Tester, all |
| 10 | Fri 2026-11-06 | Release with flag off, canary of flag on at 5% if go; production sanity per A15; completion report | Release manager, Tester |

## 9. Configuration Management of Testware

- This plan, the Gherkin scenarios, test cases, fixture set, simulator stubs and reports live in the product repository under a docs/qa/5.3 folder, version controlled with the code; each has an identifier and a version, and this plan is TP-SPLIT-5.3 v1.0.
- Every case traces to a REQ-NN and to a register row; every result names the build (commit and CI run), the environment, the flag state, the simulator stub version or the sandbox window date.
- The staging environment approved on 2026-10-30 is the baseline: build, flag state, simulator version. Changes after that go through the release manager and are announced in chat.
- A previous baseline can be restored by redeploying the recorded commit and stub version, so a sandbox result can be reproduced in the next window.
- CI records unit, integration and regression results per commit automatically; sandbox results are recorded by hand in the results page, one case per row, with a "Not run — resume point" section.
- Corrections to any shared document are made in place with a dated note, never by deletion.
