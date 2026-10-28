# Test Plan: Split Payment (Release 5.3)

**Version** 1.0 | **Date** 2026-10-25 | **Author** QA (test management and testing roles) | **Status** Draft for review | **Tracker** N/A — no board URL given; assumed Jira, epic key `PAY-53` used below as a placeholder

## 1. Context of testing

**Scope, in**

| Area | What is tested | Levels | Priority |
| :--- | :--- | :--- | :--- |
| Split amount calculation | Customer-chosen first-card amount, remainder on second card, cent arithmetic, remainder-cent rule | Unit, integration, system | P0 |
| Two-charge orchestration with PayGate | Both charges succeed; order moves to paid only when both have succeeded | Integration, system integration | P0 |
| Compensating refund | Second charge declined, first charge refunded automatically within 60 s; refund failure handling | Integration, system integration | P0 |
| Input validation and boundaries | First-card amount at 0, 1, total − 1, total, above total, negative, non-numeric, decimal input | Unit, system | P1 |
| Idempotency | Double submit, retry after timeout, back button, produces no duplicate charges | Integration, system integration | P1 |
| Single-card checkout regression | Existing flow unchanged with the feature on and off | System, smoke in production | P0 |
| Feature flag | Split option hidden when off; no behaviour change for single card | System | P1 |
| Order record and reconciliation | Order stores two transactions; existing exports and admin views still read it | Integration, exploratory | P2 |

**Scope, out** (with reason)

- Post-purchase refunds or cancellations of an order paid with two cards through the existing customer-service flow. Not in the brief; logged as risk R08 and raised to the Product Owner as an open question. Assumed to stay single-card-only in 5.3.
- Three or more cards, gift cards, or mixing card with another payment method. Not in the brief.
- Load and stress testing. Volume is about 4,000 orders a day, under one order per 20 s on average; the split path adds one gateway call per order. Latency is measured, load is not generated (see item 6, Q4).
- PCI-scope audit. Assumed that card data is tokenized client-side by PayGate's SDK and never reaches the application servers; one checklist item confirms the assumption (R09).
- Accessibility audit of the new form. Only a keyboard and screen-reader smoke check is done in the exploratory session; a full WCAG audit is deferred to 5.4.

**Objectives**

1. Show that every split produces two charges whose sum equals the order total, in cents, with the remainder cent on the first card.
2. Show that a declined second charge leaves the customer with no net charge within 60 s, and that a failed refund is never silent.
3. Show that single-card checkout is unaffected, before release and during the first hours in production.
4. Give the Product Owner a go/no-go record by Thursday 2026-11-05 with residual risks listed.

**Test basis**

- Feature brief "Split payment (release 5.3)" (this document's source; no ticket version given).
- PayGate API documentation for charge, refund and decline codes. Assumption: the version the current single-card integration uses; its version string is recorded in item 9.
- Existing single-card checkout acceptance tests and regression suite. Assumption: an automated regression suite exists and runs in CI.
- Open questions sent to the Product Owner on 2026-10-26 (listed in item 2). Answers become part of the test basis when received.

## 2. Assumptions and constraints

**Constraints (given)**

- PayGate sandbox is reachable only on Tuesdays and Thursdays. Within the 10 working days that gives four windows: Tue 2026-10-27, Thu 2026-10-29, Tue 2026-11-03, Thu 2026-11-05.
- Release date Friday 2026-11-06 (10 working days from today, 2026-10-25).
- One tester at half time, about 40 person-hours over the period, plus two developers building the feature.
- Single-card checkout handles about 4,000 orders a day and must keep working.

**Assumptions (made where the brief is silent; each is marked and will be corrected in place if wrong)**

| # | Assumption | Why it matters |
| :-- | :--- | :--- |
| A1 | Web checkout with a browser front end and a backend service; the split, orchestration and refund logic live in the backend. | Chooses the backend-heavy pyramid preset. |
| A2 | The customer enters the first-card amount as a decimal value in the UI; the backend converts to cents. The remainder-cent rule applies when the UI offers an equal-split shortcut or a percentage, and when a decimal input converts to a fractional cent. | Defines the inputs that can produce an uneven split. If no shortcut exists, the rule is still tested at the unit level on the conversion. |
| A3 | Valid first-card amount is 1 cent to total − 1 cent inclusive; 0 and total are rejected as "use single card". PayGate's minimum charge is not known; assumed 1 cent, to be confirmed on the first sandbox day. | Sets the boundaries for BVA. If PayGate has a higher minimum, the boundaries move and R06 is re-scored. |
| A4 | The 60 s limit is measured from the decline response of the second charge to PayGate acknowledging the refund request, not to settlement. | Makes the requirement measurable. |
| A5 | If the refund request fails, the system retries with backoff, alerts operations, and keeps the order in a "payment failed, refund pending" state visible to support. | The brief does not say; without this the customer can be charged with no order. Logged as R05. |
| A6 | The same card may be used for both halves; no rule forbids it. | Tested once; not a release blocker either way. |
| A7 | Charges are made sequentially: first card, then second. The first charge is a capture, not an authorization hold. | Determines whether a refund or a void is needed. If the team uses auth-then-capture, the compensation becomes a void and R02 cases are rewritten, not removed. |
| A8 | A feature flag exists or will be added so that split payment can be switched off in production without a deploy. | Main non-test mitigation for R03 and R18. |
| A9 | PayGate sandbox provides test card numbers that approve, decline, and time out, and a refund endpoint that behaves as in production. Verified on the first sandbox day. | Needed to run G02 against the real gateway. |
| A10 | A PayGate stub (recorded responses, scenario-selectable) can be built by the developers by Wednesday 2026-10-28, so that all non-sandbox days have a deterministic gateway. | The plan does not work without it; see R14. |
| A11 | The tester sits in the same product team as the developers. | Sets the independence degree in item 6. |
| A12 | Dev, staging and production environments exist; staging can reach the PayGate sandbox; dev uses the stub. | Environment plan in item 6. |

**Open questions sent to the Product Owner** (plan proceeds under the assumption named)

1. Is the first-card amount free-form, a shortcut, or both? (A2)
2. Does PayGate enforce a minimum charge? (A3)
3. What should the customer and support see when the refund itself fails? (A5)
4. How is an order paid with two cards refunded later by customer service? (R08, out of scope)

## 3. Stakeholders

| Role | Who | Responsibility | Relevance to testing |
| :--- | :--- | :--- | :--- |
| Product Owner | N/A — name not given | Owns acceptance, answers open questions, signs the go/no-go, records any exception | Decides on residual risk; does a short UAT on 2026-11-05 |
| Developers (2) | N/A — names not given | Build the feature, write unit and integration tests, build and maintain the PayGate stub, fix defects | Hold the testing role at component and component integration level |
| Tester (half time) | N/A — name not given | Test management role (this plan, monitoring, reports) and testing role at system and system integration level | Single point of failure; see R13 |
| Payments or finance operations | N/A — assumed to exist | Reconciles PayGate settlements with orders | Reviews how two transactions per order appear in exports (R11); consulted in the exploratory session |
| Customer support | N/A — assumed to exist | Handles customers whose second card was declined | Reviews the customer-facing message and the "refund pending" state (A5) |
| PayGate technical contact | N/A — assumed to exist | Sandbox access, decline test cards, API questions | Needed on 2026-10-27 if A9 fails |

## 4. Communication

| Form | Frequency | Content | Template |
| :--- | :--- | :--- | :--- |
| Stand-up note in the team channel | Daily, working days | Cases run, blocked, defects opened, what runs tomorrow | Free text, three lines |
| Progress report | Evening of each sandbox day (10-27, 10-29, 11-03, 11-05) | Period, progress against plan, impediments, metrics from item 6, new and changed risks, next period | Progress report format of the `qa-reference` skill's test-reporting reference |
| Defect reports | As found | DR-SPLIT-NNN with severity, steps, expected and actual, environment and build, evidence | `/qa-defect` format |
| Go/no-go record | Once, 2026-11-05 | Each gate case with result and build; exceptions; residual risks; defects not fixed | `/qa-release` format |
| Completion report | Once, 2026-11-06 after release | Every case one per row, "Not run — resume point", lessons learned | Completion report format of the test-reporting reference |
| Retrospective | Once, week of 2026-11-09 | What to keep, what to change, actions with owner and date | Whole-team meeting |
| Risk register review | At each progress report | Re-scored rows with a dated note | In this plan, item 5 |

## 5. Risk register

Score = Likelihood (1 to 5) × Impact (1 to 5). Levels: 15 to 25 CRITICAL, 8 to 14 HIGH, 4 to 7 MEDIUM, 1 to 3 LOW.

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| :-- | :-- | :--- | :--- | :-- | :-- | :-- | :--- | :--- | :--- |
| 1 | R01 | Split amounts do not sum to the order total, or the remainder cent lands on the second card, or decimal-to-cent conversion rounds wrongly | Product | 3 | 5 | 15 | 🔴 CRITICAL | Pure function for the split; unit tests with BVA and EP on cents; property-style check that first + second = total for a range of totals; integration test asserts the two amounts sent to PayGate; gate case G01 on sandbox | Dev / QA |
| 2 | R02 | Second charge declined and the first charge is not refunded, or is refunded after 60 s | Product | 3 | 5 | 15 | 🔴 CRITICAL | State transition tests on the payment state machine (all transitions); stub scenarios for decline, timeout and 5xx on the second charge; refund latency measured and logged on every run; gate case G02 on sandbox; production alert on refund latency above 45 s | Dev / QA |
| 3 | R03 | Single-card checkout regresses (4,000 orders a day affected) | Product | 2 | 5 | 10 | 🟠 HIGH | Existing regression suite runs on every build; single-card gate cases G03 and G07; feature flag (A8) so the split path can be switched off; canary release to a share of traffic with the single-card success rate watched for 2 hours | Dev / QA / PO |
| 4 | R04 | Duplicate charges on double submit, browser retry, or timeout-then-retry | Product | 3 | 4 | 12 | 🟠 HIGH | Idempotency key per order and per leg; integration test with a replayed request; stub scenario "first charge times out, then succeeds"; gate case G05 | Dev / QA |
| 5 | R05 | Refund request fails (PayGate error or timeout); customer is charged with no order and nobody is told | Product | 2 | 5 | 10 | 🟠 HIGH | Assumption A5 confirmed with PO; retry with backoff and operations alert; "refund pending" state visible to support; stub scenario "refund returns 500 then 200"; gate case G04 | Dev / QA / Support |
| 6 | R06 | Input validation gaps: first amount 0, equal to total, above total, negative, non-numeric, more than two decimals, locale separators | Product | 3 | 3 | 9 | 🟠 HIGH | EP and BVA (3-value) at unit level and once through the UI; server-side validation tested directly through the API, not only through the form; gate case G06 | Dev / QA |
| 7 | R07 | Order marked paid after only the first charge succeeded, or stuck in an intermediate state after a crash between the two charges | Product | 2 | 5 | 10 | 🟠 HIGH | Payment state machine reviewed before coding (`/qa-static` on the design); all-transitions coverage; stub scenario "process killed between leg 1 and leg 2" with a recovery job that refunds or completes; exploratory session on order admin views | Dev / QA |
| 8 | R08 | Later refund or cancellation of a split-paid order through the existing customer-service flow refunds the wrong card or the wrong amount | Product | 3 | 4 | 12 | 🟠 HIGH | Out of scope for 5.3 by assumption; risk accepted by the PO or feature deferred. One exploratory check of what the existing refund screen does with a two-transaction order, so the PO decides with evidence | PO |
| 9 | R09 | Second card's data handled outside PayGate tokenization (PCI exposure) | Product | 1 | 5 | 5 | 🟡 MEDIUM | Checklist item in the code review: no card number, CVV or expiry in request logs, application database or analytics events for the second card; browser network inspection in the exploratory session | Dev / QA |
| 10 | R10 | Split checkout takes too long (two sequential gateway calls) and the customer abandons or retries | Product | 2 | 3 | 6 | 🟡 MEDIUM | Checkout duration logged per leg on the stub and on sandbox; compare with single-card baseline; no load generated | QA |
| 11 | R11 | Reconciliation exports and admin order views assume one transaction per order | Product | 2 | 3 | 6 | 🟡 MEDIUM | Finance operations reviews a split order in the export during the exploratory session on 2026-11-02; defect raised if the second transaction is missing | QA / Finance ops |
| 12 | R12 | PayGate sandbox available only on Tuesdays and Thursdays: four windows total; a slip of one day loses a full cycle | Project | 4 | 4 | 16 | 🔴 CRITICAL | Stub for all other days (A10); sandbox characterization on 2026-10-27 before the feature exists; main gate run on 2026-11-03 with 2026-11-05 held for confirmation; code freeze end of 2026-11-04; if the 11-05 run fails, release slips to the week of 11-09 or ships flag-off | QA / Devs |
| 13 | R13 | One tester at half time; illness or interruption removes all system-level testing | Project | 4 | 3 | 12 | 🟠 HIGH | Developers own automation at lower levels; gate cases written so a developer can run them from the plan; handover-ready state kept daily (item 9); PO can run G01 to G03 from the written steps | QA |
| 14 | R14 | PayGate stub does not behave like the real sandbox (wrong decline codes, refund response shape) so stub-based passes are false | Project | 3 | 4 | 12 | 🟠 HIGH | Stub built from responses recorded on 2026-10-27; one contract check per stub scenario against the sandbox on 2026-10-29; stub versioned in the repo | Devs / QA |
| 15 | R15 | Feature not "Ready for QA" before the third sandbox window (2026-11-03) | Project | 3 | 4 | 12 | 🟠 HIGH | Entry criterion for system test set at end of 2026-10-30; if missed, the PO is told on 2026-11-02 and the release decision moves to flag-off ship or slip | Devs / PO |
| 16 | R16 | Customer does not understand which card carries the extra cent or the result of a decline; support load rises | Product | 2 | 2 | 4 | 🟡 MEDIUM | Exploratory session with the customer-support reviewer; copy for the decline-and-refund message reviewed before 2026-11-03 | QA / Support |
| 17 | R18 | No feature flag; the only rollback is a redeploy | Project | 2 | 4 | 8 | 🟠 HIGH | Assumption A8 checked with developers on 2026-10-26; if no flag exists, one is added to the feature's scope as a release condition | Devs |
| 18 | R19 | Estimate in item 7 proves low because defects in the refund path need several fix-and-retest cycles | Project | 3 | 3 | 9 | 🟠 HIGH | Buffer of about 10 h kept in the tester's 40 h; retests on the stub, not the sandbox; estimate re-issued in the 10-29 progress report with a dated note | QA |

R17 was merged into R01 during drafting (display rounding is tested with the cent conversion); the number is skipped so later rows keep their IDs.

**Risk control.** Rows R01, R02 and R12 drive the order of execution and the gate. R08 is a decision for the PO, not a test. R03 and R18 are reduced by non-test measures (flag, canary, alerting) as much as by tests. Each row is re-scored in the progress report when its facts change, with a dated note in place.

## 6. Test approach

**Pyramid preset.** Backend / API: about 70% unit, 20% integration, 10% end-to-end. The business logic (split arithmetic, state machine, compensation) lives in the backend (A1). The UI adds one form and one message, covered by a few component tests and the end-to-end gate cases.

**Test levels, who tests, independence**

| Level | Test object | Who | Independence | Why this degree fits |
| :--- | :--- | :--- | :--- | :--- |
| Component | Split function, validation, state machine, refund scheduler | Developers, with the other developer reviewing the tests | Some (peer from the author's team) | Fast feedback on arithmetic; the peer review catches the author's assumptions about rounding and boundaries |
| Component integration | Checkout service with PayGate client against the stub; order repository | Developers; tester reviews scenario list | Some | The stub scenarios are the main defect-finding tool for R02, R04, R05 and R07; the tester's review adds the failure modes a developer tends to skip |
| System | Full checkout through the UI and API against the stub (dev) | Tester | Some (same team, A11) | A tester from outside the team is not available; the tester did not write the code and challenges the brief's gaps, which is what matters for R01 and R06 |
| System integration | Staging against the PayGate sandbox, Tuesdays and Thursdays | Tester, paired with a developer on sandbox days | Some | The pairing is for speed in a four-hour window, not for independence; the tester records every result |
| Acceptance | Gate cases G01 to G03 walked through by the PO on 2026-11-05 | Product Owner | Some (business representative within the organisation) | Confirms the behaviour matches business intent, in particular the remainder-cent rule and the customer message |

**Test types.** Functional (all levels); non-functional: performance measurement of checkout duration and refund latency (no load), security checklist for card data (R09), a keyboard and screen-reader smoke check of the new form. Black-box techniques dominate at system level; branch coverage is read at component level for the split and state-machine code (floor 80%, a trigger to look, not a target).

**Techniques by risk level**

| Risk | Technique | Coverage items |
| :--- | :--- | :--- |
| R01 CRITICAL | EP and 3-value BVA on cents; decision table for shortcut versus free-form input versus decimal conversion; property check first + second = total over totals 1 to 100,000 cents | Every partition and boundary; every feasible decision-table column |
| R02 CRITICAL | State transition testing, all-transitions criterion, on the payment state machine: states pending, leg1_charged, paid, leg2_declined, refund_requested, refunded, refund_failed; one invalid transition per case | Every valid transition exercised and every invalid one attempted |
| R04, R05, R07 HIGH | Error guessing with stub scenarios: duplicate request, timeout then success, 500 on refund, process killed between legs | One scenario per guessed fault |
| R06 HIGH | EP and 3-value BVA on first-card amount: 0, 1, 2, total − 2, total − 1, total, total + 1, negative, non-numeric, three decimals | Every boundary and its neighbours |
| R03 HIGH | Existing regression suite plus two gate cases; impact analysis of files touched by the change to pick which regression cases run manually | Changed modules and their callers |
| R08, R11, R16 | Exploratory session, 90 minutes, charter "split-paid order through admin, refund screen, export, and support message" | Session notes and defects |
| R09 MEDIUM | Checklist-based testing, five items (no PAN, CVV or expiry in logs, DB, analytics, URL, error messages) | Every item checked once |
| R10 MEDIUM | Measurement: checkout duration per leg, 10 runs on stub, 5 on sandbox; compared with single-card baseline | One measurement table |

**Testing quadrants check.** Q1: unit and component integration tests in CI. Q2: Gherkin scenarios for the split rules and decline-refund path written before coding, API tests of the checkout endpoint. Q3: exploratory session with finance operations and support, PO acceptance walkthrough. Q4: smoke suite, latency measurement, security checklist. Nothing is empty; load testing is the one Q4 activity left out, for the volume reason in item 1.

**Deliverables.** This plan; Gherkin scenarios (`/qa-bdd`) for R01, R02, R06; test cases TC-SPLIT-001 onward (`/qa-cases`) with the gate cases marked; PayGate stub scenario list with its version; exploratory session charter and notes; defect reports; progress reports on sandbox days; go/no-go record; completion report.

**Entry criteria**

| Level | Entry criteria |
| :--- | :--- |
| Component and component integration | Gherkin scenarios reviewed by PO; stub scenario list agreed; CI runs the suites on every push |
| System (dev, stub) | Feature behind flag, flag on in dev; build identifier known; stub version pinned; fixture set F1 to F6 seeded; `data-testid` on the amount field, card forms, submit and message; "Ready for QA" set in the tracker by end of 2026-10-30 |
| System integration (staging, sandbox) | System-level gate cases G04 to G06 and G08 passing on the stub; staging deployed with the same build; sandbox credentials in the secret store; decline test cards confirmed on 2026-10-27 |
| Acceptance | Gate cases G01 to G03 passed on sandbox at least once |

**Exit criteria (measured against the release gate)**

- Every gate case passing on the build proposed for release, on staging against the sandbox for G01, G02, G03, G07, and on the stub for G04, G05, G06, G08.
- 100% of P0 cases passed; 100% of P1 cases passed or each failure carries a recorded PO exception.
- Zero open Critical defects; zero open High defects without a recorded PO exception.
- Single-card regression suite green on the release build; smoke suite green on the supported browsers (assumed: current Chrome, Firefox, Safari, Edge).
- Refund latency in G02 under 60 s on every measured run, and under 45 s on the sandbox run so production has margin.
- Go/no-go record signed by the PO and the tester.
- Time running out ends testing only when the PO reviews the untested items and accepts the risk in the go/no-go record.

**Release gate**

| ID | Case | What it proves | Level / environment | Window | Result |
| :-- | :-- | :--- | :--- | :--- | :--- |
| G01 | TC-SPLIT-001 | Uneven total (e.g. 100.01 split equally) charges 50.01 on card 1 and 50.00 on card 2, both succeed, order paid, stored amounts sum to total | System integration, staging + sandbox | Tue 11-03, confirm Thu 11-05 | N/A — not yet run |
| G02 | TC-SPLIT-002 | Card 2 declined: card 1 refund acknowledged by PayGate within 60 s, order not paid, customer sees the decline-and-refund message | System integration, staging + sandbox | Tue 11-03, confirm Thu 11-05 | N/A — not yet run |
| G03 | TC-CHK-SMOKE-001 (existing) | Single-card checkout succeeds unchanged with the flag on | System integration, staging + sandbox | Tue 11-03, confirm Thu 11-05 | N/A — not yet run |
| G04 | TC-SPLIT-010 | Refund returns 500 then 200: retry succeeds, alert fired, order in "refund pending" then "refunded" | System, dev + stub | From Mon 11-02 | N/A — not yet run |
| G05 | TC-SPLIT-015 | Submitting the same split order twice produces exactly two charges, never four | System, dev + stub | From Mon 11-02 | N/A — not yet run |
| G06 | TC-SPLIT-020 | Amount boundaries: 1 cent and total − 1 cent accepted; 0 and total rejected with a message naming the field | System, dev + stub (API and UI) | From Mon 11-02 | N/A — not yet run |
| G07 | TC-CHK-SMOKE-004 (existing) | Single-card decline still shows the existing decline message and leaves no charge | System integration, staging + sandbox | Tue 11-03, confirm Thu 11-05 | N/A — not yet run |
| G08 | TC-SPLIT-030 | Flag off: split option absent, single-card checkout identical to 5.2 | System, dev + stub | From Mon 11-02 | N/A — not yet run |

Existing case IDs TC-CHK-SMOKE-001 and -004 are assumed; the real IDs replace them once the regression suite is checked.

**Execution order (risk-based, with resource windows and dependencies applied)**

1. G06 on the stub, Mon 11-02. First because G01 depends on a valid amount being accepted, and it needs no sandbox.
2. G08 on the stub, Mon 11-02. Confirms the flag before anything else is trusted.
3. G05 on the stub, Mon 11-02. Idempotency must hold before the sandbox run, or sandbox charges multiply.
4. G04 on the stub, Mon 11-02. Refund failure path; cannot be forced on the sandbox, so it runs here.
5. G01 on staging + sandbox, Tue 11-03, first thing in the window. Highest risk (R01).
6. G02 on staging + sandbox, Tue 11-03, immediately after G01. Highest risk (R02); refund latency recorded on five runs.
7. G03 and G07 on staging + sandbox, Tue 11-03. Moved after G01 and G02 only because the sandbox window is shared and the split cases are the ones that cannot run elsewhere.
8. Full analysis set and exploratory session, Mon 11-02 to Wed 11-04, on the stub.
9. Confirmation run of G01, G02, G03, G07 on the release build, Thu 11-05. The sandbox resource window fixes this date; any fix landing after Wed 11-04 cannot be confirmed before release.

Analysis cases (not in the gate): decision-table cases for input modes, remaining BVA points, all-transitions cases for the state machine, process-kill recovery, same-card-twice, latency measurement, security checklist, reconciliation export, admin refund screen, usability and keyboard check. A failure there informs; if a failure is traced to the change and would stop the release, its case moves into the gate with a dated note.

**Metrics to collect**

| Metric | Decision it supports |
| :--- | :--- |
| Gate cases passed / 8, per build | Go/no-go |
| Open defects by severity, per day | Whether code freeze on 11-04 holds |
| Risk coverage: register rows with at least one executed case / 18 | Whether the residual risk list is complete |
| Refund latency in G02: max and p95 over runs | Exit criterion and production alert threshold |
| Tester hours used against the item 7 estimate, per progress report | Whether to drop analysis cases or ask for developer time |
| Production after release: single-card success rate, split success rate, refund latency, refund failures, hourly for the first 2 h and daily for a week | Whether to turn the flag off |

**Test data: fixture set**

| ID | Record | State assumed | May be changed? | Rebuild |
| :-- | :--- | :--- | :--- | :--- |
| F1 | Sandbox test card, approves | Active | Read only | PayGate documentation |
| F2 | Sandbox test card, declines (insufficient funds) | Active | Read only | PayGate documentation |
| F3 | Sandbox test card, times out | Active, confirmed 10-27 | Read only | PayGate documentation; if absent, timeout is stub-only and noted in the plan |
| F4 | Stub scenario set v1: approve-approve, approve-decline, approve-timeout, refund-500-then-200, duplicate request, kill-between-legs | Versioned in repo | Add scenarios; never edit recorded responses | Re-record on a sandbox day |
| F5 | Test customer account with saved address, no saved cards | Logged out, empty cart | Cart may be written; restore to empty | Seed script |
| F6 | Product priced to give odd-cent totals (e.g. 100.01, 0.03, 999.99) | In catalogue on dev and staging | Read only | Seed script |

Credentials for sandbox and stub live in the team secret store, never in this plan or in test cases. A case whose fixture is missing is blocked, not failed.

**Environments**

| Environment | Gateway | Use |
| :--- | :--- | :--- |
| Local | Stub | Developer dry runs; never a recorded result |
| Dev | Stub v1 | System tests, analysis cases, retests, every working day |
| Staging | PayGate sandbox | System integration, gate confirmation, Tuesdays and Thursdays only |
| Production | PayGate live | Canary behind the flag, monitoring metrics above |

**Deviations from the test policy and strategy.** No load test (reason in item 1). Independence at system level is "some" rather than "high" because no tester outside the team is available. No full accessibility audit in this release. Each deviation is listed as residual risk in the go/no-go record.

## 7. Estimate

**Technique:** three-point estimation (CTFL v4.0 §5.1.4), chosen because one estimator is available and the margin of error must be visible. Work decomposed into tasks; E = (a + 4m + b) / 6, SD = (b − a) / 6, in person-hours.

| Task | Who | a | m | b | E |
| :--- | :--- | :-- | :-- | :-- | :-- |
| Test analysis and design: Gherkin, decision table, BVA, state-transition cases, gate | Tester | 5 | 7 | 10 | 7.2 |
| Stub scenario list and review of stub fidelity | Tester | 2 | 3 | 5 | 3.2 |
| Sandbox execution, two windows, plus characterization on 10-27 | Tester | 6 | 8 | 12 | 8.3 |
| Single-card regression: suite run, impact-based manual cases | Tester | 2 | 3 | 5 | 3.2 |
| Exploratory session and security checklist | Tester | 2 | 4 | 6 | 4.0 |
| Progress reports, go/no-go record, completion report | Tester | 2 | 3 | 4 | 3.0 |
| **Tester total** | | **19** | **28** | **42** | **28.8** |
| Unit and component integration tests, including state machine and idempotency | Developers | 8 | 12 | 20 | 12.7 |
| Build and record the PayGate stub | Developers | 2 | 3 | 5 | 3.2 |
| **Developer test total** | | **10** | **15** | **25** | **15.8** |

**Result.** Tester effort 29 ± 4 h (between 25 and 33), against 40 h available. The remaining 7 to 11 h are the buffer for fix-and-retest cycles (R19). Developer test effort 16 ± 3 h (between 13 and 19), on top of building the feature.

**Assumptions behind the figures.** A10 holds (stub ready by 10-28); the regression suite is automated and green today; no more than two Critical or High defects need a second sandbox confirmation; the PO answers the open questions by 10-28. If any fails, the estimate is re-issued in the next progress report with a dated note, not overwritten.

## 8. Budget and schedule

**Budget.** N/A — no monetary budget given; the budget is the people in item 7: about 40 tester hours and about 16 developer hours for test work. PayGate sandbox use is assumed free.

**Schedule** (working days; sandbox days marked)

| Day | Date | Activities | Milestone |
| :-- | :--- | :--- | :--- |
| 1 | Mon 10-26 | Plan review with devs and PO; open questions sent; flag confirmed (A8); Gherkin scenarios drafted; `/qa-static` review of the state machine design | Plan approved |
| 2 | Tue 10-27 (sandbox) | PayGate characterization: confirm F1 to F3, minimum charge (A3), refund response shape and timing; record responses for the stub | Sandbox facts known |
| 3 | Wed 10-28 | Stub v1 built from recordings; unit tests under way; test cases written | Stub ready |
| 4 | Thu 10-29 (sandbox) | Stub contract check against sandbox (R14); if a first build exists, early G01 dry run; progress report | Stub trusted |
| 5 | Fri 10-30 | Feature complete behind flag; CI green; "Ready for QA" | System test entry |
| 6 | Mon 11-02 | G04 to G06, G08 on the stub; analysis cases start; exploratory session with finance ops and support | Stub-side gate done |
| 7 | Tue 11-03 (sandbox) | G01, G02, G03, G07 on staging; refund latency measured; progress report | Main gate run |
| 8 | Wed 11-04 | Fixes; retests on the stub; remaining analysis cases; **code freeze end of day** | Release build cut |
| 9 | Thu 11-05 (sandbox) | Confirmation run of G01, G02, G03, G07 on the release build; PO acceptance walkthrough; go/no-go record | Go/no-go |
| 10 | Fri 11-06 | Release with flag off; flag on for a canary share; 2-hour watch of the production metrics; completion report | Released |

**Contingency.** If the 11-03 run fails on a Critical defect and the fix cannot be confirmed on 11-05, the choices put to the PO are: ship 5.3 with the flag off and enable it after a confirmation run on Tue 11-10, or slip the release. Shipping flag-on without a sandbox confirmation is not offered.

## 9. Configuration management of testware

- **Identification and versioning.** This plan, the Gherkin files, test cases TC-SPLIT-NNN, the stub scenario set, exploratory notes and reports live in the repository under a folder for release 5.3 (assumed `docs/qa/5.3-split-payment/`), versioned with the code. Defect reports live in the tracker and link back by case ID.
- **References by identifier and version.** Every result names the git commit SHA, the staging deployment tag, the stub version (v1, bumped on any change) and, for sandbox runs, the date and PayGate API version header observed. "Latest build" is never a valid reference.
- **Baselines.** Staging on 11-04 after code freeze is the release baseline: build SHA, flag state, stub version, fixture seed version recorded in the go/no-go record. The sandbox is external and unversioned; its date stands in for a version, and the characterization notes from 10-27 record what it did.
- **Restorable baselines.** Any earlier build can be redeployed to dev by SHA, with the matching stub version, to reproduce a result.
- **In CI/CD.** Unit, component integration and the stub-based system suite run on every push; the run ID is the result's identifier. Sandbox runs are manual and recorded in the progress report of that day.
- **Handover-ready state.** The plan's gate table, the fixture set and the "Not run — resume point" section are updated at the end of each day, so a developer or the PO can continue the gate if the tester is unavailable (R13).

**Corrections.** Nothing in this plan is deleted once shared. Re-scored risks, revised estimates, assumptions proved wrong and gate changes are corrected in place as `Correction, YYYY-MM-DD, <author>: <what was wrong and what is right>` or with strike-through and the reason.
