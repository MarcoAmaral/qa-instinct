# Test Plan: Split Payment (Release 5.3)

**Version:** 1.0 | **Date:** 2026-10-24 | **Owner:** QA (tester, half time) | **Release target:** 2026-11-06

## 1. Objective and scope

Verify that a customer can pay for one order with two cards, that amounts are split correctly to the cent, that both charges go through PayGate, that a declined second charge triggers an automatic refund of the first charge within 60 seconds, and that the existing single-card checkout (about 4,000 orders/day) is unaffected.

**In scope**
- Amount entry and split calculation (cents, remainder cent to card 1)
- Two sequential PayGate charges and their outcomes (approved, declined, error, timeout)
- Automatic refund of charge 1 when charge 2 is declined, within 60 seconds
- Order, payment, and ledger state after every outcome
- Regression of single-card checkout
- Customer-facing messages, receipts, and emails for split orders

**Out of scope**
- Three or more cards
- Non-card payment methods combined with a card (wallets, gift cards, store credit)
- Partial refunds or returns of split-paid orders after fulfilment (assumed existing refund flow; see assumption A7)
- PayGate internals and PayGate's own reconciliation reports

## 2. Assumptions

Where the brief is silent, the plan proceeds on these assumptions. Each one should be confirmed by product or dev in the first two days; a wrong assumption changes the tests marked with its ID.

| ID | Assumption |
|----|-----------|
| A1 | "Cannot be split evenly" refers to a percentage or 50/50 shortcut in the UI. When the customer types an explicit amount for card 1, card 2 gets exactly the remainder. |
| A2 | Card 1 amount must be at least 1 cent and at most order total minus 1 cent; 0 or full total on one card is rejected with a validation message. |
| A3 | Charges run sequentially: card 1 first, then card 2. Card 2 is not attempted if card 1 is declined. |
| A4 | The 60-second refund SLA is measured from the moment the card 2 decline is received from PayGate to the moment the refund request is accepted by PayGate. |
| A5 | If the automatic refund itself fails, the system retries and raises an alert or support ticket; the order is not marked paid. |
| A6 | Both cards may be the same card number; the brief does not forbid it. |
| A7 | Post-fulfilment refunds of split orders use the existing refund flow and refund card 2 first, then card 1 (reverse order). Flagged as a product question; tested lightly only. |
| A8 | Single currency, no multi-currency orders. |
| A9 | Developers can provide a PayGate stub or mock for use on non-sandbox days, driven by test card numbers that force approve, decline, timeout, and error. |
| A10 | A performance or staging environment with production-like data exists for regression. |
| A11 | Today (Saturday 2026-10-24) is day 0. Working days are Mon 2026-10-26 to Fri 2026-11-06. Sandbox days are Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. |

## 3. Risk assessment

Risks are ranked by likelihood x impact. Test effort follows this order.

| # | Risk | Likelihood | Impact | Priority | Why |
|---|------|-----------|--------|----------|-----|
| R1 | Card 2 declines and card 1 is not refunded, refunded late, or refunded twice | Medium | Critical | P1 | Customer is charged for nothing; chargebacks, regulatory exposure, support load. Timing and retry logic are the hardest part to build. |
| R2 | Split arithmetic wrong: sum differs from order total, remainder cent on wrong card, rounding in floats | Medium | High | P1 | Ledger mismatch on every affected order; silent and cumulative. |
| R3 | Single-card checkout regression | Low-Medium | Critical | P1 | 4,000 orders/day; shared checkout code and payment service are touched. |
| R4 | Partial failure states: timeout or 5xx from PayGate on either charge, duplicate submission, browser back button, double click | Medium | High | P1 | Leaves order in ambiguous state; may double charge or charge without order. |
| R5 | Refund succeeds but order, inventory, or email state still shows "paid" | Medium | High | P2 | Goods shipped for refunded money, or customer told payment failed when card 1 is still held. |
| R6 | Limited PayGate sandbox access (4 days) means real-gateway behaviour is under-tested | High | High | P2 | Process risk; mitigated by stub plus concentrated sandbox days. |
| R7 | Input validation gaps: negative, zero, over-total, non-numeric, more than two decimals, currency symbols | High | Medium | P2 | Cheap to test, common source of defects. |
| R8 | Security and compliance: card data for two cards in logs, PCI scope, authorization reuse | Low | High | P2 | Two card entries doubles surface area. |
| R9 | Idempotency: retry of charge 2 after network blip double-charges | Medium | High | P2 | Depends on idempotency keys per charge. |
| R10 | Reporting and reconciliation: finance exports, refunds report, dashboards do not understand two payments per order | Medium | Medium | P3 | Found late by finance; not customer-facing. |
| R11 | Accessibility and mobile layout of the two-card form | Medium | Low | P3 | Customer experience; rarely blocks release. |
| R12 | Performance: split path doubles gateway calls per order; latency and PayGate rate limits | Low | Medium | P3 | Low volume expected at launch (assumed under 5% of orders). |

## 4. Test approach

**Risk-based, layered.** Developers own unit tests for arithmetic and state machine; QA owns integration, end-to-end, regression, and exploratory testing. Everything that can be proven without PayGate is proven before the sandbox days so that sandbox time is spent only on real-gateway behaviour.

### 4.1 Layers

| Layer | Owner | What it covers | PayGate dependency |
|-------|-------|----------------|--------------------|
| Unit | Devs | Split calculation (cents, remainder), validation rules, state transitions | None |
| Integration with stub (A9) | QA + devs | Full checkout flow, decline paths, refund trigger and timing, timeouts, retries, idempotency | Stub |
| Integration with sandbox | QA | Same scenarios against real PayGate; refund SLA; real decline codes; real error payloads | Sandbox (Tue/Thu) |
| End-to-end UI | QA | Customer journey in browser and mobile viewport, receipts, emails | Stub, then sandbox |
| Regression | QA (automated suite) + devs | Existing single-card checkout, existing refunds, order management | Stub, then sandbox |
| Exploratory | QA | Edge cases, concurrency, back button, session expiry | Stub |
| Non-functional | QA + devs | Log scrubbing, latency of split path, accessibility quick pass | Stub |

### 4.2 Test data

- Order totals: 1 cent, 2 cents, 3 cents (odd), 100.00, 99.99, 0.01 remainder cases, 1,000,000.00 (largest allowed), max total minus 1 cent.
- Split cases: 50/50 on odd total, 1 cent on card 1, 1 cent on card 2, explicit amount with 3 decimals, percentage shortcut if present (A1).
- Cards: PayGate test cards for approve, decline (insufficient funds, do-not-honour, lost/stolen), timeout, gateway error, 3-D Secure challenge if supported, expired card, same card twice (A6).
- Stub must emulate the same test card numbers with the same outcomes so cases run identically on both.

## 5. Test cases by risk

Priority P1 cases must pass before release. P2 cases must pass or have an accepted known issue. P3 cases are run if time permits.

### R2 / R7: Split calculation and validation (P1, stub, day 1-3)

| ID | Case | Expected |
|----|------|----------|
| SC-01 | Total 100.01, choose 50/50 | Card 1 = 50.01, card 2 = 50.00 |
| SC-02 | Total 0.03, choose 50/50 | Card 1 = 0.02, card 2 = 0.01 |
| SC-03 | Total 100.00, card 1 explicit 33.33 | Card 2 = 66.67; sum equals total |
| SC-04 | Total 100.00, card 1 = 99.99 | Card 2 = 0.01, both charged |
| SC-05 | Card 1 = 0.00 | Rejected (A2) |
| SC-06 | Card 1 = total | Rejected (A2) |
| SC-07 | Card 1 > total | Rejected |
| SC-08 | Card 1 negative, letters, "1e2", "10,50", "$10", 3 decimals | Rejected or normalised per spec; no server 500 |
| SC-09 | Amounts sent as cents to PayGate | Request payload shows integer cents, no float |
| SC-10 | Order total changes after split entered (promo code applied, item removed) | Split recalculated or customer forced to re-enter; sum never stale |
| SC-11 | Property-style check: 1,000 random totals and splits (dev unit test) | Sum always equals total; remainder always on card 1 |

### R1 / R5: Decline of card 2 and automatic refund (P1, stub day 2-4, sandbox Tue 27 and Thu 29)

| ID | Case | Expected |
|----|------|----------|
| RF-01 | Card 1 approved, card 2 declined (insufficient funds) | Refund of card 1 requested within 60 s; order status "payment failed"; customer sees clear message naming card 2 |
| RF-02 | Same, measure time from decline to refund accepted (A4) | Under 60 s on sandbox, measured across 10 runs; report p50 and max |
| RF-03 | Card 1 approved, card 2 declined, refund request itself fails or times out | Retry occurs; alert raised; order not marked paid (A5) |
| RF-04 | Refund issued, then PayGate retries the decline webhook or callback | Refund not issued twice (idempotent) |
| RF-05 | Card 1 declined | Card 2 never attempted; no refund needed; no PayGate call for card 2 (A3) |
| RF-06 | Card 1 approved, card 2 timeout (no response) | System does not assume approved; refund of card 1 or defined retry; order not paid |
| RF-07 | Card 1 approved, card 2 approved | Order paid; two payment records; receipt shows both amounts and last 4 digits of each card |
| RF-08 | After RF-01, inventory, confirmation email, fulfilment queue | No stock reserved, no "order confirmed" email, nothing in fulfilment |
| RF-09 | After RF-01, customer retries with a different card 2 | New attempt creates new charges; card 1 is charged again (fresh), not reused from refunded charge |
| RF-10 | Refund exceeds 60 s (simulate slow PayGate on stub) | Alert or monitoring event fires; order visible in an ops view |
| RF-11 | Ledger after RF-01 | Charge, refund, net zero recorded against card 1; nothing against card 2 |

### R4 / R9: Partial failure and idempotency (P1, stub day 3-5, sandbox Thu 29)

| ID | Case | Expected |
|----|------|----------|
| PF-01 | Double-click "Pay" | One order, two charges total, not four |
| PF-02 | Browser back after card 1 charged, resubmit | No second charge on card 1 |
| PF-03 | Network drop between charge 1 and charge 2; customer refreshes | System recovers consistently: either completes card 2 or refunds card 1; never leaves card 1 charged with order unpaid for longer than SLA |
| PF-04 | Session expires between card 1 and card 2 | Card 1 refunded or held per spec; customer told clearly |
| PF-05 | PayGate returns 5xx on charge 1 | No order, no charge, retriable error to customer |
| PF-06 | PayGate returns 5xx on charge 2 | Treated as decline path (RF-01) or safe retry with same idempotency key; never double charge |
| PF-07 | Same order submitted from two tabs | Second submission rejected or deduplicated |
| PF-08 | Inspect idempotency keys in requests | Unique per charge, stable across retries of the same charge |

### R3: Single-card regression (P1, stub day 1 and day 8, sandbox Tue 3 Nov and Thu 5 Nov)

- Run full existing automated checkout regression suite on every build. Assumption: suite exists; if not, see section 9.
- Manual smoke of single-card happy path, decline path, 3-D Secure, saved card, guest checkout, and refund from order management.
- Verify split payment is behind a feature flag (assumed; if not, request one). Test with flag off: UI identical to 5.2, no split code reached, request payloads unchanged.
- Compare PayGate request payloads for a single-card order on 5.2 and 5.3 builds; they must be byte-equivalent apart from timestamps and ids.
- Canary: on release day, enable flag for internal users first, watch error rate and payment success rate for single-card for 2 hours before wider rollout.

### R8: Security and compliance (P2, day 5-6)

- Grep application logs, error trackers, and analytics events after running RF and PF cases: no PAN, CVV, or full expiry for either card.
- Card 2 fields are tokenised the same way as card 1; no raw card data hits application servers (confirm with dev; check network tab).
- Authorization check: user A cannot complete or view split details of user B's order via id manipulation.
- Rate limiting applies to split attempts as it does to single-card.

### R10: Reporting and reconciliation (P2, day 6-7)

- Finance export for a day containing split orders, refunded split orders, and single-card orders: each payment is a line, totals reconcile to PayGate settlement.
- Order management screen shows two payments per split order with individual status.
- Refund from order management on a fully paid split order (A7): refunds both charges, correct amounts, reverse order.

### R11 / R12: Accessibility, mobile, performance (P3, day 7-8)

- Keyboard-only completion of split form; labels and errors announced; mobile viewport at 360 px.
- Split checkout latency measured on sandbox: p95 of split path versus single-card; flag if more than 2x.
- Confirm PayGate rate limit headroom with devs for an assumed worst case of 10% of daily orders using split (800 orders, 1,600 charges).

## 6. Environments and PayGate access

| Need | Plan |
|------|------|
| Non-sandbox days | PayGate stub (A9), built by devs by end of day 2. Configurable per test card: approve, decline with code, delay N seconds, 5xx, no response. |
| Sandbox days | Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. Tester works full days on these four days and takes the half-time balance on other days. |
| Staging | Feature deployed on staging with flag; stub and sandbox switchable by config without redeploy. |
| Monitoring | Access to logs, refund alert channel, and a query for "charged card 1, order unpaid, older than 60 s". |

**Sandbox day agenda**

| Day | Focus |
|-----|-------|
| Tue 27 Oct | RF-01, RF-02 (first timing run), RF-05, RF-07, real decline codes, 3-D Secure behaviour. Capture real payloads to improve the stub. |
| Thu 29 Oct | PF-03, PF-06, PF-08 on real gateway; RF-02 repeated 10 runs; RF-03 if sandbox supports refund failure injection. |
| Tue 3 Nov | Full single-card regression on sandbox; fixes retest; reconciliation export against sandbox settlement. |
| Thu 5 Nov | Final release candidate run: all P1 cases, release smoke, timing re-measure. Reserved for retest only, no new exploration. |

If the sandbox is down on a scheduled day, the fallback is to shift that day's agenda to the next sandbox day and ask for a one-day release slip rather than ship untested gateway behaviour.

## 7. Schedule (10 working days, tester at 50%, about 5 tester-days)

| Day | Date | Tester activity | Dev activity |
|-----|------|-----------------|--------------|
| 1 | Mon 26 Oct | Review spec, confirm assumptions A1-A11, write test data, run baseline single-card regression on 5.2 | Build; deliver stub spec |
| 2 | Tue 27 Oct | Sandbox day 1 (full day) | Build; stub ready end of day |
| 3 | Wed 28 Oct | SC-01 to SC-11 on stub; RF cases on stub | Build; unit tests for split and state machine |
| 4 | Thu 29 Oct | Sandbox day 2 (full day) | Fixes |
| 5 | Fri 30 Oct | PF cases on stub; security log check | Fixes; feature complete |
| 6 | Mon 2 Nov | Reporting cases; exploratory; defect retest | Fixes |
| 7 | Tue 3 Nov | Sandbox day 3 (full day), regression | Fixes |
| 8 | Wed 4 Nov | Accessibility and mobile; retest; test report draft | Code freeze end of day |
| 9 | Thu 5 Nov | Sandbox day 4 (full day), release candidate run | Release prep, rollback rehearsal |
| 10 | Fri 6 Nov | Go/no-go, canary monitoring | Release with flag off, then canary |

Half-time budget is concentrated into the four sandbox days plus short slots elsewhere. Developers run unit tests and the automated regression suite on every build so the tester's time goes to risk areas, not to repetition.

## 8. Roles

| Role | Responsibility |
|------|----------------|
| Tester | This plan, P1 and P2 execution, sandbox days, defect triage, test report, go/no-go recommendation |
| Developer 1 | Split calculation and validation unit tests; stub build and maintenance; idempotency |
| Developer 2 | Refund state machine unit tests; monitoring query and alert for refund SLA; feature flag |
| Product (assumed available) | Confirm A1-A8 by end of day 2; accept known issues |

## 9. Entry and exit criteria

**Entry (before day 3)**
- Feature on staging behind a flag.
- Stub available with all outcome modes.
- Unit tests for split arithmetic pass, including the random-total check (SC-11).
- Assumptions A1-A8 confirmed or corrected.

**Exit (go for release)**
- All P1 cases pass on stub and on sandbox.
- RF-02 timing: max under 60 s across at least 10 sandbox runs.
- Zero open defects of severity critical or high in split or single-card checkout.
- Single-card regression suite green on the release candidate build on sandbox.
- No card data found in logs.
- Rollback rehearsed: flag off restores 5.2 behaviour without a deploy.
- P2 cases pass or each failure has a product-accepted known issue with a ticket.

**No-go triggers**
- Any case where card 1 remains charged with no refund and no alert.
- Any single-card regression failure.
- Fewer than two sandbox days actually usable.

## 10. Defect severity

| Severity | Definition | Example |
|----------|-----------|---------|
| Critical | Money lost or taken without an order; single-card broken | Card 1 not refunded after card 2 decline |
| High | Wrong amount, wrong state, duplicate charge recoverable by ops | Remainder cent on card 2; order marked paid after refund |
| Medium | Customer-facing confusion with no financial impact | Error message blames wrong card |
| Low | Cosmetic | Alignment on mobile |

## 11. Release and rollback

- Ship with the feature flag off. Enable for internal users on release day, then 5% of customers for 48 hours, then 100%.
- Monitor during rollout: split attempt count, card 2 decline rate, refund latency p95 and max, orders in "card 1 charged, unpaid" state older than 60 s, single-card success rate compared with the previous week.
- Rollback is flag off. Any in-flight split orders at flag-off time must still complete or refund; this is covered by PF-03 with the flag toggled mid-flow (added to day 8 exploratory).

## 12. Known gaps and residual risk

- Only four sandbox days. Real PayGate behaviour under network failure and refund failure (RF-03, PF-06) may be untestable on sandbox if it offers no failure injection; those paths will be proven on the stub only. Residual risk accepted and covered by the production refund-SLA alert.
- Half-time tester means P3 cases may be dropped. Accessibility and performance are the first to go.
- Load testing of the split path is not planned; volume at launch is assumed low and the canary rollout caps exposure.
- Post-fulfilment refunds of split orders (A7) are tested only lightly. If product confirms a different rule, add a day of testing or defer the refund behaviour to 5.3.1 with the flag limiting exposure.
