# Test Plan: Split Payment (Release 5.3)

| Field | Value |
| :---- | :---- |
| Plan ID | TP-SPLIT-5.3 |
| Version | 0.1, 2026-10-24 (first draft, not yet shared) |
| Owner (test management role) | The half-time tester |
| Board | N/A — tracker URL not given; the plan refers to tickets by key `SPLIT-nn` once they exist |
| Release date | Friday 2026-11-07 (10 working days from Friday 2026-10-24) |
| PayGate sandbox days in the window | Tue 2026-10-28, Thu 2026-10-30, Tue 2026-11-04, Thu 2026-11-06 (four days) |

## 1. Context of testing

**Scope.**

In scope:

- The split payment flow: amount entry for card 1, derivation of the card 2 amount, both charges through PayGate, order placement on double approval.
- The compensation path: card 2 declined, card 1 refunded automatically within 60 seconds, order not placed, customer told what happened.
- The split arithmetic in cents, including the remainder cent going to card 1.
- Regression of the existing single-card checkout (about 4,000 orders a day), which must keep working with the feature on and off.
- Tampering resistance of the amounts sent from the browser.

Out of scope:

- PayGate's own correctness (its sandbox is the oracle for its responses, not a test object).
- Load and stress testing of checkout. There is no load environment or time in the window; a latency check on the split path replaces it (see item 6, deviations).
- Three or more cards, saved-card wallets, 3-D Secure challenges, and partial refunds of a completed split order. Assumed not part of release 5.3.
- Accounting reconciliation reports. Covered by a non-test measure (item 5, R06) rather than by tests.

**Objectives.**

1. Show that no customer can be charged for an order that is not placed, and that no placed order is charged more or less than its total.
2. Show that the single-card checkout behaves exactly as it does today, feature flag on or off.
3. Give the release decision a record of what passed, what did not run and which risks stay open, measured on a named build and environment.

**Test basis.**

- The feature brief above (the only written source available).
- PayGate's API documentation for charge, refund and idempotency semantics (assumed to exist; version to be recorded on first sandbox day).
- The existing single-card checkout tests and their last results (assumed to exist in the repository).
- Acceptance scenarios to be written from this plan with `/qa-bdd` on day 1, so the brief gets a testable rewrite before code lands.

## 2. Assumptions and constraints

Assumptions (each stated because the brief does not settle it; each is a question for the product owner on day 1, and testing proceeds on the assumption until answered):

- A1. The card 1 amount is entered in whole cents and must be at least 1 cent and at most total minus 1 cent. Zero and the full total are rejected with a message pointing the customer to single-card checkout.
- A2. The remainder-cent rule applies to a "split evenly" shortcut that halves an odd total; manual entry needs no rounding since it is already in cents.
- A3. Charges run sequentially: card 1 first, card 2 only after card 1 is approved. If card 1 is declined, card 2 is never attempted.
- A4. The 60-second refund target is measured from PayGate's decline response for card 2 to PayGate's acceptance of the refund request.
- A5. The feature ships behind a feature flag, off by default, so the off state is production's current behavior and can be tested as such.
- A6. Charge requests to PayGate carry an idempotency key, so a retry after a timeout cannot charge the same card twice.
- A7. A refund that fails raises an alert to support with the order and charge identifiers, and a manual refund runbook exists or will be written by release.
- A8. The stack is a web front end over a backend checkout service that owns the split arithmetic and the charge orchestration. The pyramid preset in item 6 rests on this.
- A9. Staging is deployed from a CI pipeline and the deployed build is identifiable by commit.
- A10. One currency, no fees or rounding in PayGate's responses.

Constraints:

- C1. PayGate's sandbox is available only on Tuesdays and Thursdays: four days in the window. Every test that needs the real gateway is pinned to those days; every other day runs against a PayGate stub the developers maintain.
- C2. One tester at half time, about 40 person-hours across the window, plus two developers.
- C3. Release in 10 working days with no slack for a second sandbox cycle after Thursday 2026-11-06.
- C4. Single-card checkout runs about 4,000 orders a day, so any regression costs money within hours.

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :--- | :-- | :------------- | :------------------- |
| Product owner | N/A — name not given; assumed one exists | Confirms assumptions A1 to A7, accepts residual risk at the gate, signs the completion report | Owns the exceptions on P1 failures and the go/no-go |
| Developers (2) | The two building the feature | Unit and integration tests, PayGate stub, fixes, feature flag and kill switch | Hold the testing role at component and component integration level; one developer peer-reviews the other's tests |
| Tester (half time) | The one tester | Test analysis, design and execution at system and system integration level; monitoring and reporting | Holds the test management role and the testing role for the higher levels |
| Support / operations | N/A — not named; assumed a support function exists | Handles refund-failure alerts and the manual refund runbook | Validates the runbook once, on a sandbox day |
| PayGate account contact | N/A — not named | Sandbox access, test card list, API version | Blocks every sandbox-day test if access fails |
| Finance | N/A — not named | First-week reconciliation of split orders after release | Non-test control for arithmetic and refund risks |

## 4. Communication

| Form | Frequency | Template |
| :--- | :-------- | :------- |
| Stand-up note from the tester (progress, blockers, next sandbox day plan) | Daily, written in the team channel | Three lines: done, next, blocked |
| Progress report | After each of the four sandbox days | The progress report content in the package's reporting reference: period, progress against plan, impediments, metrics, new risks, next period |
| Defect reports | As found | `/qa-defect` format, `DR-SPLIT-NNN`, one ticket per finding, linked from this plan |
| Risk register review | At each progress report | Re-score rows in place with a dated note; never delete a row |
| Completion report with go/no-go record | Friday 2026-11-07, before the release decision | Every case one per row, "Not run — resume point" section, residual risks and defects not fixed |
| Retrospective | Week after release | Whole team; three questions; actions with owner and date |

## 5. Risk register

Scale: likelihood 1 to 5, impact 1 to 5, score is the product. Levels: 15 to 25 critical, 8 to 14 high, 4 to 7 medium, 1 to 3 low.

| # | ID | Risk description | Category | L | I | Score | Level | Mitigation strategy | Owner |
| :- | :- | :--------------- | :------- | :- | :- | :---- | :---- | :------------------ | :---- |
| 1 | R01 | Card 2 declined and card 1 not refunded, or refunded after 60 s: customer charged for an order that does not exist | Product | 3 | 5 | 15 | 🔴 Critical | State transition tests on the orchestration at unit level; gate cases G3 and G7 on sandbox with refund latency measured; refund-failure alert and manual refund runbook (A7); kill switch via feature flag | Dev / Tester |
| 2 | R02 | Double charge: a timeout after card 1 or card 2 is charged leads to a retry that charges again | Product | 3 | 5 | 15 | 🔴 Critical | Idempotency key per charge (A6) checked by integration test against the stub with injected timeouts; one sandbox probe of PayGate's idempotency behaviour on day 1 | Dev |
| 3 | R03 | Regression in single-card checkout with the flag on or off | Product | 2 | 5 | 10 | 🟠 High | Existing single-card regression suite run on every build, both flag states; gate cases G5 and G8; canary rollout at 5 % with error-rate threshold | Dev / Tester |
| 4 | R04 | Split arithmetic wrong: amounts do not sum to the total, remainder cent on card 2, or rounding in the UI before cents reach the backend | Product | 3 | 4 | 12 | 🟠 High | Unit tests with BVA and EP on the split function (A1, A2); gate case G2; finance reconciliation in week one | Dev |
| 5 | R05 | Card 1 charged, then the process dies before card 2 is attempted: charge with no order and no refund trigger | Product | 2 | 5 | 10 | 🟠 High | Orchestration persists state before each gateway call; a recovery job refunds orphaned card 1 charges; integration test kills the process between calls; sandbox check that recovery works end to end | Dev |
| 6 | R06 | Refund request itself fails (declined, timeout) and nobody is told | Product | 2 | 5 | 10 | 🟠 High | Alert plus runbook (A7), tested once on a sandbox day with a refund-fail test card if PayGate provides one, else against the stub; finance reconciliation as the backstop | Dev / Support |
| 7 | R07 | Client-side amount tampering: card 1 plus card 2 below the total, or negative amounts, accepted by the backend | Product | 2 | 5 | 10 | 🟠 High | Backend recomputes card 2 from the server-side total and rejects any mismatch; API tests send tampered bodies directly | Dev / Tester |
| 8 | R08 | Input validation gaps on the card 1 amount: 0, total, above total, negative, non-numeric, more than two decimals | Product | 4 | 3 | 12 | 🟠 High | BVA and EP cases at unit and API level; gate case G6 for the two money-relevant boundaries | Dev / Tester |
| 9 | R09 | Receipt, order history and confirmation email show wrong totals or only one charge | Product | 3 | 3 | 9 | 🟠 High | System test of each artefact on sandbox day 3; exploratory session on the customer-visible flow | Tester |
| 10 | R10 | The same card used for both halves is accepted and behaves oddly at the gateway | Product | 3 | 2 | 6 | 🟡 Medium | Decide with the product owner whether to allow it (assumed allowed); one sandbox case either way | Tester |
| 11 | R11 | Two sequential gateway calls double checkout latency past what the UI tolerates | Product | 3 | 2 | 6 | 🟡 Medium | Timing check in the sandbox runs (p95 of split checkout against single-card on the same day); no load test (item 6, deviations) | Tester |
| 12 | R12 | PayGate sandbox is available only four days in the window, so a defect found on day 4 cannot be retested on the gateway | Project | 5 | 4 | 20 | 🔴 Critical | Everything that can run on a stub runs on a stub; sandbox days reserved for gate cases, contract checks and exploration; code complete by Monday 2026-11-03 so day 3 is the main run and day 4 is retest only | Tester / Devs |
| 13 | R13 | Tester capacity: the pessimistic estimate (item 7) exceeds the 40 hours available | Project | 4 | 4 | 16 | 🔴 Critical | Developers own unit, integration and stub-based API tests; tester concentrates on the gate, sandbox sessions and reporting; cut list ordered by risk level in item 6 | Tester |
| 14 | R14 | PayGate stub disagrees with the real sandbox, so stub passes hide gateway defects | Project | 3 | 4 | 12 | 🟠 High | Sandbox day 1 used to record real responses for approve, decline, refund and idempotent retry, and the stub is built from those recordings; contract check repeated on day 3 | Devs |
| 15 | R15 | Feature lands late, pushing the first full sandbox run to Thursday 2026-11-06 with no retest day | Project | 3 | 4 | 12 | 🟠 High | Entry criteria for system testing checked on Monday 2026-11-03; if unmet, the product owner decides on day 8 between a delayed release and a flag-off release | Product owner |
| 16 | R16 | Sandbox refund timing is not representative of production, so the 60-second target is only partly verified | Project | 3 | 3 | 9 | 🟠 High | Measure sandbox refund latency and record it; add production monitoring of refund latency with an alert above 45 s; accept the residual risk in the go/no-go record | Tester / Dev |

## 6. Test approach

**Test levels, who tests and independence.**

| Level | Test object | Who tests | Independence | Why this degree fits |
| :---- | :---------- | :-------- | :----------- | :------------------- |
| Component (unit) | Split function, amount validation, orchestration state machine | The developer who wrote it, tests reviewed by the other developer | None to some | Fast feedback on arithmetic and state logic; peer review catches the author's blind spots on boundaries |
| Component integration | Checkout service against the PayGate stub: sequencing, timeouts, idempotency, persistence between calls | The other developer (not the author) | Some | The double-charge and orphan-charge risks (R02, R05) are interaction defects; a second pair of eyes on the stub contract matters |
| System and system integration | Full checkout on staging against PayGate sandbox and against the stub | The tester | High (did not write the code, same organisation) | Money-moving defects need someone who challenges the implementation's assumptions, which is what the critical rows ask for |
| Acceptance | The BDD scenarios on sandbox day 3 | Product owner, walked through by the tester | High | Validates the assumptions A1 to A7 against business intent, not just against the code |

**Test types.** Functional (all levels); non-functional: security (amount tampering, R07), performance efficiency limited to a latency comparison (R11), reliability of the compensation path (R01, R05, R06). Accessibility: a keyboard-only pass of the new amount field during the exploratory session; no full audit (see deviations).

**Pyramid preset.** Backend / API: 70 % unit, 20 % integration, 10 % end to end, because the split arithmetic, the orchestration and the refund rule live in the checkout service (A8). The UI adds one amount field and a confirmation screen, covered by two component tests and the end-to-end gate cases.

**Testing quadrants.**

- Q1 (technology facing, supports the team): unit and integration tests in CI, owned by developers.
- Q2 (business facing, supports the team): BDD scenarios from `/qa-bdd`, API tests of the checkout endpoint.
- Q3 (business facing, critiques the product): two exploratory sessions on sandbox days 3 and 4 (charters: "break the compensation path", "what does the customer see when it goes wrong"); acceptance walkthrough with the product owner.
- Q4 (technology facing, critiques the product): smoke suite on every build; tampering tests; latency comparison. No load test, by decision (deviations).

**Techniques by risk level.**

| Risk rows | Technique | Coverage items and target |
| :-------- | :-------- | :------------------------ |
| R01, R05 (critical, high) | State transition testing on the orchestration: Pending, Card1Charged, Card2Charged/OrderPlaced, Refunding, Refunded, RefundFailed, Card1Declined | All transitions, valid and invalid attempted, one invalid transition per case |
| R02 (critical) | Error guessing and decision table: timeout before/after PayGate records the charge × retry with same/different idempotency key | Every feasible column |
| R04, R08 (high) | BVA (3-value) on the card 1 amount: 0, 1, 2, total−2, total−1, total, total+1; EP on the input: whole cents valid, negative, non-numeric, three decimals invalid; "split evenly" on even and odd totals and on a 1-cent total | Every boundary and every partition |
| R03 (high) | Regression: the existing single-card suite, flag on and flag off | 100 % of the suite's P0 and P1 cases on each build |
| R06, R07 (high) | Checklist-based: refund failure handling; tampered request bodies (sum below total, negative card 2, card 1 above total) | Every checklist item |
| R09, R10, R11 (high to medium) | Exploratory sessions with charters; scripted latency comparison | Session notes with findings; one timing table |
| R12 to R16 (project) | N/A — project risks are controlled by schedule and ownership, not by test cases | N/A — no coverage item |

**Deliverables.**

- Acceptance scenarios (`.feature`), day 1.
- Test cases `TC-SPLIT-NNN` with ISTQB technique rows, days 1 to 3.
- PayGate stub recordings from sandbox day 1, owned by the developers.
- Fixture set document (below).
- Four progress reports, one completion report with the go/no-go record, defect reports.

**Entry criteria.**

Component and component integration (developers):

- Acceptance scenarios reviewed by the product owner.
- Stub built from sandbox recordings (after Tuesday 2026-10-28).

System and system integration (tester), checked Monday 2026-11-03:

- Feature flag, split flow and compensation path merged and deployed to staging from a CI run that passed, build identified by commit.
- Unit and integration suites green in CI, branch coverage of the split and orchestration modules at or above 80 %.
- PayGate sandbox credentials and test cards available (fixture set complete).
- Amount field and confirmation screen carry `data-testid` attributes.
- Refund-failure alert wired to a test channel.

**Exit criteria** (measured against the release gate below and the full case list):

- Every release gate case passed on the final build, on staging, with the real sandbox where the case requires it.
- 100 % of P0 cases run and passed; 100 % of P1 run and passed or each failure carries a recorded product-owner exception.
- Zero open critical defects; zero open high defects without a recorded exception.
- Single-card regression suite passed with the flag on and with the flag off.
- Refund latency measured on sandbox: every observed compensation under 60 s, and the production alert on refund latency deployed.
- Completion report signed by the tester and the product owner.

If time runs out before these are met, testing stops only when the product owner has reviewed the open items and recorded acceptance of the risk.

**Release gate.** The smallest set whose failure stops the release. Results are filled in on the final build.

| ID | What it proves | Needs sandbox | Risk | Result |
| :- | :------------- | :------------ | :--- | :----- |
| G1 | Split with both cards approved places the order; the two PayGate charges sum exactly to the order total | Yes | R04 | N/A — not yet run |
| G2 | "Split evenly" on an odd total puts the extra cent on card 1 (10.01 → 5.01 and 5.00) and both charges are recorded in cents | Yes | R04 | N/A — not yet run |
| G3 | Card 2 declined: card 1 is refunded automatically, the refund request is accepted within 60 s of the decline, no order is placed, the customer sees why | Yes | R01 | N/A — not yet run |
| G4 | Card 1 declined: card 2 is never charged, no order is placed | Yes | R01, A3 | N/A — not yet run |
| G5 | Single-card checkout, flag on: the existing regression suite passes on the release build | Yes | R03 | N/A — not yet run |
| G6 | Card 1 amount of 0 and of the full total are rejected; the backend rejects a tampered body whose two amounts sum below the total | No (stub) | R07, R08 | N/A — not yet run |
| G7 | Timeout after card 2 is charged, then retry: exactly one charge per card exists at PayGate and the order is placed once | No (stub; idempotency probed on sandbox day 1) | R02 | N/A — not yet run |
| G8 | Flag off: checkout page, request payload and PayGate calls are byte-for-byte what the previous build produced | No | R03 | N/A — not yet run |

Cases that fail for reasons the change did not cause get their own ticket and stay out of the gate's pass/fail. If an analysis finding turns out to be caused by the change, its case moves into the gate with a dated note here.

**Execution order.** Risk-based by default; the sandbox window and two dependencies move cases.

1. G8 on Monday 2026-10-27, on the stub, before any feature code is deployed: records the baseline the flag-off comparison needs (dependency: G8 needs the previous build's recording first).
2. Sandbox day 1, Tuesday 2026-10-28: single-card regression on sandbox to baseline G5; PayGate idempotency and refund probes that G7 and the stub depend on (resource window: real gateway needed, and the stub cannot be trusted until these recordings exist).
3. Unit and integration cases as code lands, days 2 to 6, developers, on every push.
4. G6 and G7 on the stub as soon as the orchestration is merged, days 4 to 6 (no sandbox needed, so they run before the sandbox cases despite lower risk than G3).
5. Sandbox day 2, Thursday 2026-10-30: G1 and G2 if the split flow is deployed, else repeat of step 2 with the first deployed parts; contract check of stub against sandbox.
6. Sandbox day 3, Tuesday 2026-11-04, the main run: G3, G4, G1, G2, G5 in that order (G3 first because it carries the critical risk), then exploratory session 1 and the acceptance walkthrough.
7. Days 7 and 8 on the stub: remaining analysis cases (receipts, emails, same-card, validation partitions), fixes retested.
8. Sandbox day 4, Thursday 2026-11-06: retest of every gate case that failed or changed since day 3, full gate rerun on the release candidate, exploratory session 2, refund latency table, runbook check with support.
9. Friday 2026-11-07: completion report and go/no-go record.

**Metrics to collect.**

- Gate cases passed / 8, per build (decides go/no-go).
- Single-card regression pass rate per build, flag on and flag off (decides whether R03 is live).
- Refund latency: every compensation observed on sandbox, max and count over 60 s (decides R01 residual risk).
- Risk coverage: register rows with at least one executed case / 11 product rows (decides what the completion report declares untested).
- Open defects by severity (exit criterion).
- Tester hours spent against the estimate in item 7, checked at each progress report (triggers the cut list).

Control directives are recorded with their reason at the next progress report. Pre-agreed ones: if the entry criteria are unmet on Monday 2026-11-03, the product owner chooses on that day between slipping the release and shipping with the flag off; if hours spent exceed the estimate's upper bound by day 3, analysis cases for R09 and R10 are dropped first, then exploratory session 2.

**Test data: fixture set.** Credentials live in the team's secret store; this document names records, never secrets.

| Fixture | Description | State assumed | May tests write to it | Rebuild |
| :------ | :---------- | :------------ | :-------------------- | :------ |
| F01 PayGate sandbox account | Merchant account for staging | Active, API version recorded on day 1 | Read only; charges and refunds are the expected writes and are logged | PayGate contact; nobody in the team can |
| F02 Test cards: approve, decline, insufficient funds, refund-fails (if offered), timeout (if offered) | PayGate-documented card numbers | As documented | Read only | From PayGate docs |
| F03 Orders with totals 0.01, 0.02, 10.00, 10.01, 999,999.99 (assumed maximum) | Seeded carts on staging | Unpaid | Tests consume them; reseed after each run | Seed script owned by developers |
| F04 Customer account for checkout | Staging customer with a shipping address | Logged out | Order history grows; nothing else | Seed script |
| F05 Previous-build recording for G8 | Captured page, payload and gateway calls from the pre-feature build | Captured on 2026-10-27 | Read only | Recapture from the previous build tag |
| F06 Stub recordings | PayGate responses captured on day 1 | Versioned with the stub | Read only | Recapture on any sandbox day |

A case whose fixture is missing or in the wrong state is blocked, not failed.

**Environment.** Staging deployed by CI from a named commit, feature flag readable from the flag service, PayGate stub selectable by configuration, refund alert routed to a test channel. The flag state and the gateway (sandbox or stub) are recorded in every result.

**Deviations from the test policy and strategy.**

- No load test: no load environment and no time; the latency comparison in R11 and the canary rollout stand in for it, and the residual risk is recorded.
- No full accessibility audit: one new field; a keyboard pass covers it, and a full audit is deferred to the next release.
- Component integration tests of the gateway run against a stub five days out of seven: a deliberate acceptance of R14, controlled by the day 1 recordings and the day 3 contract check.

**Non-test measures.** Feature flag as kill switch; canary at 5 % of orders for the first day with an automatic halt if checkout error rate rises above the previous week's mean plus 50 %; refund-failure alert and manual runbook; finance reconciliation of all split orders in week one; production alert on refund latency above 45 s.

## 7. Estimate

Technique: three-point estimation, one estimator, decomposed by task. Values are tester person-hours.

| Task | a | m | b |
| :--- | :- | :- | :- |
| Test analysis and design (scenarios, cases, fixture set) | 6 | 8 | 12 |
| Stub-based system and API runs on non-sandbox days | 4 | 6 | 10 |
| Four sandbox days (gate, contract check, exploration) | 12 | 16 | 20 |
| Defect reporting and retests | 3 | 4 | 8 |
| Progress reports, completion report, go/no-go record | 3 | 4 | 6 |
| Total | 28 | 38 | 56 |

E = (28 + 4 × 38 + 56) / 6 = 39.3; SD = (56 − 28) / 6 = 4.7.

**Tester effort: 39 ± 5 person-hours (between 35 and 44), against 40 available.** The pessimistic value exceeds capacity, which is why R13 is critical and the cut list exists.

Developer test effort is not estimated here; the assumption is that each developer spends about a third of the window on tests and the stub (about 24 hours each), and that the stub is ready by Wednesday 2026-10-29.

Assumptions behind the figures: sandbox access works on the first attempt; the feature meets the entry criteria on Monday 2026-11-03; the single-card regression suite is automated and runs in under 30 minutes; no more than four defects of high severity or above are found.

## 8. Budget and schedule

Budget: N/A — no monetary budget given; the cost is the staffing above and the PayGate sandbox, which is assumed already contracted.

| Day | Date | Sandbox | Developers | Tester (about 4 h) |
| :- | :--- | :------ | :--------- | :----------------- |
| 1 | Mon 2026-10-27 | No | Flag, split function, orchestration skeleton | Confirm assumptions with product owner; BDD scenarios; capture F05; G8 baseline |
| 2 | Tue 2026-10-28 | Yes | Record PayGate responses for the stub | Single-card regression on sandbox; idempotency and refund probes; progress report 1 |
| 3 | Wed 2026-10-29 | No | Stub ready; unit tests for arithmetic and state machine | Test cases for critical and high rows; fixture set |
| 4 | Thu 2026-10-30 | Yes | Integration tests against stub; deploy to staging | G1, G2 if deployed, else contract check only; progress report 2 |
| 5 | Fri 2026-10-31 | No | Compensation path, alert, recovery job | G6, G7 on stub; API tampering cases |
| 6 | Mon 2026-11-03 | No | Code complete; fixes | Entry criteria check; control decision if unmet |
| 7 | Tue 2026-11-04 | Yes | On call for fixes | Main run: G3, G4, G1, G2, G5; exploratory session 1; acceptance walkthrough; progress report 3 |
| 8 | Wed 2026-11-05 | No | Fixes | Remaining analysis cases on stub; retests on stub |
| 9 | Thu 2026-11-06 | Yes | Release candidate cut by 09:00 | Full gate rerun; exploratory session 2; refund latency table; runbook check; progress report 4 |
| 10 | Fri 2026-11-07 | No | Release behind flag, canary 5 % | Completion report; go/no-go record; post-release sanity |

## 9. Configuration management of testware

- Test cases, scenarios, the fixture set, this plan and the stub recordings live in the application repository under version control, each with an identifier (`TP-SPLIT-5.3`, `TC-SPLIT-NNN`, `DR-SPLIT-NNN`, `F0n`) and linked to the `SPLIT-nn` ticket they trace to.
- Every result names the staging build by commit and pipeline run, the flag state, and whether the gateway was the sandbox (with its API version) or the stub (with its recording version). A result without these is not accepted into a report.
- The staging environment, once it passes the entry criteria on Monday 2026-11-03, is the baseline; changes to it after that go through the team's change process and are noted in the next progress report.
- The pre-feature build tag and the F05 recording are kept so the G8 comparison can be reproduced.
- CI runs unit and integration suites on every push and the smoke suite on every deployment; the gate cases that need the sandbox are run by the tester and their evidence is attached to the ticket.
- Corrections to this plan after it is shared are made in place with a dated note; nothing is deleted.
