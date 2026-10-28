# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** two-card split checkout, cent allocation, PayGate charge sequencing, automatic refund on second-card decline, and non-regression of single-card checkout.

**Assumptions (made where the brief is silent):**

- A1. Today is Sat 24 Oct 2026; release is Fri 6 Nov 2026. Sandbox windows: Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov.
- A2. The customer may either type an amount for card 1 or pick "split evenly". The odd-cent rule applies to "split evenly"; a typed amount is used as-is.
- A3. Card 1 is charged first; card 2 is charged only if card 1 succeeds. If card 1 is declined, card 2 is never attempted.
- A4. Single currency per order; no multi-currency splits.
- A5. Card data is tokenised by PayGate; our system never stores PANs.
- A6. PayGate sandbox provides deterministic test cards for approve, decline, and timeout.
- A7. Refund-on-decline is implemented as a background job with retries and alerting when it cannot complete.
- A8. Developers will build a local PayGate stub so tests can run on non-sandbox days.
- A9. "Half time" tester = roughly 5 person-days across the 10-day window.

## 2. Risk assessment

Priority = likelihood × impact. Testing effort follows priority order.

| ID | Risk | Likelihood | Impact | Priority |
|----|------|-----------|--------|----------|
| R1 | Card 2 declined, card 1 refund fails, is late (>60 s), or is duplicated. Customer loses money. | Med | Critical | **P1** |
| R2 | Single-card checkout regresses (4,000 orders/day). | Med | Critical | **P1** |
| R3 | Cent allocation wrong: amounts do not sum to the total, odd cent on wrong card, negative or zero amounts accepted. | High | High | **P1** |
| R4 | Partial-failure states: timeout or gateway outage between charge 1 and charge 2 leaves the order half paid with no refund. | Med | Critical | **P1** |
| R5 | Retry or double-submit produces duplicate charges (idempotency). | Med | High | **P2** |
| R6 | Input validation gaps: amount > total, amount = total, same card twice, non-numeric, currency rounding on display vs. cents. | High | Med | **P2** |
| R7 | Order, receipt, and reconciliation records show one charge instead of two; later customer-service refunds act on the wrong card. | Med | Med | **P2** |
| R8 | Stub diverges from real PayGate behaviour, so green tests on non-sandbox days hide real defects. | Med | High | **P2** |
| R9 | Performance: two sequential gateway calls push checkout latency past the current timeout. | Low | Med | **P3** |
| R10 | Security: card 2 token or amount exposed in logs, URLs, or client state. | Low | High | **P3** |

## 3. Test approach by risk

**R1 — Refund on second decline (P1)**
- Unit: decline on card 2 triggers exactly one refund of card 1 for the exact charged amount.
- Integration (sandbox): decline test card on card 2; measure wall-clock time from decline response to refund confirmation. Pass threshold: ≤ 60 s on 10 consecutive runs.
- Failure injection (stub): refund call returns 5xx, times out, or succeeds after retry. Verify retries, no duplicate refund, and alert raised when retries are exhausted.
- Verify order status reads "payment failed, refund issued" and customer notification is sent.

**R2 — Single-card regression (P1)**
- Run the existing single-card automated suite on every build.
- Manual smoke of single-card checkout on each sandbox day with real gateway.
- Confirm the split feature is behind a flag; test single-card with the flag both on and off.
- Compare single-card checkout latency before and after the change.

**R3 — Cent allocation (P1)**
- Unit, table-driven, run by developers: totals of 1, 2, 3, 99, 100, 101, 999, 12345 cents and a large value near the integer limit. Assert card1 + card2 = total and odd cent lands on card 1.
- Property-based test: for any total ≥ 2 cents and any valid card 1 amount, sum equals total and both amounts are ≥ 1 cent.
- UI: confirm the displayed amounts match the cents sent to PayGate (no float rounding on display).

**R4 — Partial failure between charges (P1)**
- Stub: card 1 succeeds, then card 2 call times out with unknown outcome. Verify the system queries PayGate for the final state before deciding to refund or complete.
- Stub: application crash after card 1 success. Verify recovery job detects the orphaned charge and refunds it.
- Sandbox: PayGate timeout test card on card 2.

**R5 — Idempotency (P2)**
- Submit the same checkout twice in quick succession (double-click, browser retry). Verify exactly two charges in total, not four.
- Verify an idempotency key is sent per charge and per refund.

**R6 — Validation (P2)**
- Boundary cases: card 1 amount = 0, = 1 cent, = total − 1, = total, > total, negative, decimals, blank.
- Same card entered for both slots (assume rejected; confirm with developers).
- Expected: clear error, no gateway call made.

**R7 — Records and downstream (P2)**
- Order detail, receipt email, admin panel, and reconciliation export show two charges with correct amounts and gateway references.
- Customer-service partial refund on a split order refunds the correct card.

**R8 — Stub fidelity (P2)**
- On the first sandbox day, record real PayGate request and response payloads for approve, decline, timeout, and refund. Update the stub to match before relying on it.

**R9, R10 (P3)**
- Time ten split checkouts in sandbox; flag if p95 exceeds the existing checkout timeout.
- Grep application logs and browser network traffic from one full split flow for tokens, PANs, or amounts in URLs.

## 4. Environments and sandbox strategy

The sandbox is available 4 of the 10 working days, so it is the scarce resource.

- **Non-sandbox days:** unit, property, UI, and failure-injection tests against the PayGate stub.
- **Sandbox days:** reserved for R1 timing, R4 real timeouts, R2 real-gateway smoke, R8 payload capture, and R9 latency. Prepare every sandbox-day script the day before so no window is wasted.
- **Contingency:** if PayGate sandbox is down on a scheduled day, the next window is 2 days away. Any P1 sandbox test not passed by Thu 5 Nov blocks release.

## 5. Schedule

| Day | Date | Activity | Who |
|-----|------|----------|-----|
| 1 | Mon 26 Oct | Review design, confirm assumptions A2/A3/A7 with developers, write sandbox-day scripts, build stub | Tester, Dev |
| 2 | **Tue 27 Oct (sandbox)** | Capture real payloads (R8), first R1 timing run on whatever is built, single-card smoke | Tester |
| 3 | Wed 28 Oct | Cent allocation and validation tests (R3, R6) against stub; update stub from captured payloads | Tester, Dev |
| 4 | **Thu 29 Oct (sandbox)** | R1 decline-and-refund timing, R4 timeout cards, single-card smoke | Tester |
| 5 | Fri 30 Oct | Failure injection on stub (R1 refund failures, R4 crash recovery), idempotency (R5) | Tester, Dev |
| 6 | Mon 2 Nov | Records and downstream (R7), security log review (R10), fix verification | Tester |
| 7 | **Tue 3 Nov (sandbox)** | Full regression: 10× R1 timing runs, R2 smoke, R9 latency | Tester, Dev |
| 8 | Wed 4 Nov | Fix verification on stub, exit criteria review | Tester |
| 9 | **Thu 5 Nov (sandbox)** | Final sandbox confirmation of any fixes, go/no-go | Tester, Dev |
| 10 | Fri 6 Nov | Release with flag off, enable for internal users, monitor | Dev |

Developers own unit and property tests (R3, R5) and the stub. The tester owns sandbox sessions, failure injection, and exit review.

## 6. Entry and exit criteria

**Entry:** feature deployable to a test environment by Tue 27 Oct, stub available by Wed 28 Oct, feature flag in place.

**Exit (release blockers):**
- All P1 tests pass, including 10 consecutive R1 refund runs ≤ 60 s against real sandbox.
- Single-card automated suite green on the release candidate, with flag on and off.
- No open P1 or P2 defects. P3 defects may ship with a logged ticket.
- Alerting for failed refunds verified to fire.

## 7. Out of scope

Multi-currency, more than two cards, saved-card wallets, chargeback flows, PayGate load testing.

## 8. Risks to this plan

- Only 4 sandbox windows: a sandbox outage or a late build consumes 25% of real-gateway test time. Mitigation: dark launch behind a flag on Fri 6 Nov, enable for internal users first, monitor refund-time metric in production before customer rollout.
- Half-time tester: P3 items are the first to drop if P1 fixes arrive late.
- Assumption A7 (background refund job) changes the R1 and R4 tests if wrong. Confirm on day 1.
