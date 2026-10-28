# Test Plan: Split Payment (Release 5.3)

**Author:** QA (Marco)
**Date:** 24 October 2026
**Status:** Draft v1 for review by the two feature developers and the product owner

## 1. Purpose and scope

This plan covers verification of the split-payment feature, in which one order is paid with two cards via the PayGate gateway, and protection of the existing single-card checkout.

**In scope**

- Split amount entry and validation, including cent rounding rules.
- Two sequential PayGate charges and all outcome combinations (both succeed, first declines, second declines, timeouts, errors).
- Automatic refund of the first charge within 60 seconds when the second charge is declined.
- Order state, receipts, customer notifications, and back-office records for split orders.
- Regression of single-card checkout.
- Operational readiness: logging, alerting, reconciliation, and feature flag behaviour.

**Out of scope**

- PayGate's internal behaviour beyond its documented contract.
- Load testing beyond a smoke-level concurrency check (no load environment is assumed to exist for PayGate).
- Post-release returns and partial refunds across two cards, unless already implemented in 5.3 (see assumption A7).

## 2. Assumptions

Where the brief is silent, the following assumptions apply. Each should be confirmed by the developers or product owner in the first two days; any that prove false will change the plan.

| ID | Assumption |
|----|------------|
| A1 | "Today" is Saturday 24 October 2026. Ten working days run Monday 26 October to Friday 6 November 2026. Release is Friday 6 November. |
| A2 | PayGate sandbox days within the window are Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, and Thu 5 Nov. Four sandbox days in total. |
| A3 | The tester has roughly five person-days in total (half of ten working days). Developers contribute unit tests, a PayGate stub, and pair on exploratory sessions. |
| A4 | A customer may enter a fixed amount for card one. A "split evenly" shortcut also exists, which is where the "remainder cent goes on the first card" rule applies (for example, 10.01 splits as 5.01 and 5.00). If no shortcut exists, the rule applies only to any percentage-based entry and the related tests reduce accordingly. |
| A5 | Charges are executed sequentially: card one first, then card two. If card one is declined, card two is never attempted and no refund is needed. |
| A6 | The refund is a PayGate refund (or void, if the charge is only authorised) issued by the backend without customer involvement. The 60-second target is measured from the second decline response to PayGate acknowledging the refund request. |
| A7 | Returns and partial refunds against a split order after fulfilment are not part of 5.3. If they are, Section 6 gains a risk R13 at High. |
| A8 | The feature ships behind a feature flag that can be turned off without a deploy. |
| A9 | A single currency is used, with two decimal places, and PayGate enforces a minimum charge amount (assumed 0.50). The actual minimum must be confirmed. |
| A10 | A PayGate stub (mock server) with scripted responses can be built or extended by the developers by Tuesday 27 October. Without it, non-sandbox days lose most integration coverage. |
| A11 | One test environment exists that can point at either the stub or the sandbox via configuration. |
| A12 | Both cards are submitted and authorised within one checkout session; the customer does not return later to add the second card. |

## 3. Risk analysis

Likelihood and impact are rated Low, Medium, or High. Priority drives test depth and ordering.

| ID | Risk | Likelihood | Impact | Priority |
|----|------|-----------|--------|----------|
| R1 | Customer is charged on card one and not refunded when card two declines (money taken, no goods). | Medium | High | **P1** |
| R2 | Refund is issued but exceeds the 60-second target, or is issued more than once. | Medium | High | **P1** |
| R3 | Regression breaks single-card checkout (about 4,000 orders a day; a one-hour outage is roughly 170 lost orders). | Medium | High | **P1** |
| R4 | Rounding error produces charges that do not sum to the order total, or a charge of zero or negative cents. | Medium | High | **P1** |
| R5 | PayGate timeout or ambiguous response on either charge leaves the order in an unknown state (charged but not recorded, or recorded but not charged). | Medium | High | **P1** |
| R6 | Duplicate submission (double click, retry, network replay) results in three or four charges. | Medium | High | **P1** |
| R7 | Order shown as paid when only one charge succeeded, or shown as failed when both succeeded. | Medium | High | **P1** |
| R8 | Refund failure (PayGate error on the refund call) is silent, with no retry and no alert. | Medium | High | **P2** |
| R9 | Input validation gaps: amount greater than total, below gateway minimum, non-numeric, or same card used twice. | High | Medium | **P2** |
| R10 | Receipts, confirmation emails, and back-office views show one card or one amount only, causing support load and reconciliation errors. | High | Medium | **P2** |
| R11 | Card data or full PAN logged during the new two-charge flow (PCI exposure). | Low | High | **P2** |
| R12 | Feature flag off path is broken, so rollback is not possible. | Low | High | **P2** |
| R13 | Accessibility or usability defects in the split UI (screen reader, keyboard, mobile layout). | Medium | Low | **P3** |
| R14 | 3-D Secure or step-up authentication on the second card interrupts the flow after card one is already charged. | Medium | Medium | **P2** |

**Plan-level risks**

| ID | Risk to the plan | Mitigation |
|----|------------------|------------|
| PR1 | Only four sandbox days; a sandbox outage on any of them removes a quarter of real-gateway coverage. | Build the stub first and get 80 percent of coverage against it. Reserve sandbox days for contract confirmation, refund timing, and declined-card scenarios that need real gateway codes. |
| PR2 | The feature is not testable until late in the window. | Agree a vertical slice (happy path end to end, flag on) ready by Wednesday 28 October. Test incrementally. |
| PR3 | Tester capacity of five days is tight. | Developers own unit and stub-level tests for rounding, state machine, and idempotency. Tester owns risk-based integration, exploratory, and regression work. |
| PR4 | Sandbox behaviour differs from production (for example, refund latency). | Record sandbox refund latency and get PayGate's stated production refund SLA in writing. Add production monitoring for refund latency on day one. |

## 4. Test approach

### 4.1 Levels and ownership

| Level | Owner | Environment | Purpose |
|-------|-------|-------------|---------|
| Unit | Developers | Local | Rounding, split calculation, state transitions, idempotency key generation, refund scheduler. |
| Component / contract | Developers with tester review | Stub | Every PayGate response type for charge and refund, including timeouts, 5xx, malformed body. |
| Integration | Tester | Stub (Mon, Wed, Fri) and Sandbox (Tue, Thu) | End-to-end flows, order state, receipts, timing. |
| Regression | Tester plus existing automated suite | Stub and Sandbox | Single-card checkout unchanged, flag off path. |
| Exploratory | Tester, paired with a developer | Sandbox | Unscripted sessions targeting R5, R6, R7, R14. |
| Operational readiness | Tester with on-call engineer | Staging | Alerts fire, dashboards show split metrics, runbook exists. |

### 4.2 Stub versus sandbox

The PayGate stub is the primary tool. It must support, per request, scripted responses for: approved, declined (with at least three distinct decline codes), insufficient funds, card expired, timeout (no response within the client timeout), HTTP 500, HTTP 429, malformed JSON, and a configurable delay. It must also record every request so tests can assert on call count and idempotency keys.

Sandbox days are used only for things the stub cannot prove: real response formats, real refund latency, real 3DS flows, and real test-card decline behaviour.

### 4.3 Test data

- Order totals: 0.01, 0.50, 0.99, 1.00, 1.01, 10.00, 10.01, 999.99, 1,000.00, and the configured maximum order value.
- Card one amounts per total: 0, 0.01, exactly minimum, minimum minus 0.01, half, half rounded both ways, total minus 0.01, total, total plus 0.01.
- Sandbox test cards for: approved, declined, insufficient funds, expired, 3DS challenge required, and refund failure where PayGate provides one.
- Existing single-card regression orders, including discounts, gift cards, and tax-inclusive totals, if those exist in the catalogue.

## 5. Test design by risk

Each case has an ID, the risk it covers, and the environment where it must pass. "Both" means it must pass on the stub and be confirmed on the sandbox.

### 5.1 Split calculation and validation (R4, R9)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| SC-01 | Total 10.01, split evenly | Card one 5.01, card two 5.00; sum equals total | Stub |
| SC-02 | Total 0.01, split evenly | Card one 0.01, card two 0.00; rejected because card two is below minimum (see A9) | Stub |
| SC-03 | Total 999.99, split evenly | Card one 500.00, card two 499.99 | Stub |
| SC-04 | Card one amount equals total | Rejected, or treated as single-card with a clear message (confirm intended behaviour) | Stub |
| SC-05 | Card one amount is 0 | Rejected | Stub |
| SC-06 | Card one amount greater than total | Rejected, no charge attempted | Stub |
| SC-07 | Card one amount negative, non-numeric, or with three decimal places | Rejected client side and server side | Stub |
| SC-08 | Either amount below PayGate minimum | Rejected before any charge, message names the minimum | Both |
| SC-09 | Amount entered with locale separators (1,000.00 and 1.000,00) | Parsed correctly or rejected consistently | Stub |
| SC-10 | Server-side recalculation when client sends tampered amounts that do not sum to total | Rejected, logged | Stub |
| SC-11 | Same card number used for both cards | Allowed or rejected per product decision; behaviour matches spec | Sandbox |
| SC-12 | Order total changes between split entry and submit (for example, promotion expiry) | Split is recalculated or customer is asked to confirm; charges never exceed new total | Stub |

### 5.2 Charge sequencing and outcomes (R1, R5, R7, R14)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| CH-01 | Both charges approved | Order paid, two charge records, receipt shows both cards and amounts | Both |
| CH-02 | Card one declined | Card two not attempted, order unpaid, customer can retry, no refund issued | Both |
| CH-03 | Card one approved, card two declined | Refund of card one issued automatically, order unpaid, customer told clearly which card failed and that card one will be refunded | Both |
| CH-04 | Card one approved, card two times out | Backend queries PayGate for charge two status before deciding; if unknown after retry budget, charge one is refunded and order is unpaid; no double charge on card two | Stub then Sandbox if PayGate offers a status lookup |
| CH-05 | Card one times out | No charge two attempted; status lookup determines whether charge one happened; if it did, it is refunded or the flow continues per spec | Stub |
| CH-06 | PayGate returns HTTP 500 on charge two | Treated as decline-equivalent: refund card one, order unpaid, error logged with correlation ID | Stub |
| CH-07 | PayGate returns HTTP 429 on charge two | Retry with backoff within a bounded window, then refund card one if still failing | Stub |
| CH-08 | Malformed response on either charge | Safe failure, no order marked paid | Stub |
| CH-09 | 3DS challenge on card two, customer completes it | Both charges succeed | Sandbox |
| CH-10 | 3DS challenge on card two, customer abandons | Card one refunded within 60 seconds of abandonment or session timeout | Sandbox |
| CH-11 | Application crashes or is restarted between charge one and charge two | On recovery, orphaned charge one is detected and refunded; order not marked paid | Stub |
| CH-12 | Order status shown to customer and in admin after each of CH-01 to CH-11 | Status never says paid unless both charges succeeded | Both |

### 5.3 Automatic refund (R1, R2, R8)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| RF-01 | Measure time from charge two decline to PayGate refund acknowledgement, 20 runs | All under 60 seconds; record p50 and max | Sandbox |
| RF-02 | Refund amount equals charge one amount exactly, including the remainder cent | Exact match | Both |
| RF-03 | Refund call fails (stub returns 500) | Retried on a schedule; alert raised if not successful within 60 seconds; order flagged for manual action | Stub |
| RF-04 | Refund call times out but PayGate did process it | Status check prevents a second refund | Stub |
| RF-05 | Two refund workers pick up the same failed order | Only one refund issued (lock or idempotency key) | Stub |
| RF-06 | Refund is a void when charge one is only authorised, and a refund when it is captured | Correct operation chosen; customer sees no pending charge longer than necessary | Sandbox |
| RF-07 | Refund record visible in admin with reason "second card declined" | Present and correct | Both |

### 5.4 Idempotency and concurrency (R6)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| ID-01 | Double click submit | Exactly two charges total | Both |
| ID-02 | Replay the same submit request with the same idempotency key | Second request returns the original result, no new charges | Stub |
| ID-03 | Replay with a new key for the same order already paid | Rejected, no new charges | Stub |
| ID-04 | Two browser tabs submit the same cart | One pair of charges, the other attempt rejected | Stub |
| ID-05 | Twenty split orders submitted concurrently | No cross-order contamination; each order has its own two charges with the right amounts | Stub |

### 5.5 Regression of single-card checkout (R3, R12)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| RG-01 | Full existing automated checkout suite with flag off | 100 percent pass | Both |
| RG-02 | Full existing automated checkout suite with flag on, single card chosen | 100 percent pass | Both |
| RG-03 | Single-card timeout and decline paths unchanged | Behaviour and messages identical to 5.2 | Stub |
| RG-04 | Single-card receipt, email, admin view, and reporting export unchanged | Byte-level or field-level comparison with 5.2 | Stub |
| RG-05 | Checkout latency for single card compared with 5.2 baseline | No increase beyond 10 percent at p95 | Stub |
| RG-06 | Flag turned off mid-session for a customer who has already chosen split | Graceful fallback to single card, no charges lost | Stub |
| RG-07 | Database migration, if any, applied and rolled back | Single-card orders readable before and after | Staging |

### 5.6 Records, receipts, and reconciliation (R10, R11)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| RC-01 | Receipt and confirmation email for a split order | Both cards (masked), both amounts, total | Both |
| RC-02 | Admin order view | Two charge lines, refund line where applicable, PayGate reference IDs | Both |
| RC-03 | Finance export or settlement report | Split orders reconcile: sum of charges equals order total, refunds netted | Both |
| RC-04 | Application and gateway logs for a full split flow | No full PAN, CVV, or expiry in any log line; correlation ID links both charges and any refund | Both |
| RC-05 | Customer-facing error messages | Never expose raw PayGate codes or internal IDs | Both |

### 5.7 UI and accessibility (R13)

| ID | Case | Expected | Env |
|----|------|----------|-----|
| UI-01 | Keyboard-only completion of split checkout | Possible, focus order sensible | Stub |
| UI-02 | Screen reader announces the computed card two amount when card one changes | Announced | Stub |
| UI-03 | Mobile viewport layout | Both card forms usable, no clipped fields | Stub |
| UI-04 | Inline validation messages for SC-04 to SC-08 | Clear, next to the field | Stub |

### 5.8 Operational readiness

| ID | Case | Expected | Env |
|----|------|----------|-----|
| OP-01 | Alert fires when a refund is not acknowledged within 60 seconds | Alert received by on-call | Staging |
| OP-02 | Alert fires when an orphaned charge one exists older than two minutes | Alert received | Staging |
| OP-03 | Dashboard shows split order count, split decline rate, refund latency | Present | Staging |
| OP-04 | Runbook for manual refund of a stuck split order | Exists, walked through once by the tester | Staging |
| OP-05 | Feature flag can be toggled without deploy | Verified | Staging |

## 6. Schedule

Working days Mon 26 October to Fri 6 November 2026. Tester effort is half days unless marked. Sandbox days are in bold.

| Day | Date | Tester | Developers |
|-----|------|--------|------------|
| 1 | Mon 26 Oct | Review design, confirm assumptions A1 to A12, finalise this plan, write stub response scripts. | Build PayGate stub (A10), unit tests for split calculation. |
| 2 | **Tue 27 Oct** | Sandbox: confirm real response formats for approve, decline, timeout, refund; capture samples for the stub. Confirm PayGate minimum amount and refund SLA. | Finish stub; start charge sequencing. |
| 3 | Wed 28 Oct | Stub: SC-01 to SC-12 against vertical slice. | Vertical slice ready (happy path, flag on). |
| 4 | **Thu 29 Oct** | Sandbox: CH-01, CH-02, CH-03, RF-02, first RF-01 timing sample. | Refund scheduler and idempotency. |
| 5 | Fri 30 Oct | Stub: CH-04 to CH-08, CH-11, RF-03 to RF-05, ID-01 to ID-05. Log defects. | Fix defects; implement alerts (OP-01, OP-02). |
| 6 | Mon 2 Nov | Stub: RG-01 to RG-07, RC-04, UI-01 to UI-04. | Fix defects. |
| 7 | **Tue 3 Nov** | Sandbox: RF-01 full 20-run timing, RF-06, CH-09, CH-10, SC-11, RC-01 to RC-03. Exploratory session with developer (one hour). | Fix defects. |
| 8 | Wed 4 Nov | Retest fixed defects on stub. OP-01 to OP-05 on staging. Decide go or no-go candidate. | Code freeze end of day. |
| 9 | **Thu 5 Nov** | Sandbox: full regression RG-01, RG-02, and retest of any P1 fixes. Final RF-01 confirmation. Sign-off report. | Release candidate build. |
| 10 | Fri 6 Nov | Release support, production smoke with flag off, then flag on for a small percentage if staged rollout exists. Monitor OP-03 dashboard. | Release. |

Contingency: if the vertical slice slips past Wednesday 28 October, Thursday 29 October sandbox time moves to contract confirmation only, and Tuesday 3 November becomes the first full functional sandbox day. In that case, the release should slip or ship flag-off.

## 7. Entry and exit criteria

**Entry (per level)**

- Unit: code merged to the feature branch with unit tests for SC-01 to SC-03 and the state machine passing.
- Integration on stub: stub supports all response types in Section 4.2 and records requests.
- Integration on sandbox: feature deployed to the environment with sandbox credentials by 09:00 on the sandbox day.

**Exit (release go)**

- All P1 cases pass on the stub, and CH-01 to CH-03, RF-01, RF-02, RG-01, and RG-02 pass on the sandbox.
- RF-01: all 20 timing runs under 60 seconds.
- Zero open defects of severity Critical or High against R1 to R7.
- Existing single-card automated suite passes with the flag on and off.
- OP-01, OP-02, OP-05 verified on staging.
- Runbook for stuck split orders exists.

**Release with reduced scope**

If exit criteria are not met by Thursday 5 November, the release ships with the feature flag off. The feature is enabled in production only after the outstanding criteria are met on a later sandbox day.

## 8. Defect severity

| Severity | Definition | Example |
|----------|-----------|---------|
| Critical | Customer loses money or single-card checkout fails. | Refund not issued; single-card order cannot complete. |
| High | Wrong order state or wrong amounts, data not reconcilable. | Order marked paid with one charge; charges do not sum to total. |
| Medium | Feature works but with incorrect messaging, records, or missing alerts. | Receipt shows one card; alert missing. |
| Low | Cosmetic or minor usability. | Field alignment on mobile. |

Critical and High defects block release of the feature flag-on. Medium defects need an agreed workaround or a fix before flag-on. Low defects may ship.

## 9. Deliverables

- This plan, updated after assumption review on Monday 26 October.
- Stub response scripts and captured sandbox samples, checked into the test repository.
- Test execution log per day with case IDs, environment, result, and build number.
- Refund latency measurements from RF-01 (raw values and p50, p95, max).
- Defect reports with correlation IDs and PayGate references.
- Sign-off report on Thursday 5 November stating which exit criteria passed, which did not, and the recommended flag state for release.

## 10. Post-release monitoring (first five working days)

- Refund latency alert threshold at 45 seconds to give warning before the 60-second target is breached.
- Daily check of orphaned charge-one records and manual refund of any found.
- Daily reconciliation of split orders against PayGate settlement.
- Single-card conversion rate and checkout error rate compared against the week before release. A drop of more than 2 percent triggers investigation and consideration of flag-off.
