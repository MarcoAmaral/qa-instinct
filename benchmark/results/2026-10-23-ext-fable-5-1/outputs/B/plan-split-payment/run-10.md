# Test Plan: Split Payment (Release 5.3)

**Version** 1.0 · **Date** 24 Oct 2026 · **Owner** QA (0.5 FTE) · **Release** Fri 6 Nov 2026 (10 working days)

## 1. Scope and assumptions

**In scope:** two-card split at checkout, cent allocation rules, both PayGate charges, automatic refund of card 1 when card 2 is declined, order and payment records, and regression of the existing single-card checkout.

**Out of scope (flagged as follow-up risk):** more than two cards, customer-initiated refunds or cancellations of split orders after purchase, multi-currency, saved-card wallets, and chargeback handling.

Assumptions made where the brief is silent:

- **A1** Charges are synchronous auth-and-capture calls. Card 2 is charged only after card 1 returns success.
- **A2** The customer enters the card 1 amount in currency units; the UI converts to cents. An "equal split" shortcut exists, which is where the remainder-cent rule applies.
- **A3** Each card must carry at least 1 cent, so the first-card amount must be strictly between 0 and the order total. First-card amount equal to the total is rejected, not silently treated as single-card.
- **A4** "Refunded within 60 seconds" is measured from receipt of the card 2 decline to PayGate accepting the refund request, not to funds reaching the customer. Refund is driven by a retrying background job.
- **A5** Every PayGate call carries an idempotency key per order and card slot.
- **A6** If the refund cannot be completed after retries, the order is placed in a manual review queue and an alert fires. If this does not exist, it is raised as a requirement gap on day 1.
- **A7** The feature ships behind a feature flag with percentage rollout. If no flag exists, QA recommends adding one; it is the main mitigation for the single-card regression risk.
- **A8** PayGate sandbox provides deterministic test cards for approve, decline, insufficient funds, and timeout, and supports refund calls.
- **A9** Card data is tokenised client-side and never reaches our servers, so PCI scope is unchanged.
- **A10** Developers will build and maintain a scriptable PayGate stub, since the sandbox is only available on Tuesdays and Thursdays.

## 2. Risk assessment

Scored Likelihood × Impact, each 1 to 3. Testing effort is allocated in order of score.

| ID | Risk | L | I | Score | Test focus |
|----|------|---|---|-------|------------|
| R1 | Single-card checkout regresses (about 4,000 orders/day) | 2 | 3 | 6 | Automated regression suite, sandbox smoke, feature flag, canary rollout |
| R2 | Card 2 declines and card 1 is not refunded, refunded late, or refunded twice | 2 | 3 | 6 | Decline scenarios, refund timing measurement, retry and failure paths |
| R3 | Unknown-outcome gateway responses (timeout, 5xx) leave a charge orphaned or trigger a wrong refund | 2 | 3 | 6 | Stub-driven fault injection, status reconciliation, idempotency |
| R4 | Amounts do not sum to the total, rounding or remainder cent is wrong, or client-side amount is tampered | 2 | 3 | 6 | Unit tests on allocation, boundary data, server-side validation, API tampering |
| R5 | Gateway integration under-tested because sandbox is available only 4 days before release | 3 | 2 | 6 | Faithful stub built from recorded sandbox responses, strict sandbox-day agenda |
| R6 | Double submission or retry charges a card twice | 2 | 2 | 4 | Concurrency tests, idempotency key checks |
| R7 | Downstream records wrong: order shows paid when refunded, invoices, emails, finance exports show one payment | 2 | 2 | 4 | Order state and ledger checks after every scenario |
| R8 | Checkout latency rises because of two sequential gateway calls | 2 | 1 | 2 | Timing against existing checkout baseline |
| R9 | Same card used in both slots, or card validation diverges between slots | 1 | 2 | 2 | Negative input tests |
| R10 | Accessibility and usability of the new amount control | 2 | 1 | 2 | Keyboard and screen-reader check, mobile layout |

## 3. Test approach by level

- **Unit (developers, days 1 to 4).** Cent allocation function with a full boundary table, input parsing, idempotency key generation, and the refund job state machine. Target: every row in section 4.1 covered by a unit test before QA touches the UI.
- **Integration against the PayGate stub (QA and developers, any day).** All decline, timeout, 5xx, slow-response and refund-failure paths. The stub is seeded with real responses recorded on the first sandbox day so it is faithful.
- **Integration against the PayGate sandbox (Tue and Thu only).** Happy paths, real decline codes, refund timing measurement, and single-card regression. Sandbox time is reserved for things the stub cannot prove.
- **Regression (automated, every build).** Existing single-card checkout suite plus a new split-payment suite. Both must be green for release.
- **Exploratory (QA, days 5 to 8).** Session-based, one charter per top risk.
- **Production verification.** Flag enabled for internal accounts first, then 5 percent of traffic, with a daily reconciliation report comparing PayGate transactions with order payments.

## 4. Test scenarios

Priority: P1 must pass before release, P2 should pass, P3 if time allows.

### 4.1 Amount allocation (R4, P1)

| Total (cents) | Input | Expected card 1 / card 2 |
|---------------|-------|--------------------------|
| 1000 | equal split | 500 / 500 |
| 1001 | equal split | 501 / 500 (remainder on card 1) |
| 1 | any | rejected, cannot split |
| 2 | equal split | 1 / 1 |
| 1000 | card 1 = 1 | 1 / 999 |
| 1000 | card 1 = 999 | 999 / 1 |
| 1000 | card 1 = 0 | rejected |
| 1000 | card 1 = 1000 | rejected (see A3) |
| 1000 | card 1 = 1001 | rejected |
| 1000 | card 1 = -1 | rejected |
| 1000 | "10.005" | rejected, more than two decimals |
| 1000 | "9,99" or "9.99" | locale-safe parse to 999 |
| 99999999 | equal split | 50000000 / 49999999, no overflow |
| any | card 1 amount altered in the API request after UI validation | server recomputes and rejects |

Also assert: card1 + card2 equals total on the order record for every scenario, and totals including tax, shipping and discounts are used, not the subtotal.

### 4.2 Charge sequencing and outcomes (R2, R3, P1)

- Both approve: order paid, two payment records, confirmation email lists both amounts.
- Card 1 declines: card 2 is never attempted, order unpaid, customer sees a clear message, no refund job created.
- Card 2 declines (each sandbox decline code): card 1 refund requested, refund accepted within 60 seconds, order unpaid, customer told what happened and that the refund is in progress.
- Card 2 timeout with unknown outcome: system queries PayGate status before deciding. If card 2 actually succeeded, no refund of card 1. If it failed, refund proceeds. This is the highest-value fault-injection test.
- Card 1 timeout with unknown outcome: card 2 is not attempted until card 1 status is resolved.
- PayGate returns 5xx on the refund call: job retries with backoff, succeeds on a later attempt, timing still within 60 seconds where possible, and the order enters manual review with an alert if retries are exhausted (A6).
- Refund attempted twice (job restart, duplicate event): exactly one refund reaches PayGate.
- Same order resubmitted after browser refresh or back button: no additional charges.
- Two parallel submissions of the same checkout: one succeeds, one is rejected.

### 4.3 Refund timing measurement (R2, P1)

On each sandbox day, run 20 card-2-decline orders and log the interval from decline response to refund acceptance. Release requires all 20 under 60 seconds on the final sandbox day, with the slowest value recorded in the release notes. Repeat 20 runs against the stub with a 10-second simulated gateway latency to prove retries fit the budget.

### 4.4 Single-card regression (R1, P1)

- Full automated single-card suite on every build.
- On each sandbox day: single-card approve, decline, and refund via the existing admin path.
- With the feature flag off, the checkout UI and API payloads are byte-for-byte identical to release 5.2.
- Checkout latency for single-card orders unchanged against the 5.2 baseline.

### 4.5 Records and downstream (R7, P2)

After each scenario in 4.2, verify order status, payment ledger entries, refund entries, customer email content, admin order view, and the finance export. Verify the daily reconciliation report flags an orphaned card 1 charge when one is deliberately created with the stub.

### 4.6 Inputs, security, and usability (R6, R9, R10, P2 to P3)

- Same card number in both slots: define and verify behaviour (assumed allowed with a warning).
- Expired or invalid card in slot 2 is rejected before any charge on slot 1.
- Rate limiting on the split endpoint matches single-card.
- Keyboard-only and screen-reader walk-through of the amount control; mobile viewport layout.
- Performance: split checkout p95 latency recorded and compared against single-card plus one gateway round trip.

## 5. Environments and tooling

- **PayGate stub:** developer-built, configurable per test for approve, decline code, timeout, 5xx, slow response, and refund failure. Seeded from responses recorded on Tue 27 Oct.
- **PayGate sandbox:** Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. Each day has a fixed agenda (section 6). Sandbox credentials and test card catalogue confirmed on day 1.
- **Test data:** the amount table in 4.1 as a shared fixture used by unit, API and UI tests.
- **Observability:** refund job dashboard with latency histogram, failed-refund alert, reconciliation report. These are release prerequisites, not nice-to-haves.

## 6. Schedule

QA effort is about 5 days in total. Developers own unit tests, the stub, and the fault-injection harness.

| Day | Date | QA (half day) | Developers | Sandbox |
|-----|------|---------------|------------|---------|
| 1 | Mon 26 Oct | Review brief, confirm assumptions A1 to A10 with developers, finalise this plan | Build stub skeleton, allocation unit tests | |
| 2 | Tue 27 Oct | Record sandbox responses for approve, each decline code, timeout, refund; confirm test card catalogue; single-card smoke on current build | Feed recordings into stub | Yes |
| 3 | Wed 28 Oct | API tests for 4.1 against stub | Feature code complete for charges | |
| 4 | Thu 29 Oct | Happy path and card 2 decline on sandbox, first refund-timing sample (10 runs) | Refund job and retry logic | Yes |
| 5 | Fri 30 Oct | Fault injection 4.2 against stub (timeouts, 5xx, duplicate refund) | Fix findings | |
| 6 | Mon 2 Nov | Records and downstream checks 4.5, exploratory charter on R3 | Fix findings, monitoring and alerts | |
| 7 | Tue 3 Nov | Full 4.2 on sandbox, 20-run refund timing, single-card regression | Fix findings | Yes |
| 8 | Wed 4 Nov | Security and usability 4.6, retest fixes on stub | Code freeze end of day | |
| 9 | Thu 5 Nov | Release candidate on sandbox: full P1 pass, 20-run timing, single-card regression, sign-off | Standby for blockers only | Yes |
| 10 | Fri 6 Nov | Release with flag off, enable for internal accounts, verify reconciliation report | Deploy, monitor | |

**Post-release:** flag to 5 percent of traffic on Mon 9 Nov, full rollout after two clean reconciliation reports.

## 7. Entry and exit criteria

**Entry to sandbox testing (Thu 29 Oct):** unit tests for 4.1 green, stub covers all response types, feature deployable to the test environment with the flag.

**Exit for release:**

- All P1 scenarios pass on the sandbox on Thu 5 Nov.
- 20 of 20 refund-timing runs under 60 seconds on Thu 5 Nov.
- Single-card regression suite green and sandbox single-card smoke passed.
- No open severity 1 or 2 defects. Severity 3 defects accepted in writing by the product owner.
- Failed-refund alert and reconciliation report demonstrated working in the staging environment.
- Feature flag verified off in production configuration.

## 8. Risks to this plan and mitigations

- **Code not ready for the Thu 29 Oct sandbox day.** Only two sandbox windows would remain. Mitigation: charges path is prioritised over refund path so day 4 can still cover happy path and basic decline. If it slips past Tue 3 Nov, release is recommended to slip one week to gain two more sandbox days.
- **Stub diverges from real PayGate behaviour.** Mitigation: stub built from recordings, and every stub-only scenario that can be reproduced on sandbox is repeated there on Nov 3 or 5.
- **Half-time tester is the single point of failure.** Mitigation: developers run the automated suites and the sandbox checklist themselves on days QA is absent. Checklist is written on day 1.
- **Refund-timing requirement cannot be met under gateway latency.** Mitigation: measured early on day 4 so there is time to change the retry strategy before code freeze.
- **Post-purchase refunds of split orders (out of scope) surface in production.** Mitigation: raised as a known gap with the product owner on day 1 and tracked for release 5.4. Support team is briefed on the manual process.

## 9. Roles

- **QA:** plan, API and UI tests, sandbox-day execution, refund timing, exploratory sessions, sign-off.
- **Developer 1:** allocation logic, unit tests, PayGate stub, fault-injection harness.
- **Developer 2:** refund job, idempotency, monitoring and alerts, reconciliation report.
- **Product owner:** confirms assumptions A3 and A6 on day 1, accepts residual defects at exit.
