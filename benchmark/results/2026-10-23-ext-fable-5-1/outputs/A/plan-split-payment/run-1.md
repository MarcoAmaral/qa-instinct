# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** paying one order with two cards; split amount entry and validation; two PayGate charges; automatic refund of the first charge when the second is declined; regression of existing single-card checkout.

**Out of scope:** more than two cards, split across non-card methods, PayGate's own internals, load testing beyond a smoke check, accessibility of the new screens beyond keyboard operation.

**Assumptions** (stated where the brief is silent; each is an open item for the kickoff on day 1):

| # | Assumption |
|---|---|
| A1 | Single currency with two decimals. All arithmetic in integer cents; no floating point anywhere in the split path. |
| A2 | The remainder-cent rule applies when the UI offers an "equal split" or percentage shortcut. A customer who types a whole-cent amount never produces a remainder. |
| A3 | Each part must be at least 1 cent and strictly less than the order total, so both cards are always charged something. PayGate's own minimum charge, if any, is higher and returned as a decline. |
| A4 | Charges are sequential: card 1 first, then card 2. If card 1 is declined, card 2 is never attempted. |
| A5 | The refund of card 1 is a PayGate refund against the original charge, triggered by a background job that retries on failure. The 60-second limit is measured from receipt of the card-2 decline to PayGate accepting the refund. |
| A6 | The feature ships behind a feature flag that can be switched off without a deploy. |
| A7 | An automated regression suite for single-card checkout exists and runs in CI. If it does not, building a minimal one is the first task for the developers. |
| A8 | Developers can build a local PayGate stub, driven by recorded sandbox responses, in the first two days. |
| A9 | The same card used for both halves is allowed and treated as two independent charges. |
| A10 | Release date is Friday 6 November 2026. Sandbox days are 27 Oct, 29 Oct, 3 Nov and 5 Nov. |

## 2. Risk register

Priority drives test depth and ordering. P1 items block release if any test fails.

| ID | Risk | Likelihood | Impact | Priority |
|---|---|---|---|---|
| R1 | Single-card checkout regresses (shared checkout code, gateway client, order model). Affects ~4,000 orders/day. | Medium | Critical | P1 |
| R2 | Customer is charged on card 1 and the refund never happens, happens late, or happens twice. Direct money loss and chargebacks. | Medium | Critical | P1 |
| R3 | Split arithmetic wrong: parts do not sum to total, remainder cent goes to the wrong card, rounding in a float path, negative or zero part accepted. | Medium | High | P1 |
| R4 | Gateway timeout or unknown outcome on either charge leaves the order in an inconsistent state (charged but not placed, placed but not charged, double charge on retry). | Medium | Critical | P1 |
| R5 | Client-side amount tampering: split amounts trusted from the browser, letting a customer pay less than the order total. | Low | Critical | P1 |
| R6 | Duplicate submission (double click, retry, back button) produces three or four charges. | Medium | High | P2 |
| R7 | Order records, receipts, emails, and finance reconciliation do not show two transactions and a refund correctly. | High | Medium | P2 |
| R8 | Sandbox unavailable or flaky on the four available days, leaving the gateway integration untested against the real contract. | High | High | Schedule risk, see §5 |
| R9 | Refund succeeds but the customer sees an error and places the order again. | Medium | Medium | P2 |
| R10 | Performance: two sequential gateway calls double checkout latency past timeouts. | Low | Medium | P3 |
| R11 | Feature flag off path broken, so rollback is not possible. | Low | High | P2 |

## 3. Test design by risk

### R1 Single-card regression (P1)
- Run the full existing automated checkout suite on every build (A7).
- Manual exploratory pass of single-card checkout each sandbox day against the real gateway: successful charge, decline, 3-D Secure if used, refund from admin.
- Diff review by the tester of every change touching shared checkout code and the gateway client.
- Release-day check: flag off, run single-card suite; flag on, run single-card suite again.

### R2 Automatic refund (P1)
- Card 2 declined: refund of card 1 requested; order not placed; customer told clearly which card was declined and that card 1 will be refunded.
- Measure decline-to-refund latency in the stub (deterministic) and in the sandbox (real), 10 runs each. Pass: all under 60 s, report the max.
- Refund call fails once, twice, then succeeds: exactly one refund lands.
- Refund call fails permanently: alert raised, order flagged for manual action, no silent loss.
- Refund job is restarted mid-run: no duplicate refund (idempotency key verified in logs or stub).
- Card 2 declined with every decline reason the sandbox exposes (insufficient funds, stolen, expired, do-not-honour, fraud hold).

### R3 Split arithmetic (P1)
Unit tests, written or reviewed by the tester, with a boundary table:

| Total (cents) | Input | Expected card 1 | Expected card 2 |
|---|---|---|---|
| 1001 | equal split | 501 | 500 |
| 1000 | equal split | 500 | 500 |
| 1 | equal split | 1 | 0 → rejected (A3) |
| 2 | equal split | 1 | 1 |
| 1000 | card 1 = 1 | 1 | 999 |
| 1000 | card 1 = 999 | 999 | 1 |
| 1000 | card 1 = 1000 | rejected | |
| 1000 | card 1 = 0 | rejected | |
| 1000 | card 1 = -1 | rejected | |
| 1000 | card 1 = 10.005 | rejected or rounded per spec, never silently truncated | |
| 99999999 | equal split | 50000000 | 49999999 |

- Property test: for random totals and splits, card1 + card2 == total and both parts > 0.
- Percentage input (if A2 holds): 33% of 1000 → 330 / 670; remainder cent rule applied.
- Order total changes after split entered (coupon applied, item removed): split is recalculated or reset, never stale.

### R4 Unknown gateway outcome (P1)
Stub-driven, then confirmed in sandbox where possible:
- Timeout on card 1: no card 2 attempt; order not placed; customer sees retry; a retry does not double-charge card 1 (idempotency key).
- Timeout on card 2 where PayGate actually charged: reconciliation detects it; card 1 is not refunded if card 2 later confirms; defined behaviour documented.
- Gateway returns 5xx on refund: retried, see R2.
- Application crash between card 1 success and card 2 attempt: recovery job refunds card 1 or completes card 2, never leaves a dangling charge.

### R5 Amount tampering (P1)
- Replay the checkout request with modified amounts (card1 + card2 < total, negative card 2, card 2 omitted). Server recomputes from the order and rejects.
- Modify order total in the client after split is shown.
- Confirm raw card numbers never appear in logs, order records, or error messages for either card.

### R6 Duplicate submission (P2)
- Double-click pay button; two browser tabs; browser back then pay again; network retry of the POST. Expect exactly two charges total.

### R7 Records and reconciliation (P2)
- Order detail, customer receipt, confirmation email, admin view, and finance export each show two charges with the correct amounts and last four digits.
- After a card-2 decline, the refund appears against the correct charge and the order is not counted as revenue.
- Partial refund of a split order from admin: confirm which card is refunded and that the UI makes this explicit. If this is undefined, record it as a gap, not a test failure.

### R9 Customer messaging (P2)
- Decline message names the declined card only, does not expose decline reason beyond what single-card checkout does, and states that the first card will be refunded with an expected timeframe.

### R10 Performance smoke (P3)
- Compare p95 checkout time single-card vs split against the stub with realistic gateway latency injected. Flag if split exceeds the existing front-end timeout.

### R11 Feature flag (P2)
- Flag off: no split UI, split API endpoint rejects or is absent, single-card unaffected. Flag toggled while a split checkout is in flight: in-flight completes or fails cleanly.

## 4. Test environments and tooling

| Environment | Use | Availability |
|---|---|---|
| Local PayGate stub (A8) | All R2, R3, R4, R6 failure and timing paths. Deterministic, repeatable, every day. | Days 2 onward |
| PayGate sandbox | Contract confirmation: real decline codes, real refund latency, real idempotency behaviour, 3-D Secure. | Tue and Thu only |
| CI | Unit, property and single-card regression suites on every commit. | Continuous |
| Staging with flag | Exploratory, records and reconciliation (R7), flag tests (R11). | Days 5 onward |

The stub is the primary environment. The sandbox is used only to confirm what the stub assumes. Every sandbox session starts by recording responses to refresh the stub.

## 5. Schedule

Tester capacity is 5 person-days across 10 working days. Developer time is used for stub, unit tests and fixing.

| Day | Date | Tester (half day) | Developers |
|---|---|---|---|
| 1 | Mon 26 Oct | Kickoff: confirm assumptions A1–A10, agree flag and refund design, write boundary table (R3). | Build PayGate stub from existing recordings; start feature. |
| 2 | Tue 27 Oct | **Sandbox.** Record real responses: each decline code, refund latency, timeout, idempotent retry. Baseline single-card exploratory. | Feed recordings into stub. |
| 3 | Wed 28 Oct | Review unit and property tests for R3; review diff of shared checkout code (R1). | Feature build continues. |
| 4 | Thu 29 Oct | **Sandbox.** First end-to-end split happy path if build allows; otherwise second recording session for refund edge cases. | First testable build by end of day. |
| 5 | Fri 30 Oct | R3 and R5 against build on stub. Run single-card regression suite. | Fix. |
| 6 | Mon 2 Nov | R2 and R4 failure paths on stub; latency measurement; R6 duplicates. | Fix. |
| 7 | Tue 3 Nov | **Sandbox.** Full R2 against real gateway: 10 decline-to-refund timings, each decline code, idempotent retry. R1 exploratory. | Fix. |
| 8 | Wed 4 Nov | Retest fixes; R7 records and reconciliation; R11 flag on staging. | Fix; freeze by end of day. |
| 9 | Thu 5 Nov | **Sandbox.** Final verification on release candidate: split happy path, decline with refund, single-card regression. Sign-off report. | No feature changes; fixes only for P1. |
| 10 | Fri 6 Nov | Go/no-go, release with flag off, flag on for 5% of traffic, monitor. | Release and monitor. |

**Schedule risks and fallbacks:**
- If the first testable build slips past day 4, day 7 becomes the only full sandbox end-to-end session and day 9 the only retest. Any P1 defect found on day 9 means release with flag off and enable the following Tuesday after a sandbox retest.
- If the sandbox is down on a scheduled day, that session moves to the next sandbox day and the release decision relies on the stub plus a 1% canary with live monitoring of refund latency.
- If no automated single-card suite exists (A7 fails), developers spend day 1 and 2 on it before the feature. This is cheaper than the alternative.

## 6. Entry and exit criteria

**Entry to sandbox end-to-end (day 7):** stub-based R2, R3, R4 tests pass; no open P1 defects; single-card suite green.

**Exit for release:**
- All P1 risk tests pass on the release candidate, including at least one sandbox run of decline-to-refund with all measured latencies under 60 s.
- Single-card regression suite green with flag off and flag on.
- No open P1 defects; P2 defects either fixed or accepted in writing by the product owner with a workaround.
- Feature flag verified to disable the feature cleanly.
- Monitoring in place before release: alert on any refund older than 60 s not yet accepted, alert on orders with a successful card-1 charge and no card-2 outcome after 5 minutes, dashboard of split vs single-card decline rates.

## 7. Release safeguards

- Ship with the flag off. Enable for 5% of traffic on release day, 50% after 24 hours with no refund alerts, 100% after the next sandbox day's confirmation.
- Daily reconciliation report for the first week: every split order has exactly two settled charges, or one charge and one refund, and nothing else.
- Rollback is the flag, not a redeploy.

## 8. Defect priorities

| Priority | Definition | Release effect |
|---|---|---|
| P1 | Money wrong, refund missing or duplicated, single-card broken, card data exposed | Blocks release |
| P2 | Wrong records or messaging, duplicate-submission gap, flag misbehaviour | Blocks unless accepted in writing |
| P3 | Cosmetic, performance within timeout, minor validation message | Does not block |

## 9. Deliverables

- Boundary table and property tests for R3, committed with the feature.
- Stub recordings from each sandbox session, committed so the stub stays current.
- Sandbox session log per day listing what was run, what passed, and measured refund latencies.
- Sign-off report on day 9 against the exit criteria, listing accepted P2 items and the assumptions from §1 that were confirmed or changed.
