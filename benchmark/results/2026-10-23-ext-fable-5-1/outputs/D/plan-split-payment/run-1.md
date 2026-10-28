# Test Plan — Split Payment (Release 5.3)

**Plan ID:** TP-SPLIT-5.3 · **Version:** 1.0 · **Date:** 2026-10-24 · **Release date:** 2026-11-07 (10 working days) · **Owner (test management role):** the tester · **Board:** N/A — no tracker URL given; assumed to be the team's existing board, ticket SPLIT-5.3

## 1. Context of Testing

**Test object.** The split-payment checkout path: amount entry, cent-level split, two sequential PayGate charges, automatic refund of charge 1 when charge 2 is declined, and the order outcome recorded after each path.

**Objectives.**

- Show that the split never loses or creates a cent, for every amount and split the customer can enter.
- Show that a declined second charge leaves the customer with no money taken: charge 1 is refunded within 60 seconds, every time, including when the refund call itself fails.
- Show that the single-card checkout (about 4,000 orders a day) behaves exactly as before.
- Produce a go/no-go record for 2026-11-07 against the release gate in item 6.

**Test basis.** The feature brief; the PayGate API documentation for charge, refund and decline codes (assumed available); the current single-card checkout behaviour as the regression baseline; the team's existing checkout automation (assumed to exist, see item 2).

**In scope.** Split amount validation; cent arithmetic and the remainder rule; both charge calls and their order; decline of card 1, decline of card 2, refund success and refund failure; the 60-second refund deadline; timeouts and duplicate submissions; order and payment records after every path; single-card regression; PayGate contract conformance.

**Out of scope.** Three or more cards (not in the brief); saved-card and wallet payments (assumed unchanged); PayGate's internal behaviour beyond its contract; load testing of the split path itself (volume is unknown and the single-card path carries the daily load, see R11 for the regression performance check); accessibility of the new form beyond a one-pass check (time-boxed, see item 7).

## 2. Assumptions and Constraints

| # | Statement | Type |
| --- | --- | --- |
| A1 | Charges run in order: card 1 first, then card 2. Only "card 2 declined" triggers the refund; if card 1 declines, nothing is charged and the customer is told. | Assumption |
| A2 | "Declined" covers any non-success outcome of charge 2: hard decline, soft decline, timeout, gateway error. The brief says "declined"; the plan tests all four and flags the interpretation to the Product Owner. | Assumption |
| A3 | Minimum amount per card is 1 cent; the customer cannot enter 0 or a value equal to or above the order total on card 1 (a split of 0 is a single-card order). Maximum is the order total minus 1 cent. | Assumption |
| A4 | "Within 60 seconds" is measured from the moment the decline response for charge 2 is received to the moment PayGate acknowledges the refund request. | Assumption |
| A5 | PayGate supports idempotency keys on charge and refund calls, and the developers use them. If not, R04 is re-scored up. | Assumption |
| A6 | The developers provide a PayGate stub (a fake that returns configurable outcomes: success, decline codes, timeout, error) so that the five non-sandbox days are usable. This is a planned deliverable, not an existing one. | Assumption |
| A7 | The existing single-card checkout has an automated regression suite that runs in CI. If it does not, R10 is re-scored up and the first two days build a smoke set for it. | Assumption |
| A8 | The order rounding and tax calculations happen before the split; the split receives one final total in cents. | Assumption |
| A9 | The feature ships behind a feature flag, off by default in production, so single-card customers are never exposed before the flag is turned on. If no flag exists, R10 and R12 are re-scored up. | Assumption |
| C1 | PayGate sandbox: Tuesdays and Thursdays only. Four windows before release: 2026-10-28, 2026-10-30, 2026-11-04, 2026-11-06. | Constraint |
| C2 | Tester at half time: 10 days × 4 h = about 40 h. Two developers full time on the feature. | Constraint |
| C3 | Release 2026-11-07 (Friday). The last sandbox window, 2026-11-06, is the day before release, so only one day of fix time follows it. | Constraint |
| C4 | Single-card checkout: about 4,000 orders a day. No outage or behaviour change tolerated. | Constraint |

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| --- | --- | --- | --- |
| Product Owner | N/A — not named; assumed to exist | Owns acceptance, approves exceptions, confirms A1 to A4 | Decides go/no-go, confirms the "declined" interpretation |
| Test management role and testing role | The tester | Plan, risk register, gate, system-level cases, exploratory sessions, reports | Half time; owns the sandbox windows |
| Developers (2) | Feature developers | Unit and integration tests, PayGate stub, contract tests, fixes | Hold the testing role at component level; one developer is the stub owner |
| Payments or finance | N/A — not named; assumed to exist | Confirms refund accounting and reconciliation rules | Verifies that refunds land correctly in the ledger (R06) |
| Operations | N/A — not named; assumed to exist | Deploys, owns the feature flag and the rollback | Executes the rollback plan in R12 |
| PayGate support | External | Sandbox access and decline-simulation documentation | Only reachable on sandbox days; questions are batched |

## 4. Communication

| Form | Frequency | Content |
| --- | --- | --- |
| Stand-up note (chat) | Daily | Cases run, blocked, defects open, next sandbox-day plan |
| Progress report (board page, template in `references/test-reporting.md`) | After each sandbox day (4 times) | Testing period, progress against plan, metrics, new or re-scored risks, next period |
| Risk register review | With each progress report | Re-score rows whose facts changed, with a dated note |
| Completion report and go/no-go record | Once, 2026-11-06 evening or 2026-11-07 morning | Every case, one per row, with build and environment; "Not run — resume point" |
| Retrospective | Once, the week after release | Whole team; actions with owner and date |

Templates: this plan; test cases in TC-SPLIT-NNN format; defect reports in DR-SPLIT-NNN format; the reporting table from `references/test-reporting.md`.

## 5. Risk Register

Score = Likelihood (1–5) × Impact (1–5). 15–25 CRITICAL, 8–14 HIGH, 4–7 MEDIUM, 1–3 LOW.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Card 2 is declined and charge 1 is not refunded, or is refunded late (over 60 s): customer loses money | Product | 3 | 5 | 15 | 🔴 CRITICAL | Unit tests of the refund decision for every charge-2 outcome; integration test with stub measuring elapsed time; sandbox E2E with a real decline code; alert on refund failures in production; gate case G1 | Dev/QA |
| 2 | R02 | Refund call itself fails (timeout, gateway error) and the failure is swallowed: charge 1 stands, nobody knows | Product | 3 | 5 | 15 | 🔴 CRITICAL | Retry with backoff inside the 60 s budget; persisted "refund pending" state and a reconciliation job or alert; stub test for refund timeout; gate case G2 | Dev/QA |
| 3 | R03 | Cent arithmetic wrong: odd remainder goes to card 2, rounding of a float, sum of the two charges differs from the order total | Product | 3 | 5 | 15 | 🔴 CRITICAL | Pure function with unit tests by equivalence partitioning and boundary values (1 cent, odd totals, large totals, card 1 = total − 1); property test "charge1 + charge2 = total"; gate case G3 | Dev |
| 4 | R04 | Double charge: retried or duplicated submission charges card 1 or card 2 twice | Product | 3 | 5 | 15 | 🔴 CRITICAL | Idempotency key per charge (A5); integration test replaying the same request; sandbox test with a forced timeout then retry; gate case G4 | Dev/QA |
| 5 | R05 | Card 1 declined but card 2 still charged, or order marked paid with one charge missing | Product | 2 | 5 | 10 | 🟠 HIGH | State-transition test of the payment state machine (none → charge1 ok → charge2 ok → paid, with every failure arc); gate case G5 | Dev/QA |
| 6 | R06 | Refund recorded against the wrong charge, wrong amount, or not visible to finance reconciliation | Product | 2 | 4 | 8 | 🟠 HIGH | Assert the refund amount equals charge 1 and references its transaction ID; finance confirms one sandbox refund in the ledger view | QA/Finance |
| 7 | R07 | Split amount validation lets through 0, negative, non-numeric, more than the total, or sub-cent values | Product | 3 | 3 | 9 | 🟠 HIGH | Boundary-value analysis on the input (0, 1, total − 1, total, total + 1, 2 decimals vs 3); server-side validation tested at API level, not only in the UI | Dev/QA |
| 8 | R08 | Customer sees the wrong outcome: order shown as paid after a failed charge 2, or as failed after a successful refund with no explanation | Product | 3 | 3 | 9 | 🟠 HIGH | E2E on each outcome path checks the confirmation page and the email or receipt; exploratory session on messaging | QA |
| 9 | R09 | Partial failure after charge 2 succeeds (order service down): both cards charged, no order | Product | 2 | 5 | 10 | 🟠 HIGH | Developer review of the transaction boundary; chaos step in the integration test: kill the order write after charge 2; accept with monitoring if not fixable in 10 days, recorded as an exception | Dev |
| 10 | R10 | Single-card checkout breaks or slows: shared code path changed, 4,000 orders a day affected | Product | 2 | 5 | 10 | 🟠 HIGH | Impact analysis of the diff by the developers; full existing regression suite on every build (A7); smoke on production after flag-off deploy; feature flag off by default (A9); gate case G6 | Dev/QA/Ops |
| 11 | R11 | Single-card checkout latency grows because the new code adds a call or a lock on the shared path | Product | 2 | 4 | 8 | 🟠 HIGH | Compare p95 checkout latency on staging before and after the build, same load script; threshold: no more than 10% growth, else investigate | Dev |
| 12 | R12 | No safe rollback: feature flag missing or flag-off path untested | Project | 2 | 5 | 10 | 🟠 HIGH | Test the flag-off state on staging (G6 runs with the flag off and then on); documented rollback step for Ops; dry-run the rollback once | Ops/QA |
| 13 | R13 | PayGate sandbox available only 4 days before release; a defect found on 2026-11-06 cannot be re-verified on the sandbox before release | Project | 4 | 4 | 16 | 🔴 CRITICAL | Stub-first strategy (A6): everything that can be proven on the stub is proven before each sandbox day; sandbox days run the gate and contract cases only; decline simulation codes confirmed on day one; contingency: if a gate case fails on 2026-11-06, release slips or ships flag-off | QA/Dev |
| 14 | R14 | Stub behaves differently from the real PayGate (different decline codes, response shapes, timing) | Project | 3 | 4 | 12 | 🟠 HIGH | Record real sandbox responses on 2026-10-28 and build the stub from the recordings; contract test comparing stub and sandbox on each sandbox day | Dev |
| 15 | R15 | Tester capacity (40 h) too small: cases unwritten or unrun at release | Project | 4 | 3 | 12 | 🟠 HIGH | Developers own unit, integration and stub tests; tester owns the gate, sandbox days and exploration; risk-based cut order in item 6; time-boxed exploration | Tester/PO |
| 16 | R16 | Feature not code-complete before the third sandbox window (2026-11-04), leaving one real-gateway run | Project | 3 | 4 | 12 | 🟠 HIGH | Entry criteria checked on 2026-10-31; if not met, the PO is told the same day and the release decision is re-planned | Dev/PO |
| 17 | R17 | Unclear requirement: what "declined" covers, and what happens when the refund exceeds 60 s (A2, A4) | Project | 3 | 3 | 9 | 🟠 HIGH | Assumptions A1 to A4 sent to the PO on 2026-10-27 for confirmation; test cases written against the assumptions and corrected with a dated note if the PO disagrees | PO/QA |
| 18 | R18 | Currency or locale display of the two amounts wrong (separator, symbol) | Product | 2 | 2 | 4 | 🟡 MEDIUM | Exploratory session with the team's supported locales; no automation | QA |
| 19 | R19 | Accessibility of the split form (labels, errors announced) | Product | 2 | 2 | 4 | 🟡 MEDIUM | One axe-core pass and keyboard check, 1 hour, findings logged as separate tickets | QA |
| 20 | R20 | Test data: sandbox cards with known decline behaviour unavailable or undocumented | Project | 2 | 3 | 6 | 🟡 MEDIUM | Confirm card numbers and codes from PayGate documentation before 2026-10-28; fixture set in item 6 | QA |

## 6. Test Approach

**Pyramid preset.** Backend / API: 70% unit, 20% integration, 10% E2E. The business logic (split arithmetic, charge sequencing, refund decision, state machine) lives in the backend; the UI is a form with two fields. Approximate case counts: 35–45 unit, 10–14 integration, 6–8 E2E (the gate plus one or two more).

**Test levels, who tests, independence.**

| Level | What | Who tests | Independence | Why this degree |
| --- | --- | --- | --- | --- |
| Component | Split arithmetic, validation, refund decision, state machine | The developer who wrote it, reviewed by the other developer | None to some | Fast feedback; the tester reviews the test list against R03 and R05 so the author's blind spots are covered |
| Component integration | Payment service against the PayGate stub: sequencing, idempotency, refund retry, timing | The other developer (not the author) | Some | Pairing the developers keeps stub and service honest with each other; the tester reviews |
| System | Full checkout on staging with the stub, then with the sandbox | The tester | High (outside the authors) | CRITICAL product risks about money need a tester who does not share the authors' assumptions |
| Acceptance | Each outcome path shown to the PO on a sandbox day | PO with the tester | High | Business confirmation of A1 to A4 in the running system |
| Regression (single-card) | Existing automated suite, smoke on staging and production | CI, read by the tester | Some | Automated suite is the existing baseline; the tester owns the pass/fail reading |

**Test types.** Functional (all levels); non-functional: refund timing (R01), single-card latency (R11), one accessibility pass (R19); structural: branch coverage on the split and refund modules, target 100% branches on those two modules only; change-related: confirmation of each fix and regression of single-card checkout on every build.

**Techniques per risk.**

- R03 cent arithmetic: equivalence partitioning and boundary-value analysis on the total and the card 1 amount (1, 2, odd, even, 999, 1000, 10^7 cents; card 1 at 1 and total − 1); property test that the two charges sum to the total and card 1 carries the odd cent.
- R07 validation: BVA on the input field at API level: 0, 1, total − 1, total, total + 1, negative, non-numeric, 3 decimals, empty.
- R01, R02, R05 outcome paths: decision table with conditions charge 1 result × charge 2 result × refund result; state-transition testing of the payment state machine with every valid and invalid transition.
- R04 idempotency: replay of the same request after a timeout, with the stub and the sandbox.
- R08, R18, R19: exploratory sessions, charter-based, time-boxed.
- Regression: the existing single-card suite, scoped by the developers' impact analysis of the diff.

**Quadrants check.** Q1: unit and integration tests in CI. Q2: the decision-table and state-transition cases, the API validation cases, the acceptance run with the PO. Q3: three exploratory sessions (outcome messaging, locale, accessibility). Q4: smoke suite, refund timing measurement, single-card latency comparison. No quadrant is empty.

**Deliverables.** This plan; test cases TC-SPLIT-001 onward; stub recordings; four progress reports; defect reports DR-SPLIT-NNN; completion report with go/no-go record; retrospective actions.

**Entry criteria for system-level execution (checked 2026-10-31, before the third sandbox window).**

- [ ] Feature code-complete behind the flag, merged, build green with the unit and integration suites passing.
- [ ] Stub (A6) in place and built from the 2026-10-28 sandbox recordings.
- [ ] Staging deployed with the build identified by version; flag toggle confirmed working.
- [ ] Fixture set below available; sandbox card numbers and decline codes confirmed.
- [ ] PO has answered A1 to A4 (or the assumptions stand by default, recorded in the plan).
- [ ] Form elements carry `data-testid` attributes.

**Exit criteria for the release.**

- [ ] All six release gate cases pass on the sandbox, on the release candidate build, on 2026-11-06 at the latest.
- [ ] 100% of P0 cases executed and passing; 100% of P1 executed and passing or each failure has a recorded PO exception.
- [ ] Zero open Critical defects; zero open High defects without a PO exception.
- [ ] Single-card regression suite green on the release candidate; single-card p95 latency within 10% of baseline.
- [ ] Flag-off state verified on staging; rollback step written and dry-run once.
- [ ] Completion report signed off by the tester and the PO.
- [ ] Running out of time ends testing only if the PO records acceptance of the untested risk.

**Release gate.**

| ID | What it proves | Level | Risk | Result |
| --- | --- | --- | --- | --- |
| G1 (TC-SPLIT-001) | Card 2 hard decline: charge 1 refunded, refund acknowledged within 60 s, order not paid, customer told | E2E sandbox | R01 | N/A — not yet run |
| G2 (TC-SPLIT-002) | Card 2 declined and refund call times out: retried, refund lands within 60 s or order enters "refund pending" with an alert raised, never silent | Integration (stub) + sandbox if PayGate can simulate a refund failure | R02 | N/A — not yet run |
| G3 (TC-SPLIT-003) | Odd total (e.g. 10,001 cents) split: card 1 gets the extra cent, both charges sum to the total, amounts shown match | Unit + E2E sandbox | R03 | N/A — not yet run |
| G4 (TC-SPLIT-004) | Charge timeout followed by retry produces one charge per card, not two | Integration (stub) + sandbox | R04 | N/A — not yet run |
| G5 (TC-SPLIT-005) | Card 1 declined: no charge on card 2, no refund, order unpaid, customer told | E2E sandbox | R05 | N/A — not yet run |
| G6 (TC-SPLIT-006) | Single-card checkout: existing regression suite green and a manual single-card order succeeds on staging with the flag off and with the flag on | Regression + E2E | R10, R12 | N/A — not yet run |
| G7 (TC-SPLIT-007) | Happy path: both charges succeed, order paid, both transaction IDs stored and shown on the receipt | E2E sandbox | R05, R08 | N/A — not yet run |

A failed gate case blocks the release. Analysis cases (TC-SPLIT-008 onward: validation boundaries, locale, accessibility, messaging, reconciliation view) inform; if an analysis finding turns out to be caused by the change and would stop the release, its case moves into the gate with a dated note. Findings not caused by this change go to their own tickets and never gate it.

**Execution order (risk-based, overridden by the sandbox resource window and by dependencies).**

1. G6 regression suite on the first feature build, any day: it needs no sandbox and protects 4,000 orders a day.
2. G3 unit tests and the arithmetic property test, as soon as the module exists (no sandbox needed).
3. 2026-10-28 (sandbox, first window): record real responses for success, hard decline, soft decline, timeout; confirm decline-simulation card numbers. Dependency: the stub (A6) is built from these recordings, so this runs before any stub-based case.
4. G1, G2, G4, G5, G7 on the stub, in that order, as soon as integration is complete (any day).
5. 2026-10-30 (sandbox): G7 then G1, G5, G3 on the sandbox. G7 runs first because G1 and G5 reuse its fixture order and confirm the sandbox is healthy.
6. 2026-11-04 (sandbox): G4, G2 (if PayGate can simulate refund failure), then re-run of anything that failed on 2026-10-30 after a fix; PO acceptance walkthrough of G1, G5, G7.
7. 2026-11-06 (sandbox, last window): full gate G1 to G7 on the release candidate build. Nothing new is tested on this day; it is the confirmation run.
8. Analysis cases and exploratory sessions on stub days (2026-10-29, 2026-10-31, 2026-11-03, 2026-11-05), in the order R07, R08, R06, R18, R19.
9. If a gate case fails on 2026-11-06, the release either slips to the next sandbox window (2026-11-10) or ships with the flag off; the PO decides on the evening of 2026-11-06.

**Metrics to collect.**

- Test progress: gate cases run / passed per sandbox day (decision: is 2026-11-06 a confirmation run or a first run?).
- Defect: open defects by severity, with age (decision: exception or slip?).
- Risk coverage: CRITICAL and HIGH rows with at least one passed case on the sandbox (decision: residual risk at go/no-go).
- Refund timing: elapsed time from decline to refund acknowledgement, every run (decision: R01 met or not).
- Project: tester hours spent against the estimate in item 7 (decision: cut analysis scope on 2026-11-03 if over 70% consumed).

**Test data and environment.** Fixture set (credentials kept in the team's secret store, not here):

| Fixture | Description | State assumed | May be changed | How to rebuild |
| --- | --- | --- | --- | --- |
| FX-ORD-ODD | Order with total 10,001 cents | Unpaid, in cart | Read only; copy before paying | Seed script (developer-provided) |
| FX-ORD-EVEN | Order with total 10,000 cents | Unpaid, in cart | Read only; copy before paying | Seed script |
| FX-ORD-MIN | Order with total 2 cents | Unpaid | Read only; copy | Seed script |
| FX-CARD-OK-A, FX-CARD-OK-B | Two sandbox cards that succeed | Active | Read only | PayGate documentation |
| FX-CARD-HARD-DECLINE | Sandbox card that always declines | Active | Read only | PayGate documentation |
| FX-CARD-TIMEOUT | Sandbox card or amount that triggers a timeout | Active | Read only | PayGate documentation; if none exists, stub only and G4 sandbox run becomes "verified on stub" with a recorded exception |
| FX-STUB-PROFILES | Stub outcome profiles: success, hard decline, soft decline, timeout, refund timeout, gateway 500 | Built from 2026-10-28 recordings | Developers only | Re-record on a sandbox day |
| FX-SINGLE | Single-card order used by G6 | Unpaid | Copy per run | Seed script |

Environments: CI (unit, integration, stub); Staging with stub (every day); Staging pointed at PayGate sandbox (Tuesdays and Thursdays only, switched by configuration and recorded in each result); Production, flag off, for the post-deploy smoke.

**Deviations from the test policy and strategy.** The E2E share is slightly above the backend preset's 10% because the real gateway can only be exercised end to end; accepted for this release. No load test of the split path; accepted because volume is unknown and the single-card latency comparison covers the shared path.

## 7. Estimate

**Technique.** Three-point estimation, tester's effort only, decomposed by task; the developers' test effort is inside their build estimate. Chosen because one estimator is available, the work is new and the margin matters against a hard 40-hour budget.

| Task | a | m | b | E |
| --- | --- | --- | --- | --- |
| Plan, risk register, assumptions to PO | 3 | 4 | 6 | 4.2 |
| Test case design (gate + analysis, about 20 cases) | 5 | 7 | 10 | 7.2 |
| Sandbox day 1: recordings, fixtures, stub validation | 3 | 4 | 5 | 4.0 |
| Sandbox days 2–4: gate runs, re-runs, PO walkthrough | 9 | 11 | 14 | 11.2 |
| Stub-day execution: analysis cases, exploratory sessions (3 × 1 h), regression reading | 5 | 7 | 10 | 7.2 |
| Defect reports, progress reports, completion report | 3 | 4 | 6 | 4.2 |
| **Total** | **28** | **37** | **51** | **38 ± 3.8** |

**Result.** 38 ± 4 tester hours (between 34 and 42) against a 40-hour budget. The budget holds only at the most likely path; the pessimistic case exceeds it by about 11 hours.

**Assumptions behind the figure.** The stub exists by 2026-10-29 (A6); the existing regression suite runs without tester effort (A7); no more than two gate cases fail on the sandbox and need a re-run; the PO answers A1 to A4 within two days. If the stub is late, add 6–8 hours of sandbox-day rework and cut the analysis cases first (R15).

## 8. Budget and Schedule

Budget: 40 tester hours plus developer test effort inside the build. No tool purchase; PayGate sandbox is already provisioned.

| Day | Date | Sandbox | Tester (4 h) | Developers |
| --- | --- | --- | --- | --- |
| 1 | Mon 2026-10-27 | No | Plan review with team, assumptions to PO, start case design | Build; split module with unit tests first |
| 2 | Tue 2026-10-28 | Yes | Record real responses, confirm decline cards, fixture set | Build stub from recordings |
| 3 | Wed 2026-10-29 | No | Finish gate cases, run G3 unit review, G6 regression on first build | Integration, idempotency, refund retry |
| 4 | Thu 2026-10-30 | Yes | G7, G1, G5, G3 on sandbox; progress report 1 | Fixes |
| 5 | Fri 2026-10-31 | No | Entry criteria check; stub runs of G2, G4; analysis cases R07 | Code complete target |
| 6 | Mon 2026-11-03 | No | Exploratory R08, R06 with finance; 70% budget checkpoint | Fixes; latency comparison R11 |
| 7 | Tue 2026-11-04 | Yes | G4, G2 on sandbox; re-runs; PO walkthrough; progress report 2 | Fixes |
| 8 | Wed 2026-11-05 | No | Exploratory R18, R19; flag-off and rollback dry run with Ops; defect verification on stub | Release candidate build cut |
| 9 | Thu 2026-11-06 | Yes | Full gate G1–G7 on the release candidate; completion report draft; go/no-go with PO | On call for blocking fixes only |
| 10 | Fri 2026-11-07 | No | Release; production smoke with flag off, then flag on for a small cohort if Ops supports it | Deploy, monitor refund alerts |

Contingency: if the release candidate is not ready for 2026-11-06, the gate cannot be confirmed on the real gateway before release. The decision is then slip to 2026-11-10 (next sandbox) or ship flag-off; recorded on 2026-11-05 at the latest.

## 9. Configuration Management of Testware

- This plan, the test cases, the stub profiles, the seed scripts and the reports live in the repository beside the feature code, under version control, with the plan ID and version above; changes after sharing are made with a dated correction note, never by deletion.
- Every case references the requirement it covers (brief sentence or assumption ID) and every result names the build version and the environment (CI, staging-stub, staging-sandbox, production) it was obtained on. "Latest build" is not accepted in a result.
- The staging environment is a baseline: application build, stub version, PayGate sandbox configuration and feature-flag state are recorded with each sandbox day's report, so a result from 2026-10-30 can be reproduced on 2026-11-06 by restoring the same versions.
- The stub recordings from 2026-10-28 are a versioned artifact; re-recording creates a new version and the affected results are re-run.
- CI runs the unit, integration and regression suites on every build and stores results with the commit hash; the gate results from sandbox days are attached to the board ticket with build and date.
