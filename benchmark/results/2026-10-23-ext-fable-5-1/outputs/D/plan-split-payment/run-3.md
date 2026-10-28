# Test Plan: Split Payment (Release 5.3)

| Field | Value |
| :---- | :---- |
| Plan ID | TP-SPLIT-5.3 |
| Version | 1.0, 2026-10-24 |
| Owner (test management role) | QA tester (half time) |
| Tracker | N/A — tracker not named in the brief; assumed to be the team's existing board, tickets referenced as `SPLIT-nnn` |
| Release date | Friday 2026-11-06 (10 working days, Mon–Fri, assuming no public holidays in the window; if 2026-11-02 is a holiday locally, every date from D6 on slips one day and the release becomes 2026-11-09) |

## 1. Context of testing

**Scope, in:**

- Split of one order total across two cards: customer-chosen amount on card 1, remainder on card 2, integer cents, remainder cent on card 1.
- Two sequential PayGate charges for one order.
- Automatic refund of charge 1 within 60 seconds when charge 2 is declined.
- Order, payment and ledger state after every outcome (both succeed, first declined, second declined, refund fails).
- Regression of the existing single-card checkout (about 4,000 orders a day).
- Test levels: component, component integration, system integration (against PayGate sandbox), acceptance.

**Scope, out:**

- More than two cards (not in the brief).
- Partial refunds or refunds of a completed split order after fulfilment (post-purchase refund flow unchanged; assumed to be covered by existing regression).
- PayGate's own behaviour (contractual, outside our control); we test our handling of its responses.
- Load testing of checkout: no load tooling or environment is named, and 10 days with a half-time tester cannot build one. Covered instead by a non-test measure (canary rollout, item 6).
- Currencies without minor units: assumed every supported currency has 2 decimal minor units.

**Objectives:**

1. Prove that the split rules produce two amounts that always sum to the order total, with the odd cent on card 1.
2. Prove that money is never left in an inconsistent state: no order is placed with only one successful charge, and no customer is charged twice for one order.
3. Prove that the compensating refund is issued within 60 seconds of a declined second charge.
4. Prove that single-card checkout behaves exactly as before.

**Test basis:** the feature brief above; PayGate API documentation (sandbox test cards and decline codes); the existing single-card checkout behaviour as deployed today (recorded on D2 as the oracle). Acceptance criteria beyond the brief: N/A — none written yet; the 7 rules in the risk register's "test conditions" below are proposed as the acceptance criteria and should be confirmed by the Product Owner on D1.

## 2. Assumptions and constraints

**Assumptions (stated because the brief does not say):**

- A1. Architecture is a web front end plus a backend payment service; the split, sequencing and refund logic lives in the backend. PayGate is called from the backend only.
- A2. Card data is tokenised by PayGate; our system never stores PAN. Security testing targets amount tampering and idempotency, not card storage.
- A3. The 60-second window is measured from the moment our system receives PayGate's decline for charge 2 to the moment PayGate acknowledges the refund request for charge 1.
- A4. The feature ships behind a feature flag. If it does not, the plan asks for one (item 6, non-test measures); without it, R03 is re-scored to likelihood 3.
- A5. A staging environment exists that can point at PayGate's sandbox, and a stub of PayGate exists or will be written by the developers by D3 for non-sandbox days.
- A6. Charge order is fixed: card 1 is charged first, card 2 second. If charge 1 is declined, charge 2 is never attempted.
- A7. Minimum amount per card is 1 cent (so the card 1 amount is in the range 1 to total − 1). To be confirmed by the Product Owner on D1.
- A8. A Product Owner exists and accepts the feature; the two developers also hold the automation role for unit and integration tests.
- A9. CI runs unit and integration tests on every push and the team practises continuous delivery (a person decides the release), not continuous deployment.

**Constraints:**

- PayGate sandbox reachable only on Tuesdays and Thursdays: D2 (2026-10-27), D4 (10-29), D7 (11-03), D9 (11-05). Four windows in total; the last one is one day before release.
- Tester capacity: 10 days × 4 h = 40 h.
- Developers: 2, building the feature in the same window; their test effort competes with build effort.
- Single-card checkout cannot be degraded: 4,000 orders a day in production.

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :--- | :-- | :------------- | :------------------- |
| Test management and testing role | QA tester (half time) | Plan, design, system integration execution, reporting, go/no-go record | Owns this plan and the release gate evidence |
| Developers (2) | Feature authors | Unit and component integration tests, PayGate stub, defect fixes, decline-code catalogue | Hold the testing role at component levels; provide the stub by D3 |
| Product Owner | N/A — not named; assumed to exist | Confirms acceptance criteria (D1), accepts P1 exceptions, signs go/no-go | Acceptance decision |
| Payments / finance | N/A — not named; assumed a finance contact exists | Reconciliation of PayGate settlements against orders after release | Monitors the non-test measure for R01, R02, R04 |
| PayGate support | External | Sandbox availability, decline-code behaviour | Contingency when a sandbox window is lost |

## 4. Communication

| Form | Frequency | Template |
| :--- | :-------- | :------- |
| Daily stand-up note (progress, blockers, next sandbox window plan) | Daily, written in the ticket | Progress report content of the `qa-reference` skill's `references/test-reporting.md` |
| Sandbox-day results page | End of each sandbox day (D2, D4, D7, D9) | "Reporting Every Case" row format, one case per row, with build and environment |
| Risk register review | At each results page | This plan, item 5, corrected in place with a dated note |
| Defect reports | As found | `/qa-defect` format, DR-SPLIT-nnn |
| Go/no-go record | D10 | `/qa-release` format, against the release gate below |
| Retrospective | After release, within 5 working days | Three questions of CTFL v4.0 §2.1.6 |

## 5. Risk register

Likelihood (L) and Impact (I) on 1–5; Score = L × I.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Charge 2 declined and charge 1 is not refunded, or refunded after 60 s: customer out of pocket with no order | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests (all transitions) at integration level with stub; gate case G2 on sandbox with timing captured from logs; alert on any refund older than 60 s not acknowledged | Dev/QA |
| 2 | R02 | Split amounts do not sum to the order total, or the odd cent lands on card 2 | Product | 3 | 5 | 15 | 🔴 CRITICAL | BVA and EP unit tests on the split function (property: a + b = total for every total and every valid a); gate case G1 with an odd total | Dev |
| 3 | R03 | Single-card checkout regressed by the shared checkout code change (4,000 orders/day affected) | Product | 2 | 5 | 10 | 🟠 HIGH | Oracle recorded on D2 before the feature build; gate case G4 flag off and flag on; feature flag (A4); canary rollout | Dev/QA |
| 4 | R04 | Customer charged twice for the same card or order on retry, timeout or double submit (no idempotency key) | Product | 3 | 5 | 15 | 🔴 CRITICAL | Integration test with stub simulating timeout-after-success; gate case G7 duplicate submission; idempotency key per charge reviewed in code review | Dev/QA |
| 5 | R05 | Refund request itself fails or times out: order stuck with one charge captured and no refund | Product | 2 | 5 | 10 | 🟠 HIGH | Gate case G6 with stub returning refund failure; retry with backoff; alert and manual-refund queue; daily reconciliation report (non-test measure) | Dev/QA |
| 6 | R06 | Server trusts client-submitted amounts: tampered split (a + b ≠ total, negative, zero, non-integer cents, above total) accepted | Product | 3 | 4 | 12 | 🟠 HIGH | Server-side validation; EP/BVA at API level; gate case G5 | Dev/QA |
| 7 | R07 | Order placed, ledger or order status wrong after a partial failure (shows paid when refunded, or pending forever) | Product | 3 | 4 | 12 | 🟠 HIGH | State transition cases check order status, payment records and customer-facing message after every outcome | QA |
| 8 | R08 | Same card used for both halves accepted or rejected inconsistently | Product | 2 | 2 | 4 | 🟡 MEDIUM | One analysis case; behaviour to be decided by Product Owner on D1 (assumed: allowed) | QA |
| 9 | R09 | Checkout latency doubles with two sequential gateway calls; front-end or gateway timeout fires before charge 2 completes | Product | 2 | 3 | 6 | 🟡 MEDIUM | Measure end-to-end time on sandbox days; timeout values reviewed against PayGate p99; canary watch on checkout p95 | Dev |
| 10 | R10 | PayGate sandbox behaviour differs from production (decline codes, refund latency), so sandbox passes do not predict production | Product | 3 | 3 | 9 | 🟠 HIGH | Decline-code catalogue from PayGate docs reviewed on D1; canary rollout with a declined-second-card test purchase on a real card by the team on release day | Dev/QA |
| 11 | R11 | Only four sandbox windows; a lost window (outage, build not ready) leaves gate cases unrun before release | Project | 4 | 4 | 16 | 🔴 CRITICAL | Sandbox-facing cases scheduled first on each window; stub-based runs on other days; code freeze on gateway-facing code after D7; if D9 is lost, release decision waits for the next window (2026-11-10) | QA/PO |
| 12 | R12 | Half-time tester (40 h) cannot cover design, execution and reporting; estimate (item 7) uses 38 ± 4 h | Project | 4 | 3 | 12 | 🟠 HIGH | Developers own unit and integration levels; analysis cases below MEDIUM dropped first; progress reported daily against the estimate | QA |
| 13 | R13 | Feature not "Ready for QA" before D4, leaving only two sandbox windows for the gate | Project | 3 | 4 | 12 | 🟠 HIGH | Backend-first delivery: payment service ready for API tests by D3, UI by D5; D2 window used for oracle and sandbox calibration so no window is wasted | Dev |
| 14 | R14 | Acceptance criteria not written; tester and developers interpret edge rules (A6, A7, R08) differently | Project | 3 | 3 | 9 | 🟠 HIGH | Static review of the brief with the three amigos on D1 (`/qa-static`); the 7 test conditions below adopted as acceptance criteria | PO |

**Test conditions derived from the brief and the assumptions** (proposed acceptance criteria):

1. Card 1 amount must be in the range 1 to total − 1 cents (A7); any other value is rejected server-side with a field-level error.
2. Card 2 amount = total − card 1 amount; both are integers in cents; their sum equals the order total.
3. When the customer asks for an even split of an odd total, card 1 receives the extra cent.
4. Charges are sequential: card 1 then card 2; card 2 is not attempted if card 1 is declined.
5. If card 2 is declined, card 1 is refunded within 60 seconds, the order is not placed, and the customer sees why.
6. If the refund fails, the order is marked for manual refund, an alert is raised and the customer is told the refund is being processed.
7. Single-card checkout behaves as before with the feature on and off.

## 6. Test approach

**Pyramid preset:** Backend / API heavy (70% unit, 20% integration, 10% end to end). The split arithmetic, sequencing and compensation all live in the backend service (A1); the UI only collects one amount.

**Levels, who tests, independence:**

| Level | Test object | What it proves | Who tests | Independence | Why this degree |
| :---- | :---------- | :------------- | :-------- | :----------- | :-------------- |
| Component | Split function, validation, state machine | R02, R06 arithmetic and partitions | Developers | None | Cheap, fast, written with the code; the arithmetic is deterministic and the tester reviews the unit test list on D3 |
| Component integration | Payment service with PayGate stub | R01, R04, R05, R07 sequences including timeouts and refund failure, which the sandbox cannot inject on demand | Developer B tests developer A's work | Some | A peer catches assumptions the author made; runs every day, not only Tue/Thu |
| System integration | Staging against PayGate sandbox | Real gateway responses, timing of the 60 s refund, R10 | QA tester | High | Money-handling defects need a different perspective from the authors; the tester is outside the pair that built it |
| Acceptance | Staging, flag on | Business rules 1 to 7 | Product Owner, guided by the tester | High | Validation that the rules match the business intent |

**Types:** functional (all levels), security (amount tampering and idempotency, API level), performance (checkout time measured on sandbox days, no load test), reliability (refund retry and failure paths, integration level with stub). Usability: exploratory session on the split UI (D5), no accessibility audit in this release because the UI change is one amount field on an existing page; accessibility of the new field is one exploratory checklist item.

**Techniques by risk level:**

| Risk level | Technique | Applied to |
| :--------- | :-------- | :--------- |
| CRITICAL (R01, R02, R04, R11) | State transition, all transitions, one invalid transition per case; BVA 3-value; decision table for the outcome matrix (charge 1 × charge 2 × refund result) | Payment state machine; split function; sequencing |
| HIGH (R03, R05, R06, R07, R10) | EP each-choice; BVA 2-value; regression against recorded oracle; error guessing on timeouts and retries | Validation API; order status; single-card checkout |
| MEDIUM (R08, R09) | Happy path plus one negative; measurement | Same-card rule; latency |
| LOW | N/A — no LOW rows in the register |

**Decision table for the outcome matrix** (integration level, all 5 feasible rules are cases):

| Condition | Rule 1 | Rule 2 | Rule 3 | Rule 4 | Rule 5 |
| :-------- | :----: | :----: | :----: | :----: | :----: |
| Charge 1 succeeds | T | F | T | T | T |
| Charge 2 succeeds | T | N/A | F | F | timeout |
| Refund of charge 1 succeeds | – | N/A | T | F | – |
| Action: order placed | X | | | | |
| Action: refund issued ≤ 60 s | | | X | attempted | |
| Action: manual-refund alert | | | | X | X |
| Action: customer told order failed | | X | X | X | X |

**Testing quadrants check:** Q1 unit and integration tests in CI (developers). Q2 API cases for rules 1 to 7 and the acceptance walk-through with the Product Owner. Q3 one 90-minute exploratory session on the split UI with the stub (D5) and one on sandbox (D7). Q4 smoke of single-card checkout, amount-tampering security cases, latency measurement. No quadrant is empty.

**Deliverables:** this plan; test cases TC-SPLIT-001 onward (`/qa-cases`); PayGate stub scenarios list; fixture set (below); sandbox-day results pages (D2, D4, D7, D9); defect reports DR-SPLIT-nnn; go/no-go record (D10); completion report with retrospective.

**Entry criteria, system integration level (start of sandbox execution on D4):**

- [ ] Payment service and UI for split merged to main, CI green on the build under test, build identifier recorded.
- [ ] Staging deployed with that build and pointed at PayGate sandbox; feature flag state recorded.
- [ ] Sandbox test cards for success and for each decline code available in the fixture set.
- [ ] Unit and integration tests for the split function and state machine passing in CI (developer sign-off in the ticket).
- [ ] Logs expose charge, decline and refund timestamps so the 60 s window can be measured.
- [ ] `data-testid` on the split amount field, card forms and the result message: N/A if the front-end stack does not use them; otherwise required.

**Entry criteria, component and component integration levels:** code compiles, stub available (D3), the 5 decision-table rules enumerated in the test file names.

**Exit criteria (release decision on D10):**

- [ ] Every release gate case passed on the release candidate build on D9 (sandbox) or, for G6, in CI on the same build.
- [ ] 100% of P0 cases executed and passed; 100% of P1 cases executed and passed or each failure has a recorded Product Owner exception.
- [ ] Zero open Critical defects; zero open High defects without a Product Owner exception.
- [ ] Single-card smoke passes flag off and flag on, on the release candidate.
- [ ] Residual risk for every CRITICAL row recorded in the go/no-go record.
- [ ] Go/no-go signed by the tester and the Product Owner.
- [ ] If the D9 window is lost (R11), the release waits for 2026-11-10 unless the Product Owner records acceptance of releasing on stub evidence only.

**Release gate** (the only cases whose failure blocks the release):

| ID | What it proves | Level / environment | Risk | Result |
| :- | :------------- | :------------------ | :--- | :----- |
| G1 (TC-SPLIT-001) | Odd total split as evenly as the customer asks: card 1 gets the extra cent, both charges captured, sum equals total, order placed | System integration, staging + sandbox | R02 | N/A — not run yet |
| G2 (TC-SPLIT-002) | Card 2 declined: card 1 refunded, refund acknowledged within 60 s (log timestamps), order not placed, customer told | System integration, staging + sandbox | R01 | N/A — not run yet |
| G3 (TC-SPLIT-003) | Card 1 declined: card 2 never charged, no refund attempted, order not placed | System integration, staging + sandbox | R01, R04 | N/A — not run yet |
| G4 (TC-SPLIT-004) | Single-card checkout unchanged against the D2 oracle, flag off and flag on | System integration, staging + sandbox | R03 | N/A — not run yet |
| G5 (TC-SPLIT-005) | Server rejects card 1 amount of 0, total, total + 1, −1, a non-integer, and a pair not summing to total, even when the UI is bypassed | API, staging | R06 | N/A — not run yet |
| G6 (TC-SPLIT-006) | Refund call fails: order marked for manual refund, alert raised, customer told refund is in progress, no second refund on retry | Component integration with stub, CI | R05 | N/A — not run yet |
| G7 (TC-SPLIT-007) | The same checkout submitted twice (double click or retried request with the same idempotency key) produces exactly one charge per card | System integration, staging + sandbox | R04 | N/A — not run yet |

**Execution order** (risk-based by default; sandbox resource window and dependencies override):

1. G6 — runs first, on D3 in CI, because it needs only the stub and is not bound to a sandbox day.
2. G5 — D3, API level on staging; no sandbox needed.
3. G4 (flag off) — first on D4, because the oracle recorded on D2 is the dependency and it protects the 4,000 daily orders.
4. G2 — D4, highest CRITICAL product risk that needs the real gateway.
5. G1 — D4, after G2 because G2 needs a fresh order anyway and G1's data (odd total) is reused for G3.
6. G3 — D4, depends on the odd-total fixture from G1.
7. G7 — D4 if time allows, otherwise D7; it needs sandbox to confirm PayGate saw one charge.
8. G4 (flag on) — D7, after the full feature is in the build.
9. All seven repeated on the release candidate on D9. Cases moved by the resource window: G1, G2, G3, G4, G7 (sandbox only on Tue/Thu).

**Analysis cases (inform, do not gate):** BVA on total = 2 cents (split 1/1), total = 1 cent (no valid split, rejected), large totals near the gateway's per-transaction limit; same card twice (R08); currency rounding display in the UI; latency measurement (R09); exploratory session on the UI; order history and email content after each outcome (R07); back button and session expiry between the two charges (error guessing). If an analysis finding is traced to the change and would stop the release, its case moves into the gate with a dated note here.

**Metrics collected:**

- Gate cases passed / total, per build (test progress).
- Risk coverage: CRITICAL and HIGH rows with at least one executed case, per sandbox day.
- Open defects by severity (defect).
- Sandbox hours used versus the 12 h planned, and tester hours versus the estimate (project and cost).
- Residual risk level of R01, R04, R11 at the go/no-go (risk).

**Control directives, pre-agreed:** if the build is not ready for D4, D4 is used for G5 and the exploratory session on the stub and the gate shifts to D7, with D9 as the only repeat; if that happens, the Product Owner is asked on D4 whether to move the release. If any CRITICAL gate case fails on D7, gateway-facing code is frozen after the fix and D9 runs the full gate again.

**Test data and environment:** staging pointed at PayGate sandbox; the stub for other days. Fixture set (credentials live in the team vault, never here):

| Fixture | Description | State assumed | May be changed | Rebuild |
| :------ | :---------- | :------------ | :------------- | :------ |
| FX-CARD-OK-1, FX-CARD-OK-2 | PayGate sandbox cards that always approve | Active | Read only | From PayGate sandbox docs |
| FX-CARD-DECLINE-INSUFFICIENT, FX-CARD-DECLINE-GENERIC | Sandbox cards for each decline code in the catalogue | Active | Read only | From PayGate sandbox docs |
| FX-ORDER-ODD | Test customer basket with total 10,001 cents | Basket, unpaid | Written by G1 to G3; recreate after each run | Script `seed-split-orders`: N/A — to be written by the developers by D3 |
| FX-ORDER-SINGLE | Basket for single-card oracle, total 4,999 cents | Basket, unpaid | Written by G4 | Same script |
| FX-STUB-SCENARIOS | Stub responses: approve, decline, timeout-after-success, refund-fail | Versioned in the repo | Read only during a run | Git |

**Non-test measures:** feature flag off by default in production (A4); canary rollout of the flag to 5% of customers for 24 h with checkout error rate, p95 checkout time and refund-alert count watched, rollback by switching the flag off; daily reconciliation of PayGate captures and refunds against orders for the first two weeks; code review of the idempotency key and refund retry.

**Deviations from test policy and strategy:** N/A — no written test policy exists in the brief; this plan follows the package's default strategy. The one deliberate deviation from the default pyramid is that no end-to-end suite is automated in this release: with 40 tester hours, the end-to-end share is run manually on sandbox days and automation of G1, G2 and G4 is logged as debt for release 5.4.

## 7. Estimate

**Technique:** three-point estimation (one estimator, margin must be visible). Tester effort in hours, decomposed:

| Task | a | m | b |
| :--- | :-: | :-: | :-: |
| Static review of brief, acceptance criteria, test design (cases G1–G7 plus analysis) | 6 | 8 | 12 |
| API cases on staging (G5, tampering, BVA) | 4 | 6 | 10 |
| Sandbox execution, 4 windows × 3 h | 12 | 12 | 12 |
| Exploratory sessions (2) | 3 | 4 | 6 |
| Single-card oracle and regression | 2 | 3 | 5 |
| Reporting, defect reports, go/no-go record | 3 | 4 | 6 |
| **Total** | **30** | **37** | **51** |

E = (30 + 4 × 37 + 51) / 6 = 38.2 h; SD = (51 − 30) / 6 = 3.5 h. **Reported as 38 ± 4 h (between 34 and 42 h)** against 40 h available: no slack for a lost sandbox window or a late build (R11, R12). Developer test effort, estimated the same way: 16 / 20 / 30 h gives 20 ± 2 h across both developers for unit tests, the stub, integration tests and the seed script.

**Assumptions behind the figure:** the stub exists by D3; the build is ready for sandbox on D4; no more than 3 defects of High or above need retest on sandbox; the tester already knows the checkout codebase and PayGate's docs.

## 8. Budget and schedule

Budget: N/A — no monetary budget stated; cost is the 40 tester hours and about 20 developer hours above.

| Day | Date | Sandbox | Tester activity (4 h) | Developer test activity |
| :-- | :--- | :-----: | :-------------------- | :---------------------- |
| D1 | Mon 10-26 | | Three amigos static review; confirm A4, A6, A7, R08; test design starts | Decline-code catalogue; idempotency design |
| D2 | Tue 10-27 | Yes | Record single-card oracle on current build; calibrate sandbox cards and decline codes | Stub skeleton |
| D3 | Wed 10-28 | | Finish cases; G5 and G6 on stub/CI | Unit tests for split; stub scenarios; seed script |
| D4 | Thu 10-29 | Yes | Gate run 1: G4 off, G2, G1, G3, G7 on first build | Fixes |
| D5 | Fri 10-30 | | Exploratory session on stub; defect reports; results page | Integration tests (decision table rules 1–5) |
| D6 | Mon 11-02 | | Analysis cases on stub; retest fixes | Fixes; UI complete |
| D7 | Tue 11-03 | Yes | Gate run 2 (all 7) plus sandbox exploratory; gateway code freeze after this day | Fixes only |
| D8 | Wed 11-04 | | Retest on stub; draft go/no-go | Fixes only |
| D9 | Thu 11-05 | Yes | Gate run 3 on the release candidate; final results page | On call for blockers |
| D10 | Fri 11-06 | | Go/no-go record; release with flag off, canary plan handed to the developers | Release; canary watch |

## 9. Configuration management of testware

- This plan, the test cases, the stub scenarios, the seed script and the results pages are versioned in the repository alongside the feature, under a `qa/split-payment/` folder; the plan ID and version appear at the top of each.
- Every result names the build (commit and CI run) and the environment (staging, PayGate sandbox, feature flag state); a result without them is not accepted into a results page.
- The staging environment used on D4, D7 and D9 is recorded as a baseline (application build, stub version where used, flag values, PayGate sandbox API version) in the results page of that day; changes between windows go through the normal deploy record.
- A previous baseline is restored by redeploying the recorded build; the oracle from D2 is kept with its build identifier so G4 remains reproducible.
- CI holds the unit and integration results per commit; gate case G6 is tagged `@gate @integration @p0 @automated` so its pipeline result is traceable to this plan.
- Corrections to this plan after it is shared are made in place with a dated, attributed note, never by deletion.
