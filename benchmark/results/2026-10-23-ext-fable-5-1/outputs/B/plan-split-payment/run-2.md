# Test Plan: Split Payment (Release 5.3)

**Release date:** Friday 6 November 2026 (10 working days from Saturday 24 October 2026).
**PayGate sandbox windows:** Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov. Four days total.
**Team:** one tester at half time (about 5 person-days), two developers.

## 1. Scope

In scope: two-card split at checkout, amount entry and validation, cent rounding, sequential PayGate charges, automatic refund on second-card decline, order and payment records, existing single-card checkout regression, cancel/refund of a split order.

Out of scope: more than two cards, saved-card wallets, new currencies, PayGate internal behaviour beyond its documented contract.

## 2. Assumptions

Where the brief is silent, testing proceeds on these assumptions. Each is confirmed with the developers on day one and the plan adjusts if any is wrong.

- Amounts are integer cents. The customer enters a whole-cent amount for card one. The "remainder cent" rule applies only when the system proposes an even split (for example a 50/50 default).
- Card one must be charged at least 1 cent and strictly less than the order total. Both charges must be above PayGate's minimum charge amount.
- Card one is charged first. If card one is declined, card two is never charged.
- The 60-second window runs from receipt of the card-two decline to PayGate acknowledging the refund request.
- If the automatic refund fails, the order is held, an alert fires, and the case lands in a manual queue. Nothing is silently dropped.
- Split payment ships behind a feature flag. With the flag off, the single-card path is byte-for-byte the current code path.
- The same card may be used for both halves. PayGate treats them as two independent charges.
- Developers build a local PayGate stub from the API docs, used on non-sandbox days and validated against the real sandbox on sandbox days.
- PayGate sandbox offers test cards for approve, each decline reason, timeout, and refund failure.

## 3. Risk assessment

Priority drives effort. P1 risks get sandbox time and automation. P3 risks get exploratory coverage only if time remains.

| ID | Risk | Likelihood | Impact | Priority |
|----|------|-----------|--------|----------|
| R1 | Card two declined, refund of card one fails or exceeds 60 s. Customer loses money with no order. | Medium | Critical | P1 |
| R2 | Single-card checkout regresses. About 4,000 orders a day are affected. | Medium | Critical | P1 |
| R3 | Gateway timeout or lost response leaves a charge in unknown state, causing a double charge or an unpaid order. | Medium | Critical | P1 |
| R4 | Rounding or validation error: amounts do not sum to the total, negative or zero amounts accepted, remainder cent on the wrong card. | High | High | P1 |
| R5 | Sandbox available only four days. Real-gateway defects found late with no time to fix. | High | High | P1 (process) |
| R6 | Duplicate submission or retry charges a card twice. Missing idempotency keys. | Medium | High | P2 |
| R7 | Post-purchase cancel or refund handles only one of the two charges. | Medium | High | P2 |
| R8 | Order, ledger, and reconciliation records show one payment instead of two, or the refund is not recorded. | Medium | Medium | P2 |
| R9 | Latency doubles because of two sequential gateway calls. Checkout times out under peak load. | Low | Medium | P3 |
| R10 | Card data or full PAN appears in logs for the new code path. | Low | High | P2 |
| R11 | Mock drifts from real PayGate behaviour, so green mock tests hide real defects. | Medium | High | P2 |

## 4. Test approach

**Unit tests (developers, every day).** Amount splitting, rounding, validation boundaries, state machine for charge one, charge two, refund. Target: every branch of the split and refund logic covered before the first sandbox day.

**Integration tests against the PayGate stub (developers and tester, non-sandbox days).** Full checkout flow with scripted gateway responses: approve, each decline code, timeout, malformed response, refund failure. This is where R3 and R6 are exercised, since the real sandbox cannot easily simulate dropped responses.

**End-to-end on the PayGate sandbox (tester, sandbox days only).** Each sandbox day has a fixed agenda, listed in section 6. Every sandbox session records request and response pairs so the stub can be corrected the next morning (addresses R11).

**Regression of single-card checkout (automated, every day).** The existing checkout suite runs with the flag off and with the flag on. Any difference with the flag off is a release blocker.

**Non-functional checks.** Refund timing measured on sandbox across at least ten decline events. Load test against the stub at three times the daily peak. Log review for card data.

**Exploratory testing (tester, one session).** Browser back button, refresh during charge two, expired session, two tabs, currency display.

## 5. Key scenarios

| # | Scenario | Risk | Level |
|---|----------|------|-------|
| S1 | Both cards approved. Order confirmed. Two payment records with correct amounts. | Baseline | Stub, sandbox |
| S2 | Card two declined (each decline reason). Card one refunded. Refund acknowledged within 60 s. Order not created. Customer sees a clear message. | R1 | Sandbox |
| S3 | Card one declined. Card two never called. | R1 | Stub, sandbox |
| S4 | Card two declined and the refund call fails. Alert fires, order held, manual queue entry created. | R1 | Stub |
| S5 | Card two declined and the refund takes longer than 60 s. Behaviour matches spec (alert or retry). | R1 | Stub |
| S6 | Timeout on charge one. No second charge. Retry uses the same idempotency key. | R3 | Stub |
| S7 | Timeout on charge two. System resolves state before refunding or confirming. No double charge. | R3 | Stub |
| S8 | Even split of an odd total. Card one gets the extra cent. Example total 1001 gives 501 and 500. | R4 | Unit |
| S9 | Boundary amounts: card one at 0, 1, total minus 1, total, total plus 1, negative, non-numeric, more than two decimals. | R4 | Unit, stub |
| S10 | Amount below PayGate minimum on either card is rejected before any charge. | R4 | Stub, sandbox |
| S11 | Double click on Pay. Exactly one charge per card. | R6 | Stub |
| S12 | Cancel a completed split order. Both charges refunded. | R7 | Sandbox |
| S13 | Partial refund of a split order. Refund allocation documented and correct. | R7 | Sandbox |
| S14 | Single-card checkout, flag off, full existing suite. | R2 | Automated |
| S15 | Single-card checkout, flag on, customer chooses one card. Identical outcome to S14. | R2 | Automated, sandbox |
| S16 | Same card entered twice. Two charges, both succeed or refund logic applies. | R4 | Sandbox |
| S17 | Ledger and reconciliation export show two payments and any refund. | R8 | Sandbox |
| S18 | Logs for the split path contain no PAN, CVV, or expiry. | R10 | Review |
| S19 | Load at three times peak against the stub. P95 checkout latency within existing SLA. | R9 | Stub |

## 6. Schedule

The tester concentrates hours on sandbox days and works full days then. Other days are short.

| Day | Date | Sandbox | Activity |
|-----|------|---------|----------|
| 1 | Mon 26 Oct | No | Confirm assumptions. Finalise scenarios. Developers deliver stub and unit tests for rounding and validation. |
| 2 | Tue 27 Oct | Yes | Contract capture: run every test card and refund call on sandbox. Record responses. S1, S2, S3 first pass. |
| 3 | Wed 28 Oct | No | Correct stub from captured responses. Run S4 to S11 against stub. Regression S14 automated and running in CI. |
| 4 | Thu 29 Oct | Yes | S2 timing measurement, ten decline events. S12, S13, S15, S16, S17 on sandbox. |
| 5 | Fri 30 Oct | No | Triage and fixes. Tester reviews logs (S18). Developers run S19 load test. |
| 6 | Mon 2 Nov | No | Verify fixes on stub. Exploratory session. |
| 7 | Tue 3 Nov | Yes | Full sandbox regression of S1 to S3, S12 to S17. Re-measure refund timing after fixes. |
| 8 | Wed 4 Nov | No | Final fix verification on stub. Rollback test: flag off restores single-card path. |
| 9 | Thu 5 Nov | Yes | Go/no-go sandbox run. Only blocker fixes accepted after this point. |
| 10 | Fri 6 Nov | No | Release behind flag. Production verification with one small real split order. Monitoring on refund failures and single-card error rate. |

If a sandbox day is lost, the matching stub-based scenarios run that day and the sandbox agenda shifts to the next window. Losing Thu 5 Nov means release slips one sandbox day unless Tue 3 Nov was fully clean.

## 7. Roles

- **Tester:** owns this plan, sandbox sessions, refund timing evidence, exploratory testing, go/no-go recommendation.
- **Developer A:** PayGate stub, idempotency and timeout scenarios, load test.
- **Developer B:** unit tests for splitting and validation, single-card regression suite in CI, flag and rollback.
- **Daily 15-minute sync** to re-rank risks and reassign sandbox time.

## 8. Entry and exit criteria

**Entry to sandbox testing:** stub tests for S1 to S11 passing, feature flag working, test cards obtained.

**Exit for release:**

- All P1 scenarios pass on the real sandbox on Thu 5 Nov.
- Refund acknowledged within 60 s in every measured decline event, with evidence attached.
- No open Severity 1 or 2 defects. Severity 3 defects have an owner and a date.
- Single-card regression suite green with the flag on and off.
- Alerting for refund failure deployed and tested with S4.
- Flag-off rollback verified.

## 9. Release safeguards

- Ship with the flag off, then enable for a small share of customers for two days before full rollout.
- Dashboard: split-order count, card-two decline rate, refund success rate, refund time, single-card error rate.
- Kill switch: flag off disables the split option without a deploy.
- Daily reconciliation report reviewed by finance for the first week.

## 10. Known gaps

- Dropped-response and refund-failure behaviour is verified on the stub only. The real gateway may behave differently under those conditions.
- With five person-days of tester effort, exploratory coverage is thin. Developers cover the difference.
- Load testing uses the stub, so real gateway latency under load is not measured before release.
