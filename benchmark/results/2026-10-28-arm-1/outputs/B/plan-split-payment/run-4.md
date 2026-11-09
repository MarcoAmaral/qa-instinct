# Split Payment Test Plan (Release 5.3)

## Executive Summary

This test plan prioritizes split payment functionality validation while protecting the critical single-card checkout path. Given 1 FTE half-time tester (~70 hours available), PayGate sandbox access limited to Tuesdays and Thursdays, and a 10-working-day timeline, testing focuses on high-impact financial and integration scenarios.

## Risk Assessment & Prioritization

### Critical Risk (Test First)
- **Second charge decline → no automatic refund**: Financial liability, compliance violation, direct revenue loss
- **Refund not completed within 60 seconds**: Regulatory non-compliance, customer disputes
- **Incorrect cent allocation (remainder logic)**: Persistent accuracy problem affecting all split orders
- **Regression to single-card checkout**: Blocks ~4,000 orders/day, immediate revenue impact

### High Risk (Test Next)
- **PayGate integration failure**: Dependency on external system; sandbox limited access
- **Concurrent split payment requests**: Race conditions in refund logic or charge orchestration
- **Partial charge states** (first succeeds, second pending): Hung transactions, customer confusion

### Medium Risk (Test After Critical/High)
- **Edge case amounts** (zero split, negative, exceeds transaction limit): Validation gaps
- **Customer card updates mid-transaction**: Data consistency
- **PCI/payment data handling**: No sensitive data logged or stored improperly

### Low Risk (Spot Check)
- **UI/UX for amount selection**: Non-blocking for payment processing
- **Receipts/confirmation emails**: Notification accuracy

---

## Test Strategy

### Phase 1: Unit & Integration (Days 1–2, Oct 29–30)
**Goal**: Validate core logic before PayGate testing.

- Remainder cent allocation logic (happy path: $10.50 split 60/40, $100 split 50/50, $0.01 split)
- Refund triggering and timing (mock PayGate responses)
- State machine for charge sequences (charge1 success → charge2 success, charge2 decline, charge2 pending timeout)
- Error handling: invalid amounts, duplicate requests, missing card data

**Assumption**: Team has unit test harness; mock PayGate SDK available for integration tests.

### Phase 2: PayGate Sandbox Integration (Days 3–4, Nov 4–5 *Tuesday/Thursday window*)
**Goal**: Validate against live PayGate sandbox with real API responses.

- First charge succeeds, second charge succeeds (sunny day)
- First charge succeeds, second charge declined → refund first within 60 seconds (critical path)
- Verify refund transaction ID logged and matches first charge
- Timeout handling: second charge no response after 30 seconds → timeout logic

**Assumption**: PayGate sandbox credentials and test cards available; test data reset between runs.

### Phase 3: Regression & Load (Days 5–7, Nov 6–10)
**Goal**: Protect single-card checkout; validate under expected volume.

- Single-card checkout: 50 transactions across payment gateways (no split parameter)
- Checkout flow unchanged (button placement, success/error messages)
- Split payment feature flag behavior (on/off without code restart)
- Concurrent split requests (10 simultaneous orders with different splits)

**Assumption**: Test environment supports concurrent load; feature flag configuration available.

### Phase 4: Edge Cases & UAT (Days 8–10, Nov 13–15)
**Goal**: Close gaps; prepare for production.

- Amount edge cases: $0.01 split (all on first card), $999,999.99 split, split exceeding card limits
- Same card used for both splits (allowed/disallowed per PayGate policy)
- Declined first charge (should not attempt second charge)
- Manual refund via admin console (idempotency: refunding twice should not double-refund)
- Error message clarity (customer sees actionable text, not stack traces)
- Customer data: verify card info not persisted; PCI scope clear

---

## Test Cases by Priority

### CRITICAL: Refund on Second-Charge Decline
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-001 | Charge 1 OK, Charge 2 declined | Split $100 50/50; Card1 valid, Card2 declined | Refund $50 to Card1 within 60s; no charge on Card2 | Timer start: charge 2 initiated. Verify refund ID in logs. |
| SPLIT-002 | Refund idempotence | Trigger SPLIT-001; manually refund again via admin | Only one $50 refund processed | Prevents double-refunds if webhook fires twice. |
| SPLIT-003 | Refund timing boundary | Measure refund completion time | ≤60 seconds from decline | Use test logs/PayGate timestamps; repeat 5×. |

### CRITICAL: Remainder Cent Allocation
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-004 | Odd-cent split | Split $10.01 at 60/40 | Charge1: $6.01, Charge2: $4.00 | Remainder (1¢) on first card. Test 3 scenarios: $X.01, $X.02, $X.09. |
| SPLIT-005 | Even split, even cents | Split $10.00 at 50/50 | Each: $5.00 | Verify no rounding errors. |

### CRITICAL: Regression to Single-Card
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-006 | Single-card checkout active | Complete 10 orders without split | All succeed; no regression in latency | Run on each release candidate build. |
| SPLIT-007 | Feature flag disabled | Disable split feature; attempt split | Split UI hidden; checkout reverts to single-card | Verify clean degradation. |

### HIGH: PayGate Integration
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-008 | Both charges succeed | Split $100 50/50; both cards valid | Two charges in PayGate with correct IDs; order marked "paid" | Verify transaction IDs linked in system. |
| SPLIT-009 | Charge 2 timeout | Charge 2 no response for 45 seconds | Automatic reversal of Charge 1; customer notified | Prevents hung transactions. |
| SPLIT-010 | PayGate API error (500) on Charge 2 | Charge 1 succeeds, Charge 2 returns 500 | Treat as decline; refund Charge 1 per SPLIT-001 | Distinguish transient errors from declines. |

### HIGH: Concurrent Requests
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-011 | 5 split orders simultaneously | Submit 5 orders (different customers) with splits | All process independently; no cross-order refunds | Run during sandbox window. |
| SPLIT-012 | Duplicate split request (network retry) | Send same split order twice within 1 second | Idempotency key prevents double-charge | Verify only one pair of charges created. |

### MEDIUM: Edge Cases
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-013 | $0.01 split (all on first card) | Customer enters 100% on Card1, 0% on Card2 | UI prevents zero-cent charge; or Charge2 skipped gracefully | Clarify product requirement. |
| SPLIT-014 | Split exceeds card limit | Card1 limit $5,000; split $6,000 40/60 | Decline Charge1 (not a split problem); no Charge2 attempted | Verify single-charge validation runs first. |
| SPLIT-015 | Same card for both splits (if allowed) | Use Card1 for both split amounts | Both charges succeed; receipts show as two separate transactions | Verify PayGate allows; confirm customer sees clearly. |

### LOW: UI/Messaging
| ID | Scenario | Steps | Expected | Notes |
|---|---|---|---|---|
| SPLIT-016 | Error message: Charge 2 decline | Trigger SPLIT-001 | Customer sees "Second charge declined. We've refunded the first charge." (not technical PayGate error) | Acceptance: no jargon, actionable. |
| SPLIT-017 | Success confirmation | Both charges succeed | Receipt lists split amounts clearly; confirmation email shows both transactions | UX review required. |

---

## Regression Test Suite (Single-Card Checkout)

**Scope**: Existing checkout flow must not degrade.

| Test | Frequency | Owner |
|---|---|---|
| 10 successful single-card transactions | Per build | Tester |
| 2 single-card declines (correct error message) | Per build | Tester |
| Checkout latency ≤ 3 seconds (p95) | Daily | Automation (if available) |
| No new error logs in payment service | Per build | Tester review logs |

---

## Environment & Dependencies

| Item | Assumption | Risk Mitigation |
|---|---|---|
| **PayGate Sandbox** | Available Tue/Thu only; test cards provided by PayGate docs | Schedule 2 sandbox test windows (Nov 4–5); prepare test cases offline; use mocks for other phases. |
| **Feature Flag** | Toggleable without re-deploy | Confirm with devs before testing. |
| **Test Database** | Reset available; safe for refund testing | Coordinate with team; use isolated test org/tenant. |
| **Logging/Monitoring** | Transaction logs and refund timestamps queryable | Clarify log retention; get read access to PayGate webhooks. |
| **Admin Console** | Manual refund trigger available for SPLIT-002 testing | Verify access; test 1× before critical tests. |

---

## Timeline

| Phase | Dates | Effort | Sandbox Window |
|---|---|---|---|
| Unit/Integration (mocks) | Oct 29–30 (Wed–Thu) | ~16 hrs | — |
| **PayGate Sandbox Test 1** | **Nov 4–5 (Tue–Wed)** | **~12 hrs** | **Tue/Thu** |
| Regression & Feature Validation | Nov 6–10 (Wed–Fri) | ~20 hrs | — |
| **PayGate Sandbox Test 2** | **Nov 13 (Tue)** | **~12 hrs** | **Tue** |
| UAT & Edge Cases | Nov 14–15 (Wed–Fri) | ~14 hrs | — |
| **Buffer (defects, re-test)** | Nov 18–20 | ~6 hrs | — |
| **Total** | | **~90 hrs** | — |

*Note*: 90 hrs budgeted; 70 hrs available (1 FTE half-time × 10 days). Recommend: defer low-priority edge cases (SPLIT-013–017) if critical tests exceed time; prioritize CRITICAL & HIGH risk.

---

## Assumptions

1. **PayGate API**: Sandbox supports test cards for success, decline, and timeout scenarios per PayGate documentation.
2. **Refund API**: PayGate exposes refund endpoint with timestamps; PayGate documentation or spike test confirms 60-second refund SLA is achievable (not a third-party delay).
3. **Feature Logic**: Remainder-cent allocation is deterministic (spec: "remainder cent goes on first card"). No floating-point ambiguity.
4. **Regression Scope**: Single-card checkout is 100% of current orders; no other payment methods in scope.
5. **Defect Severity**: P1 (refund failure, regression) blocks release; P2 (edge case validation) does not.
6. **Automation**: No existing payment test automation assumed; manual testing only. Recommend automating CRITICAL cases post-release.
7. **Compliance**: PCI compliance is pre-existing; new split feature does not introduce new PCI requirements (no card data persisted by our system).
8. **Release Criteria**: Both cards charged and refund logic verified on sandbox; single-card regression cleared; UAT approval required.

---

## Success Criteria

- ✓ CRITICAL test cases pass (SPLIT-001–007): 0 financial loss, 0 regression
- ✓ HIGH test cases pass (SPLIT-008–012): PayGate integration stable
- ✓ Refund timing verified ≤60 seconds (logged, measured, repeatable)
- ✓ Single-card checkout regression test suite passes with no new errors
- ✓ No PCI compliance regression (third-party security review if required by ops)
- ✓ UAT approval from product & payments team
- ✓ Release sign-off from tech lead & QA lead

---

## Post-Release

- Monitor refund SLA in production (target: 100% within 60s) for first 48 hours
- Log all split transactions for finance audit (first 1,000 orders)
- On-call escalation path for split payment failure (documented)
