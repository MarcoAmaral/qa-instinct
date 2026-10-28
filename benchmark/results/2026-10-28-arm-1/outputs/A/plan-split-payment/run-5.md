# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Executive Summary

**Release Date:** 10 working days (by 2026-11-11)  
**Available Testing Capacity:** ~20 hours (1 tester, half-time)  
**PayGate Sandbox Windows:** Tuesdays and Thursdays only (4 available days before release)  
**Risk Level:** HIGH — payment processing, refund timing, and regression risk against high-volume existing flow

---

## Risk Analysis & Prioritization

| Risk | Impact | Likelihood | Priority | Mitigation Strategy |
|------|--------|-----------|----------|---------------------|
| Split payment not charging both cards or amounts incorrect | Revenue loss, customer refund requests | Medium | **CRITICAL** | End-to-end happy path on live PayGate sandbox; amount validation unit tests |
| Refund not triggered when second charge declines | Customer charged twice, support escalation | High | **CRITICAL** | Integration test with PayGate sandbox decline simulation; monitor 60-second window with timestamps |
| Odd-cent distribution logic fails | Accounting mismatch, customer confusion | Medium | **CRITICAL** | Unit tests + integration scenarios (odd amounts: $1.01, $10.23, $0.99) |
| Existing single-card checkout breaks | 4,000 orders/day fail; revenue impact | Low (isolated change) | **HIGH** | Smoke test on every build; no production code changes to existing path |
| Concurrent requests race condition (simultaneous charges/refunds) | Duplicate charges or failed refund | Low-Medium | **HIGH** | Unit tests for state machine; time-limited load test (5–10 concurrent orders) |
| PayGate integration timeout or network error | Order stuck in limbo, no refund | Medium | **MEDIUM** | Timeout + retry behavior; logging of all PayGate calls with request/response IDs |
| Refund timing exceeds 60 seconds | SLA breach, regulatory risk | Low-Medium | **MEDIUM** | Profiling test on sandbox; measure end-to-end refund latency; identify any DB locks |
| Decimal/currency precision loss in storage or calculation | Small amounts lost, accounting drift | Medium | **MEDIUM** | Unit tests on all arithmetic (add, subtract, compare) with cents; no floating-point math |
| UI validation allows invalid split (e.g., $0 on first card, negative, over limit) | Bad payment attempt, UX friction | Medium | **MEDIUM** | Frontend unit tests for boundary conditions; smoke test UI acceptance |
| Regression in payment reporting/audit logs | Compliance & reconciliation issues | Low | **MEDIUM** | Audit log test (verify both charges logged separately); payment report consistency check |

---

## Test Scope & Strategy

### In Scope
1. **Split payment core logic** — two-card charge flow, amount splitting, odd-cent handling  
2. **Refund automation** — second charge decline → first charge refund within 60 seconds  
3. **PayGate integration** — sandbox testing, error handling, decline scenarios  
4. **Regression** — single-card checkout, audit trail, payment reporting  
5. **Data integrity** — order state, idempotency, concurrent requests  

### Out of Scope
- Full load testing (infrastructure constraint: 1 tester, 10 days)  
- Localization of error messages (assume English)  
- Mobile app payment UI (assume web-first)  
- PayGate production environment testing (sandbox only per constraints)  

---

## Test Execution Plan

### Phase 1: Unit & Integration Tests (Days 1–5, Developers Lead)
**Timeline:** 2026-10-28 to 2026-11-03  
**Runs Locally (No PayGate Dependency)**

| Test Case | Priority | Coverage |
|-----------|----------|----------|
| Amount splitting: even split ($100 → $50/$50) | CRITICAL | Unit |
| Amount splitting: odd amount ($101 → $51/$50, remainder to first card) | CRITICAL | Unit |
| Smallest valid amounts ($0.01 on first card, rest on second) | HIGH | Unit |
| Zero or negative first card amount rejected | HIGH | Unit |
| First card ≥ total order amount rejected | HIGH | Unit |
| Decimal precision (no floating-point errors) | HIGH | Unit |
| Order state machine: pending → both-charged → complete | HIGH | Integration |
| Order state machine: first charged, second declined → refund pending → refunded | CRITICAL | Integration |
| Idempotency: duplicate refund request (same order, already refunded) | HIGH | Integration |
| Concurrent requests (5 split-payment orders simultaneously) | HIGH | Integration (local mock) |
| Existing single-card checkout path unchanged | HIGH | Regression (unit + integration) |
| Audit log entries for both charges and refund (if applicable) | MEDIUM | Integration |

**Entry Criteria:** Code complete, no merge blockers  
**Exit Criteria:** 100% pass rate, code coverage >85% for payment logic

---

### Phase 2: Sandbox Integration Tests (PayGate Available Days Only)
**Timeline:** Thu 2026-10-29, Tue 2026-11-03, Thu 2026-11-05, Tue 2026-11-10  
**Duration:** ~2 hours per sandbox window (tester + 1 developer pair)

| Test Case | Day | Priority | PayGate Setup |
|-----------|-----|----------|---------------|
| Happy path: two charges succeed in sequence | 10/29 | CRITICAL | Normal charges; verify both settle within 2 minutes |
| Second charge declined: first refunded within 60s | 10/29 | CRITICAL | Use PayGate decline test card on second charge; measure refund latency with timestamps |
| Second charge timeout: fallback behavior (retry or refund?) | 11/03 | HIGH | Network delay simulation (if PayGate supports) or manual timeout injection |
| Refund idempotency: refund same charge twice → second is no-op | 11/03 | HIGH | Attempt duplicate refund; verify no double-refund |
| Payment reporting: both charges appear as separate line items | 11/05 | MEDIUM | Export payment report; verify split amounts match order split |
| Edge case: $1.00 order, $0.01 on first card, $0.99 on second | 11/05 | MEDIUM | Verify both charges settle correctly |
| Single-card checkout regression: confirm existing flow works on PayGate | 11/10 | HIGH | One test order using old single-card path |
| Load on existing flow: 10 sequential single-card orders in 2 minutes | 11/10 | MEDIUM | Smoke test that existing ~4k/day volume is not slowed down |

**Entry Criteria:** Unit tests pass; PayGate sandbox is available; test credit card(s) funded  
**Exit Criteria:** All CRITICAL tests pass; any HIGH/MEDIUM failures have a documented workaround or post-release fix plan

---

### Phase 3: Pre-Release Validation (Day 10, All Hands)
**Timeline:** 2026-11-11 (Release Day)

| Activity | Owner | Time |
|----------|-------|------|
| Dry run: 3 live split-payment orders on staging (if staging mirrors prod PayGate config) | Developers | 30 min |
| Verify audit logs and payment report on staging | Tester | 15 min |
| Confirm rollback plan (if split payment is feature-flagged) | Developers | 15 min |
| Final sanity check: single-card checkout still works | Tester | 10 min |

---

## Test Data & Scenarios

### Representative Test Cases

**Amount Splitting (Arithmetic):**
- $50.00 order, $25.00 first card → $25.00 second card ✓
- $50.01 order, $25.00 first card → $25.01 second card (remainder to first) ✓
- $0.99 order, $0.01 first card → $0.98 second card ✓
- $10,000.00 order, $9,999.99 first card → $0.01 second card ✓

**Decline & Refund:**
- First charge succeeds, second declines → refund first within 60 seconds, order marked failed
- Both charges succeed → no refund, order marked complete
- First charge declines → stop, don't attempt second, no refund needed

**Edge Cases:**
- First card amount = 0 or negative → reject at validation
- First card amount > order total → reject at validation
- Network timeout during refund → retry logic (define: immediate? 5s? 60s max?) + alert
- Concurrent split payment + single-card order → both process independently

---

## Resource Allocation

| Role | Days 1–5 | Days 6–10 | Effort |
|------|----------|-----------|--------|
| **Developers (2)** | Unit/integration tests, mock PayGate adapter | Sandbox validation, hotfix, rollback prep | ~60% time |
| **Tester (half-time)** | Test case authoring, setup, env prep | Sandbox execution, regression testing, sign-off | 20 hours total |
| **PayGate Liaison (async)** | Confirm sandbox access, decline card numbers | — | Minimal |

**Critical Path:** Sandbox testing compressed into 4 non-consecutive days → prioritize CRITICAL tests on 10/29 and 11/03; defer edge cases to 11/05 if time-constrained.

---

## Success Criteria & Release Gates

**Must Pass Before Release:**
- [ ] All CRITICAL unit tests pass (amount splitting, refund trigger)  
- [ ] Split-payment happy path succeeds on PayGate sandbox (both charges settle)  
- [ ] Refund triggered and completed within 60 seconds when second charge declines  
- [ ] Single-card checkout regression test passes (no breakage)  
- [ ] Audit log entries for both charges and any refunds are present and correct  

**Should Pass (Defer Post-Release if Necessary, with Hotfix Plan):**
- [ ] All HIGH integration tests pass (concurrency, idempotency, timeouts)  
- [ ] Odd-cent distribution validated on sandbox (at least one live test)  
- [ ] Load test on existing flow shows no slowdown  

**Definition of "Regression":**
- Any order with existing single-card checkout method fails to charge or settles incorrectly  
- Existing audit logs or payment reports are corrupted or incomplete  

---

## Assumptions

1. **PayGate sandbox test environment** mirrors production behavior (charge timing, decline responses, settlement).  
2. **Odd-cent rule** ("remainder to first card") is non-negotiable and encoded in spec; no product questions needed.  
3. **Refund automation** is database-triggered (e.g., scheduled job or event listener), not manual, and has 60-second SLA.  
4. **Existing single-card checkout** code is not modified; split payment is additive (new endpoint or flag).  
5. **Feature is behind a feature flag** or soft-launch (e.g., beta customers only), allowing quick rollback if critical issues found.  
6. **One tester is QA-trained** and comfortable with payment testing (PCI awareness, test card handling).  
7. **Database schema** supports tracking two payment transactions per order without breaking existing queries.  
8. **Order total limit** exists and is enforced by existing code; no new validation boundary to discover.

---

## Risk Mitigation & Rollback

| Scenario | Detection | Response |
|----------|-----------|----------|
| Split payment not charging → revenue loss | Audit log shows order with 0 or 1 charges | Rollback feature flag; manual refund + recharge on single-card path |
| Refund not triggered → customer charged twice | Order status "failed" but refund_status NULL or "pending" after 60s | Trigger manual refund; hotfix retry logic; rollback if endemic |
| Single-card checkout broken | Tester smoke test fails or prod support alerts spike on normal checkout | Immediate rollback; investigate regression; revert last commit |
| PayGate integration timeout → orders stuck | New orders with split payment don't complete in 5 minutes | Rollback feature flag; implement timeout handling in hotfix before re-release |

**Rollback Procedure:** Feature flag toggle (if implemented) or git revert + redeploy (if integrated) — define pre-release.

---

## Compliance & Audit

- **Payment Card Industry (PCI):** Ensure no card details logged; only PayGate tokens and transaction IDs in audit trail.  
- **Refund SLA:** 60-second requirement must be logged (timestamp of decline, timestamp of refund completion) for regulatory audit.  
- **Revenue Recognition:** Confirm finance team knows how split payments are reported in daily settlement reports.
