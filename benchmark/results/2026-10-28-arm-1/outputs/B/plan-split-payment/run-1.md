# Split Payment (Release 5.3) – Risk-Based Test Plan

## Executive Summary

This plan prioritizes testing of the split payment feature across three risk tiers over a 2-week delivery window with 1 part-time tester and 2 developers. **Critical path:** split logic validation, refund automation, and regression on existing checkout. **Constraint mitigation:** all PayGate integration tests scheduled for Tuesday/Thursday sandbox windows.

---

## Risk Assessment & Prioritization

| Risk | Impact | Likelihood | Priority | Mitigation |
|------|--------|-----------|----------|-----------|
| Second charge declined; refund not executed or exceeds 60s SLA | Revenue loss, customer disputes, compliance | High | **CRITICAL** | Automated refund flow testing, timer validation |
| Split amount calculation errors (remainder handling) | Revenue discrepancy, customer confusion | High | **CRITICAL** | Unit tests + integration tests across edge amounts |
| Regression: existing single-card checkout breaks under load | 4,000 orders/day lost, business impact | Medium | **CRITICAL** | Smoke test after each build; load test existing flow |
| PayGate integration fails (auth, timeouts, malformed requests) | Feature non-functional | Medium | **CRITICAL** | PayGate sandbox tests Tue/Thu; mock-based tests daily |
| Race condition: concurrent split payment requests | Double-charge or orphaned refunds | Medium | **HIGH** | Concurrency tests, transaction lock validation |
| Edge cases: $0 first card, $0.01 orders, negative amounts | Checkout flow breaks | Medium | **HIGH** | Boundary testing, input validation tests |
| Refund succeeds but customer charged twice (refund fails silently) | Disputes, reputation | Low–Medium | **HIGH** | Refund success/failure paths, PayGate API error handling |
| Timing: refund initiated late (after 60s) | SLA breach | Low | **MEDIUM** | Timer instrumentation, log review |

---

## Test Scope

### **In Scope**
- Split payment flow with two cards (positive & negative paths)
- Split amount calculation (even splits, remainder handling, edge values)
- First charge → second charge sequence
- Refund automation: trigger, execution, timing, status reporting
- PayGate integration: request/response validation, error codes
- Existing single-card checkout (smoke & load)
- Data integrity: order records, payment records, refund records

### **Out of Scope**
- PayGate's internal processing (assumed working per API contract)
- UI/UX validation (delegated to design QA)
- Payment method tokenization/PCI compliance (assumed handled separately)

---

## Test Strategy by Phase

### **Phase 1: Pre-Sandbox Testing (Days 1–4)**
*Resource: 1 tester (20 hrs) + 2 developers*

**Unit & Integration Testing (Dev-Led, Tester Observing)**
- Split amount calculation: [mockup test cases]
  - $100.00 split 50/50 → $50.00 + $50.00
  - $100.01 split 50/50 → $50.01 + $50.00 (remainder on first)
  - $0.01 split (all on first card) → $0.01 + $0.00
  - $1,000.00 split $1/$999 → boundary cases
  - Negative/zero amounts → rejected
  - Split > total amount → rejected
- Refund timer logic (mocked clock): initiate refund, verify triggered ≤60s after second decline
- Existing checkout smoke test: single-card flow executes end-to-end

**Mock PayGate Testing**
- Mock both charges succeeding
- Mock second charge declining (verify refund triggered)
- Mock first charge declining (no refund needed, second charge cancelled)
- Mock timeout on second charge (refund triggered)

**Assumption:** Developers write unit tests; tester validates test coverage and design against requirements.

---

### **Phase 2: PayGate Sandbox Integration (Days 5–7, Tue/Thu)**
*Resource: 1 tester (12 hrs across 2 sandbox windows) + 1 developer pairing*

**Sandboxed End-to-End Tests (Live PayGate)**
- Both charges succeed (happy path)
  - Assertion: both charge IDs logged, order status = "paid"
- Second charge declined (critical refund path)
  - Assertion: first charge refunded within 60s; order status = "refund_pending" then "refunded"
  - Log review: refund request timestamp vs. completion timestamp
- First charge declined (guard case)
  - Assertion: second charge never attempted; order cancelled
- Partial refund scenario (if applicable per business logic): first charge $100, second $50, only second declined
  - Assertion: $50 refunded, order status reflects partial refund
- Timeout on second charge (PayGate slow response)
  - Assertion: refund initiated; retry logic (if any) follows defined backoff

**Load/Concurrency Check (Existing Checkout)**
- 50 concurrent single-card transactions
- Assertion: all succeed, no timeouts, no duplicate charges

**Assumption:** PayGate sandbox credentials available; API documentation provided to testers.

---

### **Phase 3: Regression & Acceptance (Days 8–10)**
*Resource: 1 tester (8 hrs)*

**Regression Test Suite (Automated, Run Daily)**
- Existing single-card checkout: 10 transactions end-to-end
- Split payment happy path: 5 transactions
- Refund path: 2 transactions (decline second card scenario)

**Production-Like Load Simulation**
- Simulate 4,000 orders over 8 hours (single-card + split mix, ~30% split adoption assumed)
- Assertion: all orders processed, no data inconsistencies, no orphaned refunds

**Assumption:** Split payment adoption 30% day-1 (conservative); production-like test environment available.

**Data Validation**
- Order table: verify split amounts stored correctly
- Payment records: verify all charges linked to correct orders
- Refund records: verify refunds link to correct original charge

---

## Test Cases (Summary)

### **Critical Path Test Cases**

| ID | Scenario | Steps | Expected Result | Sandbox | Automated |
|----|-----------|----|--|--|--|
| TC-001 | Split payment, both succeed | Initiate $100 split $60/$40 on two cards → both charges succeed | Order marked paid, both charge IDs logged | Yes | No |
| TC-002 | Second charge declines, auto-refund | $100 split $60/$40, second charge declined via PayGate | First charge refunded ≤60s; order status = refunded | Yes | No |
| TC-003 | Refund failure handling | Second charge declines but PayGate refund API fails | Refund marked failed; alert/retry logged | Yes | No |
| TC-004 | Remainder cent logic | $100.01 split 50/50 | First card $50.01, second $50.00 | Yes | Yes (unit) |
| TC-005 | Single-card checkout (regression) | Existing flow on one card | Order succeeds as before, no performance regression | No | Yes (daily) |
| TC-006 | Concurrent split payments | 50 split payment requests simultaneously | All succeed, no double-charges, no lost refunds | No | Yes (weekly) |
| TC-007 | Invalid split amounts | Attempt: $100 split $101/$0, $0/$100, negative amounts | All rejected with validation error | No | Yes (unit) |
| TC-008 | Edge case: $0.01 order split | $0.01 total, split between two cards | Placed entirely on first card (or rejected per business rule) | Yes | Yes (unit) |

---

## Resource Allocation & Timeline

| Week | Activity | Tester Hours | Dev Hours | Days |
|-----|----------|---|---|---|
| 1 | Mock testing, unit test review | 12 | 16 | 1–4 |
| 1–2 | PayGate sandbox Tue/Thu windows | 12 | 4 | 5–7 |
| 2 | Regression, load test, data validation | 8 | 4 | 8–10 |
| **Total** | | **32 hrs** | **24 hrs** | **10 days** |

**Assumption:** Tester works 20 hrs/week (10 hrs × 2 weeks); developers contribute ~12 hrs/week each.

---

## Defect Severity Mapping

| Severity | Criteria | Example | Hold Release? |
|----------|----------|---------|---|
| Critical | Feature non-functional; revenue loss; data loss; refund SLA miss | Refund not triggered; split logic broken | **YES** |
| High | Regression on existing flow; partial feature failure | Single-card checkout times out; some refunds fail | **YES** |
| Medium | Edge case fails; misleading error message | $0.01 split crashes UI (but rare) | No (if <5% orders) |
| Low | UI text, logging, non-blocking edge case | Refund log unclear | No |

---

## Assumptions & Dependencies

1. **PayGate API & Sandbox:** Full API documentation available by Day 1; sandbox credentials provisioned; sandbox available Tue/Thu only.
2. **Development:** Split feature code complete and code-reviewed by end of Day 4; existing checkout refactored minimally (no regression expected).
3. **Environment:** Test database seeded with realistic order data; ability to reset between sandbox tests.
4. **Business Logic:** Uneven splits always favor first card (remainder cent); refund is automatic (no manual intervention); refund counted as completed once PayGate API returns 2xx.
5. **Monitoring/Logging:** Charge IDs, refund timestamps, and PayGate request/response payloads logged for investigation.
6. **Go/No-Go Criteria:** 
   - All Critical tests pass
   - Existing single-card checkout passes regression suite
   - Refund SLA met in all sandbox tests
   - No data inconsistencies in load test
   - Zero open High or Critical defects

---

## Sign-Off

**Test Plan Owner:** QA (1 half-time tester)  
**Stakeholders:** Product, Engineering, Payments Team  
**Approval Date:** [Release Date - 10 days]  
**Last Updated:** [Today's date]
