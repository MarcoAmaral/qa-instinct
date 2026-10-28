# Test Plan: Split Payment (Release 5.3)

## 1. Summary

Split payment lets a customer pay one order with two cards, choosing the amount for card 1; card 2 takes the remainder. Both charges go through PayGate. If charge 2 is declined, charge 1 must be auto-refunded within 60 seconds.

Highest risks, in order: (1) money lost or double-charged when the second charge fails or the refund fails, (2) cent-rounding errors that leave the order under- or over-paid, (3) regression of the single-card checkout that handles ~4,000 orders/day, (4) only four PayGate sandbox days before release.

Testing effort is concentrated on the two-charge-plus-refund state machine and on cents arithmetic. Everything that does not need PayGate is tested against a local gateway stub so the four sandbox days are reserved for confirmation runs only.

## 2. Key dates and capacity

| Item | Value |
|---|---|
| Today | Fri 24 Oct 2026 (plan written on Sat 24 Oct; day 1 = Mon 26 Oct) |
| Release | Fri 6 Nov 2026 (working day 10) |
| PayGate sandbox days | Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov |
| Tester capacity | 5 person-days (half time over 10 days) |
| Developer test capacity | ~2 person-days total assumed (unit tests, stub, fixtures) |
| Code-complete target | Wed 28 Oct (needed to use the 29 Oct sandbox day meaningfully) |
| Code freeze | Wed 4 Nov end of day |

## 3. Assumptions (stated where the brief is silent)

1. **Charge order**: card 1 is charged first, then card 2. Card 2 is attempted only if card 1 succeeds. If card 1 is declined, nothing else is charged and the customer can retry.
2. **"Remainder cent goes on the first card"** applies when the customer chooses an even split (e.g. 50/50 of an odd total). When the customer enters an explicit amount for card 1, that amount is used as entered and card 2 gets total minus card 1.
3. **Valid card-1 amount**: strictly greater than 0 and strictly less than the order total. 0 or the full total means it is not a split payment and is rejected (or routed to single-card checkout).
4. **Refund**: full refund of charge 1 via PayGate's refund API, triggered by the system without human action. "Within 60 seconds" is measured from receiving the decline on charge 2 to PayGate acknowledging the refund request.
5. **Refund failure**: if the auto-refund fails or times out, the order is flagged for manual intervention and an alert is raised. The customer is not shown "payment successful."
6. **Same card twice** is allowed (two charges on one card) unless product says otherwise; it is tested either way.
7. **Currency**: single currency, 2-decimal minor unit. No multi-currency orders.
8. **PayGate sandbox** supports decline, timeout and refund-failure simulation via test card numbers or amounts. If it does not, the stub covers those paths and the sandbox covers happy path + one real decline.
9. **A gateway stub** (local fake PayGate) is built or extended by the developers in week 1. Without it, this plan is not achievable.
10. **Feature flag**: split payment ships behind a flag, defaulting off, so rollback is a flag flip, not a redeploy.
11. **Observability**: each PayGate call (charge, refund) is logged with order id, amount, result, and timestamp.

If any assumption is wrong, the affected cases below are re-scoped, not dropped.

## 4. Scope

**In scope**
- Split amount entry and validation (UI and API).
- Cents arithmetic and rounding.
- Two-charge orchestration against PayGate, including all failure permutations.
- Automatic refund of charge 1 and the 60-second SLA.
- Order and payment records, customer-facing messages, receipts/emails.
- Regression of single-card checkout.
- Idempotency and concurrency (double submit, retry after timeout).
- Basic performance impact on checkout.

**Out of scope**
- PayGate internal behaviour, PCI compliance of PayGate.
- More than two cards.
- Partial refunds, chargebacks, post-order refunds of split orders (tested only at smoke level unless time remains).
- Load testing beyond a short checkout soak (see §7).

## 5. Risk analysis and prioritisation

Scored Likelihood (L) × Impact (I), 1–5 each.

| # | Risk | L | I | Score | Mitigation / test focus |
|---|---|---|---|---|---|
| R1 | Card 2 declined, refund of card 1 not issued, late, or issued twice → customer charged with no order, or refunded twice | 4 | 5 | 20 | Full failure-path matrix (§6.2), timed refund assertions, idempotency tests, log/alert checks |
| R2 | Cents rounding wrong → sum of charges ≠ order total; off-by-one cent per order, multiplied over volume | 4 | 4 | 16 | Boundary-value unit tests + property test "card1 + card2 == total" over random totals |
| R3 | Single-card checkout regressed (shared code paths, DB schema, order state machine) | 3 | 5 | 15 | Automated regression suite run on every build; manual smoke on each sandbox day; flag-off testing |
| R4 | Transient PayGate failure (timeout, 5xx) on charge 2 is treated as decline, or as success; retries create duplicate charges | 3 | 5 | 15 | Stub-driven timeout/ambiguous-response tests; idempotency keys verified on PayGate side on a sandbox day |
| R5 | Amount validation bypass via API (negative, zero, > total, non-integer, float cents) | 3 | 4 | 12 | API-level negative tests independent of UI |
| R6 | Only 4 sandbox days; a blocking defect found on Thu 5 Nov cannot be re-verified against PayGate before Fri release | 4 | 3 | 12 | Front-load sandbox use; treat 5 Nov as confirmation only; go/no-go criteria in §9 |
| R7 | Concurrency: double-click / double submit / two tabs → two split sessions, four charges | 2 | 5 | 10 | Double-submit tests at UI and API, idempotency key per order attempt |
| R8 | Partial-success state not recoverable: refund fails after charge 2 decline; order stuck | 2 | 5 | 10 | Refund-failure path, manual-intervention queue, alert fired |
| R9 | Receipts, emails, order history show wrong amounts or only one card | 3 | 2 | 6 | Checked as part of happy-path runs |
| R10 | Performance: extra gateway call doubles checkout latency; extra DB writes affect 4,000/day throughput | 2 | 3 | 6 | Short soak with flag on vs off |
| R11 | Security: card-1 amount tampered client-side; card data for two cards logged in plain text | 2 | 4 | 8 | Server-side validation test, log inspection for PAN leakage |

Test effort allocation (of 5 tester-days): R1/R4/R7/R8 ≈ 2.0 days; R2/R5 ≈ 0.75; R3/R10 ≈ 1.0; R6 overhead (sandbox-day planning and execution) ≈ 0.75; R9/R11 and reporting ≈ 0.5.

## 6. Test design

### 6.1 Amount validation and rounding (R2, R5) — runs against stub, automatable

Developer-owned unit tests, tester reviews and adds cases.

| ID | Total (cents) | Card 1 input | Expected card 1 | Expected card 2 | Notes |
|---|---|---|---|---|---|
| A01 | 10000 | 5000 | 5000 | 5000 | even split |
| A02 | 10001 | "split evenly" | 5001 | 5000 | remainder cent to card 1 |
| A03 | 1 | "split evenly" | 1 | 0 | card 2 = 0: reject or treat as single-card (assumption 3) |
| A04 | 10000 | 1 | 1 | 9999 | minimum card 1 |
| A05 | 10000 | 9999 | 9999 | 1 | minimum card 2 |
| A06 | 10000 | 0 | reject | — | |
| A07 | 10000 | 10000 | reject | — | |
| A08 | 10000 | 10001 | reject | — | |
| A09 | 10000 | -1 | reject | — | API only |
| A10 | 10000 | 50.005 / "abc" / null | reject | — | API only, type coercion |
| A11 | 10000 | 12.34 (UI decimal entry) | 1234 | 8766 | UI→cents conversion |
| A12 | 999999999 | "split evenly" | 500000000 | 499999999 | large total, overflow check |
| A13 | any | any valid | — | — | property test: card1 + card2 == total, both > 0, 1000 random totals |
| A14 | total changes after split chosen (coupon applied, item removed) | — | recompute or reject stale split | — | stale-state test |

### 6.2 Charge orchestration and refund (R1, R4, R7, R8) — stub first, sandbox confirmation

Each case checks: PayGate calls made (count, order, amounts, idempotency keys), order status, payment records, customer message, refund timing, logs/alerts.

| ID | Card 1 result | Card 2 result | Refund result | Expected outcome |
|---|---|---|---|---|
| C01 | approved | approved | n/a | order paid, two payment records, receipt shows both |
| C02 | declined | not attempted | n/a | no charge, customer can retry, no refund issued |
| C03 | approved | declined | approved | refund of card 1 within 60 s, order unpaid, customer told card 2 declined and card 1 refunded |
| C04 | approved | declined | declined / error | order flagged for manual intervention, alert raised, customer not shown success, no second refund attempt that could duplicate |
| C05 | approved | declined | timeout | as C04, plus refund not retried blindly; status queried before retry |
| C06 | approved | timeout (ambiguous) | — | system must not assume decline; expected: query PayGate for status, then refund or complete. Verify no duplicate charge 2 |
| C07 | timeout (ambiguous) | not attempted | — | status query on card 1 before any retry; no double charge |
| C08 | approved | 5xx from PayGate | approved | treated like C03 after bounded retries |
| C09 | approved | approved | n/a, then double submit of same order | second submit rejected, no extra charges (idempotency) |
| C10 | approved | declined, refund SLA | measure | refund issued at 59 s passes; stub-induced 61 s delay → SLA breach logged/alerted |
| C11 | same card for both | approved/approved | n/a | two charges on one card, both recorded |
| C12 | card 1 approved; service crashes before charge 2 | — | — | on restart/recovery: either charge 2 completed or card 1 refunded; never left charged silently |
| C13 | card 2 approved, DB write fails | — | — | reconciliation path; both charges reconciled or refunded; alert raised |
| C14 | repeat C03 100× via stub | — | — | exactly 100 refunds, 0 duplicates, all < 60 s |

C01, C03, C04, C06, C09 and C11 are re-run on PayGate sandbox (see §8). The rest rely on the stub because sandbox cannot reliably simulate crashes or DB failures.

### 6.3 Regression: single-card checkout (R3)

- Existing automated checkout regression suite runs on every build with flag off and flag on.
- Manual smoke (15 min) on each sandbox day: single card approved, declined, timeout; receipt; order history.
- Database migration tested forward and backward on a copy of production-shaped data.
- Verify flag-off path is byte-for-byte the old request to PayGate (compare logged payloads before/after).

### 6.4 UI and customer communication (R9)

- Amount entry: decimal input, currency formatting, live display of card 2 amount, error messages for A06–A08.
- Messages for C02, C03, C04 are accurate and do not say "payment successful" when it is not.
- Email/receipt shows both cards (last 4 digits), both amounts, and refund where applicable.
- Order history and admin view show two payments and any refund.
- Accessibility smoke: keyboard navigation through the split form, errors announced.

### 6.5 Security (R11)

- Card-1 amount altered in the browser request → server recomputes/rejects.
- Logs and error messages contain no full PAN or CVV for either card.
- Refund endpoint cannot be triggered by the client directly.

### 6.6 Performance (R10)

- Baseline checkout latency with flag off; compare with flag on for single-card orders (should be unchanged).
- Split-order latency: p95 under 2× single-card p95 (assumed acceptable; confirm with product).
- 30-minute soak at 3× the daily peak rate against the stub, mixed 90% single / 10% split, no errors, no growing refund queue.

## 7. Environments and tools

| Environment | Use | Availability |
|---|---|---|
| Local / CI with PayGate stub | Unit, API, orchestration, concurrency, soak | Every day |
| Staging with PayGate sandbox | Confirmation of C01, C03, C04, C06, C09, C11, refund timing, regression smoke | Tue/Thu only |
| Staging with stub | Everything else, UI, regression | Every day |

Stub requirements (dev-built, week 1): per-request control of approve / decline / timeout / 5xx / delayed response for charge and refund; records every call with idempotency key; configurable latency to test the 60 s SLA.

Tooling: existing API test framework for 6.1 and 6.2; existing UI regression suite for 6.3; load tool already in use for 6.6; log search for refund timing (timestamp of decline → timestamp of refund request).

## 8. Schedule

| Day | Date | Tester (half day) | Developers | Sandbox |
|---|---|---|---|---|
| 1 | Mon 26 Oct | Review design, finalise this plan, write API cases 6.1/6.2 | Build stub, unit tests for rounding | — |
| 2 | Tue 27 Oct | Sandbox: verify stub matches real PayGate responses (shape, codes, refund API, decline test cards); run C01–C03 on whatever is built | Feature dev | ✔ |
| 3 | Wed 28 Oct | Run 6.1 on stub; log defects | Code complete target | — |
| 4 | Thu 29 Oct | Sandbox: C01, C03, C04, C06, C09, C11; refund timing; single-card smoke | Fix defects | ✔ |
| 5 | Fri 30 Oct | Stub: C05–C08, C12–C14; concurrency | Fix defects | — |
| 6 | Mon 2 Nov | UI (6.4), security (6.5), regression suite flag on/off | Fix defects | — |
| 7 | Tue 3 Nov | Sandbox: re-run failed cases, full happy path end to end incl. receipt/email; single-card smoke | Fix defects | ✔ |
| 8 | Wed 4 Nov | Performance soak (6.6), migration rollback test; code freeze EOD | Final fixes only | — |
| 9 | Thu 5 Nov | Sandbox: release-candidate confirmation run (C01, C03, C04, C09 + single-card smoke); go/no-go | Release prep | ✔ |
| 10 | Fri 6 Nov | Release; production verification (§10) | Release | — |

Contingency: there is none inside the tester's 5 days. If code-complete slips past Wed 28 Oct, the 29 Oct sandbox day is lost and the release is at risk; escalate on 28 Oct, not later.

## 9. Entry and exit criteria

**Entry (to start sandbox testing on 29 Oct)**
- Stub-based cases A01–A14 and C01–C04 passing in CI.
- Feature deployed to staging behind flag.
- PayGate sandbox credentials and decline/refund test cards confirmed on 27 Oct.

**Exit / go criteria (decided Thu 5 Nov)**
- All §6.2 cases pass; C03 refund observed < 60 s on sandbox at least 5 times; zero duplicate charges or refunds across all runs.
- Property test A13 passes; A01–A12 pass.
- Single-card regression suite green with flag on and off; sandbox smoke green on 5 Nov.
- No open Severity 1 or 2 defects. Severity 1 = money moved incorrectly or lost. Severity 2 = order in unrecoverable state, wrong customer message about payment outcome, single-card regression.
- Alerting for C04/C05/C10 verified to fire in staging.
- Rollback (flag off) tested on staging.

**No-go triggers**
- Any failure in C03, C04, C06 or C09 found on 5 Nov that cannot be re-verified against sandbox before release.
- Any single-card regression.

## 10. Release and post-release verification

- Ship with flag off. Enable for internal staff accounts first on Fri 6 Nov, run C01 and C03 with real cards and small amounts, confirm refund timing in production logs.
- Enable for 5% of customers for 3 working days (next sandbox day for diagnosis is Tue 10 Nov), monitoring: split-order count, charge-2 decline rate, refund count vs decline count (must match), refund latency p95, manual-intervention queue size, single-card error rate vs baseline.
- Daily reconciliation report for the first week: sum of charges minus refunds per split order equals order total or zero.
- Rollback: flag off. Open split orders in mid-flight must still complete or refund; verified by C12.

## 11. Deliverables

- This plan (reviewed with developers on day 1).
- Automated API tests for §6.1 and §6.2 (stub), added to CI.
- Sandbox test log per sandbox day with PayGate transaction ids for traceability.
- Defect list with severity.
- Go/no-go report on Thu 5 Nov.
- Post-release monitoring checklist for the on-call engineer.

## 12. Open questions to resolve on day 1 (plan proceeds on the assumptions in §3 meanwhile)

1. Does product want 0 / full-total card-1 amounts rejected or silently routed to single-card?
2. Is the same card allowed for both charges?
3. What is the required behaviour when charge 2 times out ambiguously (assumption: status query before any decision)?
4. Who is paged when the auto-refund fails, and what is the manual process?
5. Can PayGate sandbox simulate refund failure and timeout? If not, these remain stub-only and that is noted as residual risk in the go/no-go report.
