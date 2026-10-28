# Test Plan: Split Payment (Release 5.3)

| Field | Value |
| :---- | :---- |
| Plan ID | TP-SPLIT-5.3 v1.0 |
| Date | 2026-10-25 |
| Author | QA (test management role and testing role held by the same person, see item 6) |
| Release date | 2026-11-06 (Friday, working day 10; assumed 10 working days counted from Monday 2026-10-26, no public holidays) |
| Board | N/A — no tracker URL given; assumed JIRA epic "Split payment", ticket IDs written as SPLIT-nnn once known |
| Status | Draft for review by the two developers and the product owner on 2026-10-26 |

## 1. Context of Testing

**Scope, in:**

- Split of one order across two cards: customer enters the first-card amount; the second card takes the remainder.
- Cent arithmetic: amounts handled as integer cents; when an amount cannot be split evenly, the extra cent goes on the first card.
- Two charges through PayGate, in order: first card, then second card.
- Automatic refund of the first charge within 60 seconds when the second charge is declined.
- Order state, receipt and confirmation email showing both charges.
- Regression of the existing single-card checkout (about 4,000 orders a day) with the feature flag on and off.
- PayGate integration contract: charge, decline, refund, timeout and error responses.

**Scope, out:**

- More than two cards (not in the brief).
- Partial refunds, returns and chargebacks after the order is placed (unchanged flows; covered only by the single-card regression suite).
- PayGate's own correctness (external system; tested only at its interface).
- Performance testing under production load (no load environment named; see risk R11 for the measure taken instead).
- Accessibility audit of the new amount field: a scanner pass is in the analysis set; a full WCAG audit is deferred to 5.4 and recorded as a residual risk.

**Objectives:**

1. Show that the two charges always sum to the order total and that the remainder cent lands on the first card.
2. Show that a declined second charge leaves the customer with no money taken, within 60 seconds, every time.
3. Show that single-card checkout behaves exactly as in 5.2.
4. Give the product owner a go/no-go record on 2026-11-05 built from results on PayGate's sandbox, not on a stub.

**Test basis:**

- The feature brief above (the only written requirement; assumptions in item 2 fill its gaps and must be confirmed in the 2026-10-26 review).
- PayGate API documentation for charge, refund, decline codes, minimum charge amount and idempotency keys (assumed to exist; to be fetched by Dev A on day 1).
- Existing single-card checkout test cases and automated suite (assumed to exist and pass on the current main build).

## 2. Assumptions and Constraints

**Assumptions (each one is a question for the day-1 review; the plan proceeds as if the answer is "yes"):**

- A1. The feature ships behind a feature flag `split_payment`, off by default, so single-card checkout runs the 5.2 code path when the flag is off.
- A2. The first-card amount must be at least 1 cent and at most total minus 1 cent; anything else is rejected with a validation message before any charge is made. "Cannot be split evenly" refers to the UI's default "split in half" suggestion on an odd total.
- A3. Charges are sequential: the second card is charged only after the first succeeds. If the first is declined, no second charge is attempted and the order is not placed.
- A4. If the refund call itself fails or times out, the order is marked "refund pending", a retry runs, and an alert reaches payments operations. The brief does not say this; the plan treats it as required behavior because the alternative is a customer charged with no order.
- A5. Each charge carries an idempotency key so a retried submission cannot charge a card twice.
- A6. Card data never reaches application logs; only PayGate tokens are stored (existing PCI posture, unchanged).
- A7. The stack is a web checkout (browser UI plus backend payment service); the split arithmetic, orchestration and refund logic live in the backend service.
- A8. The developers build a PayGate stub (fake) that reproduces the sandbox's real responses captured on day 2, so testing is not limited to two days a week.
- A9. A company test card can make a small real charge in production after release and be refunded.

**Constraints:**

- C1. PayGate sandbox available only on Tuesdays and Thursdays: 2026-10-27, 2026-10-29, 2026-11-03, 2026-11-05. Four windows, the last one the day before release.
- C2. One tester at half time: 4 hours a day, 40 hours across the 10 days.
- C3. Two developers build the feature and write component and integration tests; they are not available as additional system testers.
- C4. Single-card checkout must keep working at about 4,000 orders a day.
- C5. No further sandbox window exists between the final gate run (Thursday 2026-11-05) and release (Friday 2026-11-06). A gate failure found on 2026-11-05 cannot be re-verified on the sandbox before release.

## 3. Stakeholders

| Role | Who (assumed) | Responsibility | Relevance to testing |
| :--- | :------------ | :------------- | :------------------- |
| Product owner | PO of checkout | Confirms assumptions A1 to A9, owns the go/no-go decision, grants exit-criteria exceptions | Decides on 2026-11-05 from the gate record |
| Tester | QA, half time | Test management role and testing role: this plan, test design, system and system-integration execution, reports | Sole independent tester |
| Developer A | Backend | Payment service, PayGate adapter, refund orchestration, unit and integration tests, PayGate stub | Tests own code at component level; runs the day-2 sandbox capture |
| Developer B | Frontend | Amount field, validation, receipt; component tests | Tests own code at component level |
| Payments operations | Finance / support lead | Receives refund-pending alerts, reconciles PayGate statements | Confirms the refund-failed path (A4) is operable |
| Release manager | N/A — assumed the PO also holds this role | Deploys 5.3, flips the flag | Needs the sanity checklist for release day |

## 4. Communication

| Form | Frequency | Audience | Template |
| :--- | :-------- | :------- | :------- |
| Assumption review (30 min) | Once, 2026-10-26 | PO, both developers, tester | This plan, item 2 |
| Progress note in the epic | Each working day the tester works, end of day | Team | Progress report format from the test reporting reference: period, progress against plan, impediments, metrics, new risks, next period |
| Sandbox-day stand-up (10 min) | Each Tuesday and Thursday, 09:00 | Developers, tester | Which cases need the sandbox today and in what order |
| Defect reports | As found | Developers, PO | DR-SPLIT-nnn via `/qa-defect` |
| Go/no-go record | Once, 2026-11-05 end of day | PO | Completion report format: every case one row, build and environment named, residual risks, defects not fixed |
| Retrospective | Once, 2026-11-09 or first working day after release | Whole team | Three questions: keep, improve, carry forward |

## 5. Risk Register

Score = Likelihood (1 to 5) × Impact (1 to 5). Levels: 15 to 25 CRITICAL, 8 to 14 HIGH, 4 to 7 MEDIUM, 1 to 3 LOW.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| :-- | :-- | :--- | :--- | :-- | :-- | :-- | :--- | :--- | :--- |
| 1 | R01 | Two charges do not sum to the order total, or the remainder cent goes on the second card (cent arithmetic, float use, rounding) | Product | 3 | 5 | 15 | 🔴 CRITICAL | Unit tests with BVA and EP on integer cents (odd and even totals, 1 cent, total minus 1); code review bans floating point in the split function; GATE-01 and GATE-02 on sandbox | Dev A / QA |
| 2 | R02 | Second charge declined and the first charge is not refunded, or refunded after 60 seconds | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests of the order state machine; integration test with stubbed decline; GATE-03 on sandbox measuring refund time from decline response to refund confirmation; timer assertion at 60 s | Dev A / QA |
| 3 | R03 | Single-card checkout breaks (4,000 orders a day affected) | Product | 2 | 5 | 10 | 🟠 HIGH | Feature flag off by default (A1); full existing regression suite run with flag off and on; GATE-05; production sanity after release | QA / Dev B |
| 4 | R04 | Duplicate charge on resubmission, double click or network retry | Product | 3 | 4 | 12 | 🟠 HIGH | Idempotency key per charge (A5); integration test replaying the same request; GATE-08 on sandbox; error guessing session | Dev A / QA |
| 5 | R05 | First charge declined but second card still charged, or order placed | Product | 2 | 4 | 8 | 🟠 HIGH | Decision table over charge outcomes; GATE-04 on sandbox | Dev A / QA |
| 6 | R06 | First-card amount boundaries mishandled: 0, equal to total, above total, negative, fractional cents, non-numeric | Product | 3 | 3 | 9 | 🟠 HIGH | 3-value BVA on the amount field at component and API level; server-side validation tested directly, not only through the UI; GATE-06 | Dev B / QA |
| 7 | R07 | Refund call fails or times out, leaving a charged customer with no order and nobody alerted | Product | 3 | 4 | 12 | 🟠 HIGH | Stub injects refund timeout and 5xx; test retry, "refund pending" state and alert to payments operations (A4); runbook reviewed with operations | Dev A / Ops |
| 8 | R08 | Card data or full PAN written to logs or error payloads for the second card path | Product | 2 | 4 | 8 | 🟠 HIGH | Log inspection after every sandbox run; security checklist from the reference; grep of logs for 13 to 19 digit sequences | QA |
| 9 | R09 | Customer abandons or loses connection between the two charges; order left half paid | Product | 2 | 3 | 6 | 🟡 MEDIUM | State transition test for abandon after charge 1; background reconciliation job verified on stub | Dev A |
| 10 | R10 | Receipt, confirmation email or admin order view shows wrong per-card amounts | Product | 3 | 2 | 6 | 🟡 MEDIUM | Checklist-based manual check on the sandbox run; one component test on the receipt renderer | Dev B / QA |
| 11 | R11 | Checkout latency doubles from two sequential PayGate calls and times out the UI | Product | 2 | 3 | 6 | 🟡 MEDIUM | Measure end-to-end time on sandbox for GATE-01; accept if under the existing checkout timeout with 50 percent margin; no load test (out of scope, residual) | QA |
| 12 | R12 | PayGate rejects a 1-cent charge (minimum amount) and the UI lets the customer pick it | Product | 2 | 3 | 6 | 🟡 MEDIUM | Confirm the minimum in PayGate docs on day 1; align validation (A2) to it; BVA case at the minimum | Dev B |
| 13 | R13 | Same card entered twice, or second card is the first card's token | Product | 2 | 2 | 4 | 🟡 MEDIUM | Exploratory session; PO decides whether to allow it (assumed allowed; no test beyond the session) | PO |
| 14 | P01 | Sandbox only on Tuesdays and Thursdays: four windows in the release period, last one the day before release | Project | 5 | 4 | 20 | 🔴 CRITICAL | PayGate stub built from day-2 captures (A8) for all non-sandbox days; sandbox days reserved for gate runs only; contingency in item 8 if the 2026-11-05 run fails | Dev A / QA |
| 15 | P02 | Tester at half time: 40 hours for design, execution, regression and reporting | Project | 4 | 3 | 12 | 🟠 HIGH | Developers own all component and integration tests; existing regression suite runs in CI, not by hand; tester effort tracked daily against the estimate in item 7 | QA / PO |
| 16 | P03 | Feature not "Ready for QA" by 2026-10-30, pushing system testing into the final sandbox window | Project | 3 | 4 | 12 | 🟠 HIGH | Entry criteria checked on day 5; if missed, the PO is told the same day that 2026-11-03 becomes the first and only full gate run and release risk rises | Devs / PO |
| 17 | P04 | Stub behaves differently from real PayGate (wrong decline codes, refund latency, response shapes) | Project | 3 | 4 | 12 | 🟠 HIGH | Stub responses recorded from the sandbox on 2026-10-27, not invented; contract test of the adapter against the sandbox on 2026-10-29; every gate case re-run on the real sandbox | Dev A |
| 18 | P05 | Sandbox refund latency not representative of production, so the 60-second check proves little | Project | 3 | 3 | 9 | 🟠 HIGH | Ask PayGate for production refund SLA on day 1; measure sandbox latency on every sandbox run and record it; production sanity charge-and-refund after release (A9) | QA / PO |

Residual risks accepted if the plan runs as written: R11 (no load test), R13 (same card twice), accessibility audit of the amount field (deferred). The register is re-scored at each daily progress note and corrections are dated in place.

## 6. Test Approach

**Pyramid preset.** Backend / API: 70 percent unit, 20 percent integration, 10 percent end-to-end. The business logic (cent split, charge sequencing, refund, state machine) lives in the backend payment service (A7). The UI contributes one amount field and a receipt, covered by component tests and a small number of end-to-end cases.

**Test levels, who tests, independence:**

| Level | Test object | What it proves | Who tests | Independence | Why that degree fits |
| :---- | :---------- | :------------- | :-------- | :----------- | :------------------- |
| Component | Split function, validation, order state machine, receipt renderer | R01, R06, R09, R10 at the cheapest layer | Dev A, Dev B on their own code | None | Developers find defects in their own units fastest; the tester reviews the test code for the ability to fail (`/qa-review`) |
| Component integration | Payment service with PayGate adapter against the stub | R02, R04, R05, R07 with injected declines, timeouts and 5xx | Dev A writes; tester reviews the scenarios against the decision table | None, with a peer review | The stub makes failure injection possible every day; the review adds a second perspective on the scenarios |
| System | Whole checkout, flag on, against the stub | Gate and analysis cases rehearsed; regression suite | Tester | High | Only person outside the authors; needed for the CRITICAL product risks |
| System integration | Whole checkout against the PayGate sandbox | Every gate case on the real gateway; log inspection | Tester, developers on call | High | The result that gates the release must come from the real integration |
| Acceptance | Gate record and a demo on the sandbox | Business validation and go/no-go | PO | High (business) | The PO is the decision owner |

**Test types.** Functional at every level. Non-functional: security (log and payload inspection, R08), performance as a single measured timing on the sandbox (R11), reliability of the refund path (R07). Black-box techniques dominate; branch coverage is read for the split and state-machine modules.

**Techniques by risk level:**

| Risk level | Techniques | Where |
| :--------- | :--------- | :---- |
| CRITICAL (R01, R02) | 3-value BVA on cents; decision table over (charge 1 outcome × charge 2 outcome × refund outcome); state transition with all-transitions coverage on the order state machine, one invalid transition per case | Unit, integration, gate |
| HIGH (R03 to R08) | EP and 2-value BVA; decision table; error guessing on retries and double submission; checklist for logs | Integration, system, gate |
| MEDIUM (R09 to R13) | Happy path plus one exploratory session (charter: "break the order between the two charges") | System, analysis |

**Coverage floors.** Split and state-machine modules: 80 percent branch coverage, read, not chased. Critical path requirements coverage: every objective in item 1 and every CRITICAL and HIGH risk traced to at least one case, 100 percent.

**Testing quadrants check.** Q1: component and integration tests in CI (developers). Q2: gate and analysis cases, BDD scenarios for the three charge outcomes written with `/qa-bdd` on day 1. Q3: one exploratory session (R09, R13) and the PO's acceptance demo. Q4: smoke suite in CI, security log check, one latency measurement. Nothing in Q4 covers load; said in scope-out and R11.

**Deliverables:** this plan; BDD scenarios; test cases TC-SPLIT-001 onward; PayGate stub response catalogue (developers); fixture set below; daily progress notes; defect reports; go/no-go record of 2026-11-05; completion report after release.

**Entry criteria, system and system-integration execution (checked 2026-10-30):**

- [ ] Split payment stories marked Ready for QA, with assumptions A1 to A9 confirmed or corrected in writing.
- [ ] Main build green in CI, including the existing single-card regression suite with the flag off and on.
- [ ] Component and integration tests merged with the feature, branch coverage visible for the split and state-machine modules.
- [ ] Staging deployed with the build identifier recorded, flag switchable per environment.
- [ ] PayGate stub reproduces the day-2 sandbox captures: approved, declined (at least two decline codes), refund success, refund timeout, 5xx.
- [ ] Sandbox credentials and test cards for approve and decline in the fixture set.
- [ ] `data-testid` on the amount field, card forms, submit button and receipt lines.

Entry criteria for component and integration levels: the story is understood and the stub interface agreed (day 1). They start with the code.

**Exit criteria (release):**

- [ ] Every release gate case passed on the PayGate sandbox, on the release candidate build, on 2026-11-03 or 2026-11-05.
- [ ] 100 percent of P0 cases and 100 percent of P1 cases passed, or a recorded PO exception per P1 failure.
- [ ] Zero open Critical defects; zero open High defects or a recorded PO exception.
- [ ] Existing single-card regression suite green on the release candidate with the flag off and on.
- [ ] No card data found in logs from any sandbox run.
- [ ] Refund time measured under 60 seconds on every GATE-03 run.
- [ ] Go/no-go record signed by QA and the PO.

Running out of sandbox days ends testing only if the PO reviews and accepts the risk in writing.

**Release gate (built from risk; a failure here blocks):**

| Gate ID | Case | What it proves | Register link | Result |
| :------ | :--- | :------------- | :------------ | :----- |
| GATE-01 | Even split, both approved | Two charges sum to the total; order placed; receipt shows both | R01 | N/A — not yet run |
| GATE-02 | Odd total, default half split | Remainder cent on the first card; sum equals total | R01 | N/A — not yet run |
| GATE-03 | First approved, second declined | First charge refunded automatically, measured under 60 s; order not placed; customer told | R02 | N/A — not yet run |
| GATE-04 | First declined | No second charge attempted; order not placed | R05 | N/A — not yet run |
| GATE-05 | Single-card checkout, flag off and flag on | Behavior identical to 5.2 on the existing regression suite | R03 | N/A — not yet run |
| GATE-06 | First amount at the boundaries: 0, 1, total minus 1, total, total plus 1 | Only 1 to total minus 1 accepted; rejection happens before any charge | R06 | N/A — not yet run |
| GATE-07 | Second declined and refund call times out | Order enters refund pending, retry succeeds, operations alert fired | R07 | N/A — not yet run |
| GATE-08 | Submit twice with the same idempotency key | Exactly one charge per card on the PayGate statement | R04 | N/A — not yet run |

**Execution order for the gate (risk-based, with resource and dependency overrides):**

1. GATE-05 on the stub environment, day 5 (2026-10-30), before anything else: it needs no sandbox and a failure here is the cheapest to find early. Repeated on the release candidate on day 9.
2. GATE-06 on the stub, day 5: validation runs before any charge, so it needs no sandbox; moved ahead of CRITICAL cases for that reason.
3. GATE-01, then GATE-02, on the sandbox on 2026-11-03: GATE-01 first because every other sandbox case depends on an approved first charge working.
4. GATE-03 on the sandbox on 2026-11-03, timed with a stopwatch from the decline response to the refund confirmation in PayGate.
5. GATE-04 on the sandbox on 2026-11-03.
6. GATE-08 on the sandbox on 2026-11-03: needs PayGate's statement to count charges.
7. GATE-07 on the stub on 2026-10-30 and 2026-11-02 (the sandbox cannot be made to time out on demand); re-checked on the sandbox on 2026-11-05 only for the "refund pending" state display, which the sandbox can show.
8. Full re-run of 1 to 6 on the release candidate on 2026-11-05, after confirmation testing of any fixes from 2026-11-03.

**Analysis cases (inform, do not gate):** exploratory session on abandonment and connection loss between charges (R09); same card twice (R13); receipt and email content (R10); latency measurement (R11); minimum charge at 1 cent (R12); log inspection (R08, which moves into the gate if any card data is found, with the date noted here). Findings not caused by this change are logged as their own tickets and linked from the plan.

**Metrics collected:**

| Metric | Decision it informs |
| :----- | :------------------ |
| Gate cases run, passed, failed, blocked, per sandbox day | Whether 2026-11-05 is a confirmation run or a first run |
| Open defects by severity | Exit criteria, PO exceptions |
| Risk coverage: CRITICAL and HIGH risks with at least one executed case | Whether residual risk is known or unknown |
| Refund time on each GATE-03 run, in seconds | Pass or fail on R02; representativeness (P05) |
| Tester hours used against the estimate in item 7 | Whether to drop analysis cases or ask for help |

**Test data and environment requirements (fixture set):**

| Record | Description | State assumed | May be changed | Rebuild |
| :----- | :---------- | :------------ | :------------- | :------ |
| FX-CARD-OK-1, FX-CARD-OK-2 | PayGate sandbox test cards that approve | Active | Read only | From PayGate sandbox docs |
| FX-CARD-DECLINE | Sandbox card that declines every charge | Active | Read only | From PayGate sandbox docs |
| FX-CARD-DECLINE-2ND | Card or amount pattern that declines only above a threshold, used as second card | Active | Read only | From PayGate sandbox docs; if none exists, use FX-CARD-DECLINE as the second card |
| FX-ORDER-EVEN | Cart totalling 10000 cents | Unpaid | Written by tests; reset after each run | Seed script, Dev A |
| FX-ORDER-ODD | Cart totalling 10001 cents | Unpaid | Written by tests; reset after each run | Seed script, Dev A |
| FX-ORDER-MIN | Cart totalling 2 cents | Unpaid | Written by tests | Seed script |
| FX-STUB-CATALOGUE | Recorded sandbox responses, versioned | Matches 2026-10-27 captures | Changed only by Dev A with a version bump | Re-capture on a sandbox day |
| Sandbox credentials | Location: team secret store | N/A — not recorded here | Off limits | PayGate account owner |

Environments: staging with stub (every day), staging pointed at the PayGate sandbox (Tuesdays and Thursdays), production for the post-release sanity. Each result names the build identifier and which PayGate target was in use.

**Deviations from the test policy and strategy:** two. The release gate is run on the sandbox only twice instead of on every candidate build, because of C1. The PO acceptance is a demo on the sandbox rather than a separate UAT cycle, because of C2.

## 7. Estimate

Technique: three-point estimation for the tester, since there is one estimator and no history for a two-card flow. Developer test effort by ratio against their build effort.

Tester effort, decomposed:

| Task | a | m | b |
| :--- | :-- | :-- | :-- |
| Assumption review, BDD scenarios, test cases, fixture set | 5 | 7 | 10 |
| Day-2 sandbox capture with Dev A, stub review | 2 | 3 | 5 |
| Review of developer unit and integration tests | 2 | 3 | 5 |
| Stub-based system run and regression (days 5 and 6) | 5 | 7 | 10 |
| Sandbox gate runs (2026-11-03 and 2026-11-05) | 6 | 8 | 12 |
| Exploratory session, log inspection | 2 | 3 | 4 |
| Defect reports, confirmation testing | 1 | 3 | 6 |
| Daily notes, go/no-go record, completion report | 2 | 3 | 4 |
| Total (hours) | 25 | 37 | 56 |

E = (25 + 4 × 37 + 56) / 6 = 38 hours. SD = (56 − 25) / 6 = 5 hours. Reported as 38 ± 5 hours, between 33 and 43 hours, against 40 hours available. The pessimistic case exceeds availability; item 8 says what is dropped first.

Developer test effort: ratio of 2 development hours to 1 test hour, assumed from similar payment work. With two developers at 8 days of build each, that is roughly 40 to 55 hours of component, integration and stub work. Assumptions: the stub takes under a day; no third rework cycle; the existing regression suite runs in CI without manual effort.

## 8. Budget and Schedule

Budget: N/A — no monetary budget given; effort in item 7 is the budget. No new tooling is needed; the PayGate stub is built in-house.

| Day | Date | Sandbox | Activity |
| :-- | :--- | :------ | :------- |
| 1 | Mon 2026-10-26 | No | Assumption review; BDD scenarios; stub interface agreed; PayGate minimum amount and refund SLA checked |
| 2 | Tue 2026-10-27 | Yes | Capture real responses: approve, declines, refund, refund latency. These become the stub catalogue and the oracle |
| 3 | Wed 2026-10-28 | No | Developers build; tester writes gate and analysis cases, fixture seed script reviewed |
| 4 | Thu 2026-10-29 | Yes | Contract test of the PayGate adapter against the sandbox, even if the feature is incomplete |
| 5 | Fri 2026-10-30 | No | Entry criteria checked. GATE-05, GATE-06, GATE-07 on the stub |
| 6 | Mon 2026-11-02 | No | Remaining gate cases rehearsed on the stub; regression suite; exploratory session |
| 7 | Tue 2026-11-03 | Yes | First full gate run on the sandbox, release candidate build RC1. Defects filed same day |
| 8 | Wed 2026-11-04 | No | Fixes; confirmation on the stub; RC2 built |
| 9 | Thu 2026-11-05 | Yes | Confirmation and full gate re-run on the sandbox against RC2. Go/no-go record to the PO by end of day |
| 10 | Fri 2026-11-06 | No | Release with flag off; flag on in production; sanity charge-and-refund with the company test card (A9); logs checked |

**Contingencies, decided in advance:**

- If entry criteria are missed on day 5, 2026-11-03 becomes the first and only full gate run and the PO is told that day that release carries one sandbox run instead of two.
- If any gate case fails on 2026-11-05 and cannot be confirmed on the sandbox before release, the options are to ship 5.3 with the flag off and enable it after a sandbox confirmation on Tuesday 2026-11-10, or to slip the release. The plan recommends shipping with the flag off: single-card checkout is protected (R03) and the feature waits two working days.
- If tester hours reach the pessimistic estimate, the analysis cases for R10, R11 and R13 are dropped first and recorded as not run with a resume point.

## 9. Configuration Management of Testware

- This plan, the BDD scenarios, the test cases, the stub catalogue and the seed script are versioned in the repository alongside the feature, under a `qa/split-payment` folder, each with an identifier and version. Corrections to shared documents are made in place with a dated note, never deleted.
- Every result names the build identifier (commit and pipeline run), the environment, the flag state and the PayGate target (stub catalogue version or sandbox). A result without these is not accepted as evidence.
- The staging environment used for the gate is a baseline: application build, flag configuration, stub catalogue version and PayGate sandbox account. It changes only through the normal deploy pipeline, and the deploy record is the source of truth for what ran, not the branch name.
- The stub catalogue is itself a configuration item: re-captured only on a sandbox day, version bumped, and the version recorded in every stub-based result so a later reader knows which real responses it reflected.
- Earlier baselines (RC1 of 2026-11-03) remain deployable so a disputed result can be reproduced.
- CI runs component, integration and the existing regression suite on every push; the sandbox runs are manual and their evidence (screenshots, PayGate statement export, refund timing) is attached to the test cases in the tracker.
