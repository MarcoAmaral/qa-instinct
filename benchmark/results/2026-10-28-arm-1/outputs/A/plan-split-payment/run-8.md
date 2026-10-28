# Risk-Based Test Plan: Split Payment (Release 5.3)

## Executive Summary

This feature introduces payment processing complexity (two-stage charges, conditional refund logic) and a hard real-time constraint (60-second refund window). The highest risks are incomplete refunds, race conditions causing data inconsistency, and regression of the existing checkout flow (4,000 orders/day). Test strategy prioritizes these over feature completeness. Resource constraint (1 half-time tester) drives test automation and staged execution aligned with PayGate sandbox availability (Tues/Thurs).

## Assumptions

- Split payment is behind a feature flag and can be rolled back without data migration.
- Existing checkout and split checkout share the same PayGate integration client.
- Monitoring and alerting are in place for failed charges and refunds.
- At least one pre-production environment exists with PayGate sandbox credentials.
- The 60-second refund must complete end-to-end (API call completion), not just initiation.
- Failure during second charge means zero refund has been processed yet; first charge refund is always possible.
- A single charge can be refunded multiple times (partial refunds) or the system prevents double-refunds.

## Risk Matrix

| Risk | Severity | Likelihood | Score | Mitigation Priority |
|------|----------|------------|-------|---------------------|
| First charge succeeds, second charge declines, refund fails or exceeds 60-second window | Critical | High | 9 | Highest |
| Race condition: simultaneous payment processing causes double-charge or inconsistent ledger | Critical | Medium | 8 | Highest |
| Remainder cent logic incorrect (e.g., goes to second card instead of first) | High | Low | 4 | High |
| Single-card checkout regression (4,000 orders/day) | Critical | Low | 7 | Highest |
| PayGate timeout/unavailability during charge | High | Medium | 6 | High |
| Idempotency: retry on first or second charge creates duplicate transactions | High | Medium | 6 | High |
| Customer sees charged amount but order fails mid-flow (confirmation/DB insert) | High | Medium | 6 | High |
| Concurrent refunds triggered (webhook + timeout retry) | High | Medium | 6 | High |

## Test Strategy by Risk

### Tier 1: Critical Path (60% of test effort)
**Scope:** Refund logic, data consistency, regression of existing checkout.

1. **Refund timing and accuracy** (must test Tues/Thurs against PayGate sandbox)
   - Manual test: First charge succeeds, second declines. Verify refund initiated within 5 seconds; completes within 60 seconds. Check ledger shows refund.
   - Repeat 5 times with different payment amounts (including edge cases: 1¢ split, $0.01 first card, $x.99 splits).
   - Expected outcome: 100% of refunds complete on time; order marked as failed; no phantom credits.

2. **Single-card checkout regression** (smoke test on both existing and new code paths)
   - Automated: 10 baseline orders through existing checkout; verify all succeed.
   - Before deployment, run same test. After deployment with feature flag off, repeat. After feature flag on, run with flag on and off.
   - Expected outcome: 100% pass rate, no timing degradation.

3. **Race condition: simultaneous charges**
   - Automated: Simulate two requests trying to charge the same order simultaneously at the payment gateway level (mock 10ms delay between first and second charge).
   - Verify: Order state machine prevents double-processing; only one charge succeeds; no ledger inconsistency.
   - Expected outcome: Requests serialize or one fails cleanly without partial state.

### Tier 2: Integration & Correctness (25% of test effort)

4. **Amount split accuracy** (unit + integration)
   - Automated: Parameterized tests for all cent splits: $10.00 → $5.00/$5.00, $10.01 → $5.01/$5.00, $10.99 → $5.50/$5.49, $0.01 → $0.01/$0.00.
   - Expected outcome: Remainder always on first card; sum equals order total; cents never lost.

5. **PayGate integration: both charges via sandbox**
   - One manual end-to-end run per PayGate sandbox window (Tues or Thurs). Both charges approved.
   - Verify PayGate transaction records match internal ledger.
   - Expected outcome: 2 separate charges in PayGate; both recorded correctly.

6. **Idempotency on retry**
   - Automated: Simulate first charge succeeds, API crashes before recording it in DB. Retry occurs. Verify no duplicate charge to PayGate; order state consistent.
   - Simulate second charge initiated twice. Verify only one charge succeeds or both fail cleanly.
   - Expected outcome: Retries do not duplicate charges; idempotency key prevents multiples.

### Tier 3: Edge Cases & Non-Functional (15% of test effort)

7. **PayGate unavailability during flow**
   - Automated mock: First charge succeeds (recorded in DB), second charge times out. Verify refund is triggered; escalation to monitoring works.
   - Expected outcome: Refund initiated; alert sent; order marked in recovery state.

8. **Order confirmation and state transitions**
   - Automated: Verify order state progresses: pending → charging-first → charging-second → refunding-on-decline → failed OR charged.
   - Capture state at each step; simulate crash; replay. Verify state machine is durable.
   - Expected outcome: No orphaned states; recovery is deterministic.

9. **Load test: existing checkout under split-payment deployment**
   - Resource: Run 100 single-card orders concurrently on pre-prod with split-payment code deployed (feature flag off). Monitor latency, error rate.
   - Expected outcome: No degradation vs. baseline; < 1% error rate; p99 latency ≤ 500ms.

---

## Test Execution Plan

### Week 1 (Days 1–5)
- **Days 1–2 (Mon–Tue):** Unit tests + automated integration tests (no PayGate needed yet). Tester prepares PayGate sandbox credentials, runs Tier 2.5 (unit + mocked PayGate).
- **Tues (sandbox available):** Tester performs manual Tier 2.5 end-to-end with real PayGate: one happy-path split charge, one decline-on-second scenario. Record timings.
- **Wed–Fri:** Automated Tier 1 (race conditions, refund logic simulation) and Tier 3 (edge cases, state machine).

### Week 2 (Days 6–10)
- **Mon–Wed:** Full regression sweep (single-card + existing flows). Load test (Tier 3.9).
- **Thu (sandbox available):** Final manual validation: refund timing under load if possible; verify monitoring alerts.
- **Fri:** UAT sign-off, rollout prep.

---

## Test Artifacts & Sign-Off

**Automated Test Coverage:**
- Refund logic: 15+ scenarios (timing, amounts, idempotency, retries). Target: ≥ 95% pass rate.
- Single-card regression: 20 baseline transactions. Target: 100% pass rate, no latency regression.
- Race conditions & state machine: 20+ concurrent scenarios. Target: 100% pass rate, no orphaned state.
- Amount split accuracy: 50+ edge cases. Target: 100% pass.
- Load test: 100 concurrent orders. Target: < 1% error rate, p99 ≤ 500ms.

**Manual Test Coverage:**
- PayGate sandbox runs: ≥ 2 windows (Tues + Thu if needed). Document transaction IDs, timing, ledger reconciliation.
- Refund timing: ≥ 5 decline scenarios, all under 60 seconds.

**Regression Baseline:**
- Single-card checkout latency and error rate before/after deployment.

**Sign-Off Criteria:**
1. All Tier 1 tests pass; zero refund timeouts in sandbox.
2. All Tier 2 integration tests pass; PayGate reconciles end-to-end.
3. Single-card checkout regression tests pass; no latency increase.
4. Load test passes; no errors under concurrent load.
5. Monitoring alerts verified for refund failures.
6. Feature flag functional (on/off) verified.

**Known Unknowns (require dev feedback before Fri Day 10):**
- Does the system implement partial refund if full refund fails? Test plan assumes yes; if no, escalate risk.
- Is there a webhook from PayGate, or polling for refund status? Test will verify implementation choice.
