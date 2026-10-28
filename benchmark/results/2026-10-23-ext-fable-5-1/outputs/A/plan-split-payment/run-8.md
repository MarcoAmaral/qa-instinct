# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** two-card split at checkout, cent allocation, two PayGate charges, automatic refund of the first charge on second-charge decline, and non-regression of single-card checkout.

**Assumptions made where the brief is silent:**

- A1. Today is Sat 2026-10-24. Working days run Mon 26 Oct to Fri 6 Nov. Release is Fri 6 Nov. Sandbox days are Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov.
- A2. Testable builds land no earlier than Wed 28 Oct, so three sandbox days carry real integration testing. The first sandbox day is used for discovery only.
- A3. One currency per order. Amounts arrive as integer cents from the order service.
- A4. "Cannot be split evenly" refers to an "equal split" shortcut in the UI. Manual splits are always exact by construction.
- A5. PayGate exposes charge, refund, and status lookup, plus documented sandbox test cards for approval, decline, and timeout.
- A6. The feature ships behind a feature flag with percentage rollout.
- A7. An automated regression suite for single-card checkout already exists and is green on main.
- A8. 3-D Secure and stored-card wallets are out of scope for 5.3. If either is in scope, risk R8 moves to High and needs one extra sandbox day.
- A9. The tester's five person-days are split as: 1 day planning and data prep, 2.5 days execution, 1 day regression and release sign-off, 0.5 day buffer.

**Out of scope:** more than two cards, split across card and non-card methods, post-purchase partial refunds across two cards (see R9 for the follow-up), load testing of the gateway.

## 2. Risk register

Priority drives test depth. Likelihood and impact are rated Low, Medium, High.

| ID | Risk | Lik. | Impact | Priority | What goes wrong for the business |
|----|------|------|--------|----------|----------------------------------|
| R1 | Second charge declined, first charge not refunded, or refunded late or twice | M | H | **P1** | Customer charged for nothing, chargebacks, support load |
| R2 | Charge amounts do not sum to order total (rounding, remainder cent, overflow) | M | H | **P1** | Revenue leak or overcharge on every split order |
| R3 | Single-card checkout regresses | M | H | **P1** | 4,000 orders/day at risk; this outweighs the new feature |
| R4 | Unknown outcome between charges (timeout, crash, double submit) leaves order half-paid | M | H | **P1** | Stuck orders, duplicate charges, manual reconciliation |
| R5 | Refund path works in mocks but not against real PayGate (API shape, latency, decline codes) | H | M | **P2** | Discovered in production because sandbox time was short |
| R6 | Input validation gaps: zero, negative, over-total, same card twice, minimum amount per card | H | M | **P2** | Gateway errors surfaced to customer, abandoned checkouts |
| R7 | First charge declined, flow does not stop cleanly | L | M | **P2** | Second card charged for a partial order |
| R8 | Fraud and compliance: split used to stay under fraud thresholds; two PANs handled in one session | L | H | **P2** | Fraud losses, PCI finding |
| R9 | Downstream records wrong: receipts, order history, finance export show one transaction or wrong amounts | M | M | **P2** | Reconciliation breaks, support cannot refund later |
| R10 | Sandbox unavailable or flaky on a scheduled day | M | M | **P2** | Schedule slips with no recovery window |
| R11 | Accessibility and usability of the split UI | M | L | **P3** | Lost conversions, not money loss |
| R12 | Performance: two sequential gateway calls double checkout latency | L | L | **P3** | Slower checkout, acceptable for an opt-in feature |

## 3. Test approach by risk

The scarce resource is sandbox time. Everything deterministic runs against a local PayGate stub owned by the developers. Sandbox days are reserved for behaviour only PayGate can confirm.

### R1. Refund on second-card decline (P1)

- **Unit and stub level, devs:** refund triggered on every decline code, not only "insufficient funds". Refund idempotency key derived from the first charge ID so retries cannot double-refund. Refund amount equals first charge amount exactly.
- **Stub level, tester:** refund call fails once then succeeds; refund call times out; refund rejected permanently. Expected: retry with backoff inside the 60 s budget, then alert and queue for manual action. Order must never show "paid".
- **Sandbox, tester and one dev:** real decline test card on second charge. Measure wall-clock from decline to refund confirmed. Run 10 times, record each timing. Pass: all under 60 s, none duplicated. Also confirm whether PayGate treats an uncaptured charge as a void rather than a refund, and that the customer-facing state is the same either way.
- **Observability check:** a metric or log line exists for "refund triggered", "refund succeeded", "refund failed". This is the only way to know R1 is healthy in production.

### R2. Cent allocation (P1)

- **Unit, devs, table-driven:** totals 1, 2, 3, 99, 100, 101, 999999 cents and the largest order value in the last 90 days. For equal split: odd totals put the extra cent on card 1. For manual split: card 2 = total minus card 1, never recomputed from a percentage.
- **Property test, dev:** for any total and any valid card-1 amount, charge1 + charge2 == total, both ≥ minimum charge, no floats anywhere in the path.
- **Tester:** review the test table rather than re-run it. Spot-check through the UI with a 10.01 and a 0.03 order against the stub.

### R3. Single-card regression (P1)

- Full existing checkout regression suite on every build that touches payment code.
- Feature flag off: diff the PayGate request payload for a single-card order against a recorded payload from the current release. Must be byte-identical except timestamps and IDs.
- Feature flag on, customer chooses one card: same payload diff.
- One sandbox run of the single-card happy path on the release candidate on Thu 5 Nov.
- Rollout at 5% of traffic for 48 hours before 100%. Rollback is flag off, no deploy.

### R4. Partial-completion and concurrency (P1)

- **Stub level:** kill the process after charge 1 succeeds. Expected: on restart the recovery job finds the order in "first charge done" and either completes charge 2 or refunds charge 1. Not both. Not neither.
- Double-click submit and two tabs on the same order: exactly two charges in total, not four.
- Charge 2 times out with unknown outcome: system calls status lookup before deciding to refund charge 1. This is the case most likely to produce a double charge.
- Devs add a state machine diagram to the PR. Tester walks every transition against the test cases above.

### R5. Real-gateway contract (P2)

- First sandbox day (Tue 27 Oct): tester records real responses for approve, decline, timeout, refund success, refund of already-refunded charge. These recordings become the stub fixtures, so later stub tests reflect reality.
- Compare decline codes and error shapes with what the code branches on.

### R6. Validation (P2)

Stub level, tester, one pass through the UI and one through the API directly:

- card 1 amount: 0, equal to total, greater than total, negative, non-numeric, 1 cent, total minus 1 cent
- same card number entered twice
- card 1 amount below PayGate's minimum charge
- total changes after split is chosen (discount applied, item removed)

API-level cases matter because the UI will block the obvious ones.

### R7, R8, R9 (P2)

- R7: first card declined on stub and once on sandbox. Expected: no call to charge card 2, clear message, order stays open.
- R8: ask the fraud and compliance owner to review the design for one hour. Tester confirms second PAN is never logged and both tokens are cleared on failure. No new PCI scope beyond today.
- R9: after one successful and one refunded split order, check receipt email, order history page, admin order view, and finance export. Each shows two lines with correct amounts and the refund where applicable.

### R10, R11, R12 (P2 and P3)

- R10: every sandbox scenario has a stub twin written first. If a sandbox day is lost, the stub twins plus one extra 30-minute sandbox slot on the next available day cover it. If two days are lost, release slips and the plan says so on the day.
- R11: keyboard-only and screen-reader pass of the split form, 1 hour, stub only.
- R12: compare p95 checkout time single vs split on the stub. Flag if split exceeds 2× single. No fix required for 5.3.

## 4. Schedule

| Day | Date | Activity | Who |
|-----|------|----------|-----|
| D1 | Mon 26 Oct | Finalise this plan, build test data, confirm sandbox credentials and test cards | Tester |
| D2 | Tue 27 Oct | **Sandbox.** Record real responses, confirm refund and status APIs, time a manual refund | Tester, dev |
| D3 | Wed 28 Oct | Devs deliver stub and unit tests for R2, R6. Tester reviews test tables | Devs, tester |
| D4 | Thu 29 Oct | **Sandbox.** First end-to-end split: approve/approve, approve/decline with refund timing | Tester, dev |
| D5 | Fri 30 Oct | R4 and R6 on stub. Bug triage | Tester |
| D6 | Mon 2 Nov | R1 failure-mode cases on stub. R9 downstream checks | Tester |
| D7 | Tue 3 Nov | **Sandbox.** Refund timing × 10, R7, retest sandbox-only bugs | Tester, dev |
| D8 | Wed 4 Nov | Full single-card regression on release candidate. R11, R12 | Tester |
| D9 | Thu 5 Nov | **Sandbox.** Final RC smoke: one split success, one split refund, one single-card order | Tester |
| D10 | Fri 6 Nov | Release at 5% flag. Monitor refund metrics | All |

Code freeze for payment code is end of D7. Anything found on D8 or D9 is fixed only if it is P1.

## 5. Entry and exit criteria

**Entry to sandbox days:** build deployed to the sandbox-connected environment by 09:00, stub twin of each planned scenario already passing.

**Exit for release:**

- All P1 risk cases pass on stub and sandbox. Zero open P1 defects.
- Refund observed under 60 s in 10 of 10 sandbox runs. No duplicate refunds.
- Single-card regression suite green and payload diff clean.
- P2 cases pass or have an owner and a dated follow-up. P3 may be deferred.
- Refund metrics and alert exist in production dashboards before the flag turns on.

## 6. Deliverables

- Risk register (this document) updated daily with status per risk.
- Stub fixtures recorded from sandbox, checked into the repo.
- Refund timing log from sandbox runs.
- Release readiness note on D9 with a go/no-go recommendation per risk.

## 7. Risks to this plan

- **Sandbox is the bottleneck.** Three effective days with no slack. One lost day is survivable, two are not. Mitigation is the stub-first rule above.
- **Half-time tester.** No capacity for exploratory testing beyond what is listed. Developers own all unit and property tests and should expect to pair on sandbox days.
- **Refund SLA depends on PayGate latency.** If sandbox refunds take 40 s or more, 60 s in production is not credible and the requirement should be renegotiated before release, not after.
