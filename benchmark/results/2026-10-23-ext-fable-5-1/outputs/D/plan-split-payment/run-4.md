# Test Plan: Split Payment (release 5.3)

Plan version 1.0, 2026-10-24. Owner: QA (test management and testing roles both held by the one tester). Status: draft for review by the two developers and the Product Owner on day 1.

## 1. Context of testing

**Scope.** Paying one order with two cards through PayGate: the customer sets the first-card amount, the rest goes on the second card, amounts are integers in cents, an "uneven" split puts the remainder cent on the first card, and a declined second charge triggers an automatic refund of the first charge within 60 seconds. The existing single-card checkout (about 4,000 orders a day) is in scope as the regression target.

**In scope**

| Area | Test levels | Business priority |
| :-- | :-- | :-- |
| Split amount calculation and validation (cents, remainder cent, boundaries) | Component, system | P0 |
| Two-charge orchestration with PayGate (approve, decline, timeout, duplicate protection) | Component integration, system integration | P0 |
| Automatic refund of the first charge on second-charge decline, within 60 s | Component integration, system integration | P0 |
| Order payment state and customer-facing outcome (receipt, error message) | System, acceptance | P1 |
| Single-card checkout regression, feature flag off and on | System | P0 |
| Security hygiene of the new path (card tokens not logged, server-side amount validation) | System | P1 |

**Out of scope** (and why): three or more cards (not in the brief); support-initiated partial refunds and chargebacks (unchanged code); gateways other than PayGate (none in use); load or stress testing of checkout (the feature adds one gateway call per split order, not new traffic; latency is checked, load is not); a full WCAG audit of the new form (a basic keyboard and label check runs inside the exploratory session; a full audit does not fit 40 tester hours and is logged as debt); native mobile apps (assumed web checkout only).

**Objectives.** Show that split orders charge exactly the order total across two cards; show that no customer is left charged without an order; show that single-card checkout is unchanged; give the Product Owner the evidence for a go/no-go on Thursday 5 November 2026.

**Test basis.** The feature brief above; PayGate's API documentation for charge, refund and error codes (assumed available); the existing single-card checkout test suite; the order payment state model (assumed, see item 2). Findings from the static review of the brief are in item 2 under "Ambiguities in the test basis".

## 2. Assumptions and constraints

**Constraints (given)**

- PayGate sandbox is reachable only on Tuesdays and Thursdays.
- Release in 10 working days.
- One tester at half time, plus the two developers building the feature.
- Single-card checkout must keep working at about 4,000 orders a day.

**Assumptions (stated, not confirmed)**

- A01 Today is Saturday 24 October 2026. Day 1 is Monday 26 October; day 10 and the release date is Friday 6 November 2026. Sandbox windows inside the plan: Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. Four windows, none repeatable.
- A02 The feature ships behind a feature flag, off by default. If no flag is planned, this plan asks for one on day 1: it is the main non-test risk control for R03 and P03.
- A03 One currency with two minor-unit decimals. Zero-decimal currencies are out of scope.
- A04 Charges run sequentially: first card, then second card. The second charge is never attempted if the first is declined.
- A05 The refund of the first charge is a full refund, and "within 60 seconds" is measured from the time our system receives the second-charge decline to the time PayGate acknowledges the refund request.
- A06 PayGate tokenizes cards; no primary account number reaches our servers. Both charges and the refund carry an idempotency key.
- A07 The stack is a web checkout UI over a backend API that calls PayGate over HTTPS; a CI pipeline runs unit and integration tests on every push.
- A08 The developers can provide a deterministic PayGate stub (approve, decline with code, timeout, refund failure) for every day that is not a sandbox day.
- A09 PayGate sandbox offers test cards for approve, decline and timeout outcomes. If it has no timeout card, timeout is tested only on the stub, and that gap is recorded as residual risk.
- A10 Tracker: N/A — none named; the plan uses Jira-style placeholders (ticket PAY-530, cases TC-PAY-NNN, defects DR-PAY-NNN).
- A11 The tester belongs to the same squad as the developers (independence: some). See item 6.

**Ambiguities in the test basis** (raised to the Product Owner on day 1; the plan proceeds under the stated reading)

- The brief says the customer chooses the first-card amount and also that an uneven amount puts the remainder cent on the first card. If the customer enters an exact cent amount, there is never a remainder. Reading adopted: the UI offers a "split evenly" shortcut; on an odd total, the first card takes the extra cent. Manual entry with more than two decimals is rejected.
- Minimum amount per card is not stated. Reading adopted: 1 cent per card, unless PayGate enforces a minimum, which the Tue 27 Oct sandbox session will establish.
- What the customer sees when the refund fails is not stated. Reading adopted: order not paid, customer told to retry, order flagged for manual review, alert raised to operations.

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :-- | :-- | :-- | :-- |
| Product Owner | N/A — not named | Owns acceptance criteria and the go/no-go decision; signs exceptions | Resolves the ambiguities above; attends the Thu 5 Nov acceptance run |
| Developers (2) | N/A — not named | Build the feature, write unit and component integration tests, build the PayGate stub | Hold the testing role at component levels; one reviews the other's module |
| Tester (half time) | N/A — not named | Test management and testing roles; system and system integration tests; this plan, reports, go/no-go record | 40 person-hours total |
| Operations / payments support | N/A — not named | Owns the manual-review queue and the refund alert | Confirms the refund-failure handling is operable |
| PayGate | External | Sandbox and test cards | Availability window fixes the schedule |

## 4. Communication

- Daily stand-up (15 min) with developers; the tester reports gate status, blockers and sandbox readiness.
- A written progress report in the ticket after each sandbox day (Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov): period, progress against this plan, impediments, metrics in item 6, new or re-scored risks, plan for the next period.
- Go/no-go meeting Thu 5 Nov, late afternoon, on the completion report.
- Templates: test cases in TC-PAY-NNN format; defects in DR-PAY-NNN format with severity, steps, expected versus actual, build, environment and flag state; progress and completion reports as described in item 6, every case one row.

## 5. Risk register

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Split arithmetic wrong: the two charges do not sum to the order total, or the remainder cent lands on the second card, or float conversion loses a cent | Product | 3 | 5 | 15 | 🔴 CRITICAL | Pure function for the split, unit-tested with EP, 3-value BVA and a decision table; property check "first + second = total" over random totals; gate cases G01 and G07 | Dev / QA |
| 2 | R02 | Second charge declined and the first charge is not refunded, or refunded after 60 s: customer charged with no order | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests of the order payment model; refund timer asserted in integration test on the stub and measured on sandbox; alert when refund not acknowledged within 60 s; gate case G03 | Dev / QA |
| 3 | R03 | Single-card checkout regresses (shared checkout code or data model changes); 4,000 orders a day exposed | Product | 2 | 5 | 10 | 🟠 HIGH | Feature flag off path tested as the production state; existing checkout regression suite in CI on every build; canary at a small share on release day with rollback by flag; gate case G05 | Dev / QA |
| 4 | R04 | Duplicate charge after a PayGate timeout, a retry, or a double-submitted form | Product | 3 | 4 | 12 | 🟠 HIGH | Idempotency key per charge and per refund; integration test with stub timeout then retry; error guessing session on double submit; gate case G06 | Dev / QA |
| 5 | R05 | Refund request itself fails or times out, leaving a charged customer with no automatic recovery | Product | 2 | 5 | 10 | 🟠 HIGH | Retry with backoff, then order to manual-review queue and operations alert; integration test on stub; verified on sandbox if PayGate can simulate refund failure; gate case G08 | Dev / Ops |
| 6 | R06 | First-card amount validation lets through 0, negative, above total, or more than two decimals; or rejects 1 cent and total minus 1 cent | Product | 3 | 3 | 9 | 🟠 HIGH | 3-value BVA on the amount at both boundaries, client and server side; server-side validation is the one that counts; gate case G07 | QA |
| 7 | R07 | Order state inconsistent with charges: order marked paid after one successful charge, or still pending after both succeeded | Product | 3 | 4 | 12 | 🟠 HIGH | State transition testing with valid-transitions coverage, plus one invalid transition per case; daily reconciliation report of PayGate charges against orders (non-test measure); gate case G02 | Dev / QA |
| 8 | R08 | Second card token or amounts leak into logs, or client-supplied amounts are trusted by the server | Product | 2 | 4 | 8 | 🟠 HIGH | Security checklist in the exploratory session: log inspection after a split order, tampered request with first + second not equal to total rejected by the API | QA |
| 9 | R09 | Display and input rounding differs from the cents model (for example an entered 10.005) | Product | 2 | 3 | 6 | 🟡 MEDIUM | EP on input formats in the UI; one unit test per rejected format | Dev |
| 10 | R10 | Checkout latency doubles with two sequential gateway calls; customer abandons or retries | Product | 2 | 3 | 6 | 🟡 MEDIUM | Measure end-to-end time for a split order on sandbox; compare with single-card; accept if within twice the single-card median, else raise | QA |
| 11 | R11 | Customer does not understand which card takes the extra cent or why both cards appear on the receipt | Product | 3 | 2 | 6 | 🟡 MEDIUM | Exploratory session with the Product Owner on wording and receipt; usability only, no scripted cases | PO / QA |
| 12 | P01 | PayGate sandbox available only Tue and Thu: four windows in the plan, none repeatable; a lost window cannot be recovered | Project | 4 | 4 | 16 | 🔴 CRITICAL | PayGate stub for all other days; every sandbox day has a pre-agreed script and entry criteria; the Tue 27 Oct window is used for gateway discovery before the feature exists | QA / Dev |
| 13 | P02 | Tester capacity is 40 hours; the estimate in item 7 reaches 48 hours at the top of its range | Project | 4 | 3 | 12 | 🟠 HIGH | Developers own unit, component integration and the stub automation; the drop list in item 7 is agreed with the Product Owner on day 1 | QA / PO |
| 14 | P03 | Feature not ready for the Thu 29 Oct window, which compresses all gateway testing into Tue 3 Nov and Thu 5 Nov | Project | 3 | 4 | 12 | 🟠 HIGH | Partial entry criteria for Thu 29 Oct (charge and refund orchestration only, no UI); release can ship with the flag off if Thu 5 Nov fails, which is a scope decision for the Product Owner | Dev / PO |
| 15 | P04 | Sandbox behaviour differs from production PayGate (decline codes, refund latency) | Project | 3 | 4 | 12 | 🟠 HIGH | Canary on release day with real low-value orders by the team; post-release sanity checks on production; residual risk recorded in the completion report | QA / Ops |
| 16 | P05 | PayGate sandbox lacks a test card for timeout or refund failure | Project | 2 | 3 | 6 | 🟡 MEDIUM | Established on Tue 27 Oct; if missing, those paths are proven on the stub only and listed as unmitigated residual risk | QA |

Monitoring: the register is re-read at each progress report; a row is re-scored in place with a dated note when its facts change (for example after the Tue 27 Oct discovery session).

## 6. Test approach

**Test levels, who tests, independence**

| Level | Test object | Who | Independence | Why it fits the risk |
| :-- | :-- | :-- | :-- | :-- |
| Component | Split function, validation, refund timer, state model | Developers; each developer reviews the other's tests | None, raised to some by cross-review | Fast, cheap, where the arithmetic defects of R01 and R06 are found |
| Component integration | Orchestration against the PayGate stub, idempotency, state transitions | Developers, cases reviewed by the tester | Some | Timeout and retry paths (R04, R05) need deterministic doubles; the stub is the only way to run them daily |
| System and system integration | Checkout UI to backend to PayGate sandbox, flag off and on | Tester | Some (same squad, A11) | A payment feature would merit high independence; not available in this team. Compensated by Product Owner acceptance and by the reconciliation report after release |
| Acceptance | The gate scenarios, run by the Product Owner with the tester on Thu 5 Nov | Product Owner | High relative to the developers | Business validation of the ambiguities resolved in item 2 |

**Test pyramid.** Preset Backend / API: 70% unit, 20% integration, 10% end-to-end. The business logic (split, remainder, refund orchestration, state) lives in the backend; the UI adds one input and one shortcut.

**Testing quadrants.** Q1: unit and component integration tests in CI, developer-owned. Q2: the gate cases below as API and end-to-end tests, plus Gherkin scenarios for the remainder-cent and refund rules written on day 1 to settle the ambiguities. Q3: two exploratory sessions (boundaries and double submit; receipt wording and basic accessibility with the Product Owner) and the Thu 5 Nov acceptance run. Q4: the existing smoke suite on each build, the security checklist (R08), and a latency measurement (R10). Nothing in Q4 covers load: stated out of scope above.

**Techniques by risk.** R01: equivalence partitioning, 3-value boundary value analysis on totals of 1, 2, 3 cents and on even versus odd totals, decision table for the remainder rule (conditions: split evenly or manual; total even or odd). R02 and R07: state transition testing over the order payment states Pending, FirstCharged, Paid, RefundPending, Refunded, RefundFailed, ManualReview, Failed; valid-transitions coverage, one invalid transition per case. R04 and R05: error guessing (timeout then retry, double submit, refund timeout). R06: 3-value BVA on the first-card amount at 0 and at total. R08: checklist-based. R11: exploratory.

**Entry criteria, system-level execution (stub days).** Build merged and green in CI with unit and integration tests; staging deployed with the stub and the flag toggleable per session; fixture set below seeded; split-amount input and submit button carry test identifiers.

**Entry criteria, sandbox days.** All of the above, plus staging pointed at PayGate sandbox with credentials verified by 09:00; the day's script agreed the day before; no deployments to staging during the session except the one planned build. For Thu 29 Oct the partial criterion of P03 applies.

**Exit criteria (release).** Every gate case passed on the release candidate build on Thu 5 Nov, on sandbox; all P0 cases passed; P1 failures each carry a recorded Product Owner exception; zero open Critical or High defects without exception; the single-card smoke suite green with the flag off and on; refund latency measured on sandbox under 60 s on every observed decline; completion report signed by the tester and the Product Owner. If time runs out, the Product Owner accepts the residual risk in writing or the feature ships with the flag off.

**Release gate**

| ID | What it proves | Risk | Technique | Where it runs | Result |
| :-- | :-- | :-- | :-- | :-- | :-- |
| G01 | Odd-cent total split evenly puts the extra cent on the first card; first + second = total for even, odd, 1-cent and 2-cent totals | R01 | BVA, decision table | Unit in CI; one end-to-end on sandbox | N/A — not yet run |
| G02 | Both charges approved: order Paid, two charge records with the right amounts, receipt shows both cards | R07 | State transition | Sandbox | N/A — not yet run |
| G03 | Second charge declined: first charge refunded automatically, refund acknowledged within 60 s, order not Paid, customer told | R02 | State transition, timing | Stub daily; sandbox Tue 3 Nov and Thu 5 Nov | N/A — not yet run |
| G04 | First charge declined: second charge never attempted, no refund issued, order Failed | R02, R07 | State transition | Stub; sandbox | N/A — not yet run |
| G05 | Single-card checkout unchanged with the flag off and with the flag on (existing smoke suite) | R03 | Regression | CI every build; staging each sandbox day | N/A — not yet run |
| G06 | PayGate timeout on the second charge, then retry: exactly one charge per card, no duplicate | R04 | Error guessing, idempotency | Stub; sandbox only if a timeout card exists (P05) | N/A — not yet run |
| G07 | First-card amount of 0, above total, negative and 10.005 rejected server-side; 1 cent and total minus 1 cent accepted | R06, R01 | 3-value BVA | API test in CI; one end-to-end on stub | N/A — not yet run |
| G08 | Refund failure: retries, then order to ManualReview and operations alert raised; customer not shown a success | R05 | State transition | Stub; sandbox if simulable (P05) | N/A — not yet run |

**Execution order.** Risk-based for the gate, with the sandbox window overriding priority:

1. G01, G07 as unit and API tests, from the first merged build (no gateway needed; cheapest, CRITICAL risk).
2. G05 flag off, on every build (the production state today; must stay green before anything else is believed).
3. G03, G04, G06, G08 on the stub, Fri 30 Oct to Mon 2 Nov (deterministic doubles; proves the paths before spending a sandbox window).
4. G02, G03, G04, G01 end-to-end on sandbox, Tue 3 Nov (resource window; G02 first because G03 depends on a known-good first charge).
5. G06, G08 on sandbox, Tue 3 Nov, only if the Tue 27 Oct discovery found the matching test cards; otherwise recorded as stub-only.
6. G05 flag on, staging, Tue 3 Nov after the gate run.
7. Full gate repeat on the release candidate, Thu 5 Nov, same order as 4 to 6 (confirmation of fixes plus regression).

**Analysis cases, not gating.** Double submit of the split form; same card entered twice; browser back after the first charge; a split where the first amount equals the total (should degrade to single card or be rejected, Product Owner to decide); receipt and email wording; keyboard and label check of the new input; log inspection for tokens; latency comparison. Findings not caused by this change are filed as separate defects and linked, never gating.

**Metrics collected.** Gate cases passed over total, per build. CRITICAL and HIGH risk coverage: register rows with at least one executed case. Open defects by severity. Refund latency on sandbox: every observed value and the maximum. Sandbox windows used over four planned. Tester hours spent against the item 7 estimate.

**Test data: fixture set.** Credentials and sandbox keys stay in the team vault; the plan names only identifiers.

| Fixture | Description | Assumed state | May be changed |
| :-- | :-- | :-- | :-- |
| CARD-OK-A, CARD-OK-B | PayGate sandbox approve cards | Valid | Read only |
| CARD-DECLINE | Sandbox decline card (insufficient funds) | Valid | Read only |
| CARD-TIMEOUT | Sandbox timeout card | Existence confirmed Tue 27 Oct | Read only |
| CARD-REFUND-FAIL | Sandbox card whose refund fails | Existence confirmed Tue 27 Oct | Read only |
| ORD-EVEN, ORD-ODD, ORD-1C, ORD-2C, ORD-MAX | Staging orders with totals 10.00, 10.01, 0.01, 0.02 and 99,999.99 | Pending, unpaid | Written by tests; recreated by seed script after each session |
| FLAG split_payment | Feature flag on staging | Off outside sessions | Toggled per session, state recorded in every result, restored to off |

A case whose fixture is missing or in the wrong state is blocked, not failed. How to rebuild: the seed script owned by the developers; sandbox cards cannot be rebuilt by us.

**Environments.** Developer machines with the stub (dry runs only, never results). CI on every push. Staging with the stub on non-sandbox days and with PayGate sandbox on Tue and Thu. Production canary on Fri 6 Nov at a small share of traffic, flag on, with team-placed low-value orders and the reconciliation report watched; rollback is the flag.

**Non-test measures.** Feature flag with kill switch; daily reconciliation of PayGate charges and refunds against orders; alert on any refund not acknowledged within 60 s; operations runbook for the ManualReview queue.

**Deviations from test policy and strategy.** N/A — no written policy or strategy was provided; this plan follows the package's default.

## 7. Estimate

Technique: three-point estimation, one estimator, decomposed by task. Figures are tester person-hours.

| Task | a | m | b |
| :-- | :-- | :-- | :-- |
| Static review of the brief, Gherkin scenarios, this plan's review | 2 | 3 | 5 |
| Fixture set and PayGate discovery session (Tue 27 Oct) | 2 | 3 | 5 |
| Gate automation at API and end-to-end level, with developer support | 6 | 10 | 16 |
| Three sandbox sessions (Thu 29 Oct, Tue 3 Nov, Thu 5 Nov) | 8 | 12 | 16 |
| Single-card regression and flag-off checks | 2 | 4 | 6 |
| Exploratory sessions (two) | 3 | 4 | 8 |
| Defect retests, progress and completion reports, go/no-go record | 3 | 4 | 8 |
| Total | 26 | 40 | 64 |

E = (26 + 4 × 40 + 64) / 6 = 41.7; SD = (64 − 26) / 6 = 6.3. Reported as 42 ± 6 person-hours (36 to 48) against 40 available.

Assumptions: developers deliver the stub by Wed 28 Oct and write all unit and component integration tests (about 40 developer hours, assumed as one quarter of their time); the automation reuses the existing checkout end-to-end framework; no more than two sandbox-day defects need a retest on a later sandbox day. Drop list if the top of the range is reached, in this order and with Product Owner agreement: receipt-wording exploratory session, latency comparison, basic accessibility check. The gate is never dropped.

## 8. Budget and schedule

Budget: N/A — no cost figures given; capacity is the 40 tester hours and the developers' time above.

| Day | Date | Activity |
| :-- | :-- | :-- |
| 1 | Mon 26 Oct | Plan review; ambiguities to Product Owner; Gherkin scenarios; flag confirmed; stub agreed |
| 2 | Tue 27 Oct (sandbox) | PayGate discovery: test cards, decline codes, refund latency baseline, minimum amount; fixture set written |
| 3 | Wed 28 Oct | Developers build; unit tests; stub delivered; tester writes G01 and G07 API tests |
| 4 | Thu 29 Oct (sandbox) | Partial entry criteria: orchestration against sandbox for G02, G03, G04 if built; otherwise discovery continues |
| 5 | Fri 30 Oct | Stub runs of G03, G04, G06, G08; G05 flag off |
| 6 | Mon 2 Nov | Exploratory session 1; defects filed; progress report |
| 7 | Tue 3 Nov (sandbox) | Full gate on sandbox; G05 flag on; latency measured |
| 8 | Wed 4 Nov | Fixes; confirmation tests on stub; exploratory session 2 with Product Owner |
| 9 | Thu 5 Nov (sandbox) | Gate repeat on release candidate; acceptance run; completion report; go/no-go |
| 10 | Fri 6 Nov | Release with flag off, then canary on; team-placed real orders; sanity checks; reconciliation watched |

## 9. Configuration management of testware

- This plan, the Gherkin scenarios, the test cases and the fixture document live in the product repository under version control, with identifiers TC-PAY-NNN and DR-PAY-NNN linked to ticket PAY-530.
- Every recorded result names the build (commit SHA and pipeline run), the environment (CI, staging-stub, staging-sandbox, production-canary), the flag state, and the PayGate sandbox API version read on Tue 27 Oct.
- Staging is baselined at the start of each sandbox session: the deployed build is recorded, and no other deployment happens during the session. A session on a build that failed CI is not started.
- Automated gate cases run in the pipeline and carry a gate tag; stub-only cases are tagged so a sandbox run can be filtered to the cases that need the real gateway.
- Corrections to this plan after sharing are made in place with a dated, attributed note; nothing is deleted.
