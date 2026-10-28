# Test Cases — ORD-4: Order status changes

## Scope and assumptions

The story defines five statuses (Placed, Paid, Shipped, Delivered, Cancelled) and four transitions. Where the story is silent, the following assumptions apply and are referenced by number in the test cases.

- **A1** — Any transition not listed in the story is invalid. An invalid transition is refused, the order's status is unchanged, and the caller receives an error. The story only specifies the error text for AC-5, so for other refusals the tests check only that a refusal occurs and the status does not change.
- **A2** — Delivered and Cancelled are terminal states. No further transition is possible from either.
- **A3** — The exact error message in AC-5 is matched verbatim, including the trailing period: `Shipped orders cannot be cancelled.`
- **A4** — A refused transition does not create a status-history entry or any other side effect (no partial update).
- **A5** — Transitions are applied via whatever interface the system exposes (API, UI, or service call). The steps below are written interface-neutrally; "record a payment" means invoking that operation through the interface under test.
- **A6** — Status values are compared exactly as written in the story (capitalised, e.g. `Paid`). If the system stores an enum or code instead, the visible/returned label must map to these names.
- **A7** — Concurrent updates to the same order are serialised; exactly one of two conflicting transitions wins and the other is refused per A1.

## Coverage summary

| Area | Test IDs |
|---|---|
| Initial state | TC-01 |
| AC-1 Placed → Paid | TC-02, TC-10, TC-11, TC-12, TC-13 |
| AC-2 Paid → Shipped | TC-03, TC-14, TC-15, TC-16, TC-17 |
| AC-3 Shipped → Delivered | TC-04, TC-18, TC-19, TC-20, TC-21 |
| AC-4 Cancel Placed/Paid | TC-05, TC-06, TC-22, TC-23, TC-24 |
| AC-5 Cancel Shipped refused | TC-07, TC-08, TC-09 |
| Full lifecycle / terminal states | TC-25, TC-26, TC-27 |
| Robustness | TC-28, TC-29, TC-30, TC-31 |

---

## Initial state

### TC-01 — New order starts as Placed
- **Priority:** High
- **Preconditions:** None.
- **Steps:**
  1. Create a new order.
  2. Read the order's status.
- **Expected result:** Status is `Placed`.
- **Covers:** Story preamble.

---

## AC-1: Recording a payment on a Placed order changes its status to Paid

### TC-02 — Payment on a Placed order → Paid
- **Priority:** High
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Record a payment on the order.
  2. Read the order's status.
- **Expected result:** Operation succeeds. Status is `Paid`.
- **Covers:** AC-1.

### TC-10 — Payment on an already Paid order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Paid`.
- **Steps:**
  1. Record a payment on the order.
  2. Read the order's status.
- **Expected result:** Operation is refused (A1). Status remains `Paid`.
- **Covers:** AC-1 negative, A1.

### TC-11 — Payment on a Shipped order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Shipped`.
- **Steps:**
  1. Record a payment on the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Shipped`.
- **Covers:** AC-1 negative, A1.

### TC-12 — Payment on a Delivered order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Delivered`.
- **Steps:**
  1. Record a payment on the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Delivered`.
- **Covers:** AC-1 negative, A1, A2.

### TC-13 — Payment on a Cancelled order is refused
- **Priority:** High
- **Preconditions:** An order exists with status `Cancelled`.
- **Steps:**
  1. Record a payment on the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Cancelled`.
- **Covers:** AC-1 negative, A1, A2.

---

## AC-2: Marking a Paid order as shipped changes its status to Shipped

### TC-03 — Ship a Paid order → Shipped
- **Priority:** High
- **Preconditions:** An order exists with status `Paid`.
- **Steps:**
  1. Mark the order as shipped.
  2. Read the order's status.
- **Expected result:** Operation succeeds. Status is `Shipped`.
- **Covers:** AC-2.

### TC-14 — Ship a Placed (unpaid) order is refused
- **Priority:** High
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Mark the order as shipped.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Placed`. (Guards against shipping unpaid orders.)
- **Covers:** AC-2 negative, A1.

### TC-15 — Ship an already Shipped order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Shipped`.
- **Steps:**
  1. Mark the order as shipped.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Shipped`.
- **Covers:** AC-2 negative, A1.

### TC-16 — Ship a Delivered order is refused
- **Priority:** Low
- **Preconditions:** An order exists with status `Delivered`.
- **Steps:**
  1. Mark the order as shipped.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Delivered`.
- **Covers:** AC-2 negative, A1, A2.

### TC-17 — Ship a Cancelled order is refused
- **Priority:** High
- **Preconditions:** An order exists with status `Cancelled`.
- **Steps:**
  1. Mark the order as shipped.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Cancelled`. (Guards against shipping cancelled orders.)
- **Covers:** AC-2 negative, A1, A2.

---

## AC-3: Confirming delivery of a Shipped order changes its status to Delivered

### TC-04 — Confirm delivery of a Shipped order → Delivered
- **Priority:** High
- **Preconditions:** An order exists with status `Shipped`.
- **Steps:**
  1. Confirm delivery of the order.
  2. Read the order's status.
- **Expected result:** Operation succeeds. Status is `Delivered`.
- **Covers:** AC-3.

### TC-18 — Confirm delivery of a Placed order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Confirm delivery of the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Placed`.
- **Covers:** AC-3 negative, A1.

### TC-19 — Confirm delivery of a Paid (not yet shipped) order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Paid`.
- **Steps:**
  1. Confirm delivery of the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Paid`.
- **Covers:** AC-3 negative, A1.

### TC-20 — Confirm delivery of an already Delivered order is refused
- **Priority:** Low
- **Preconditions:** An order exists with status `Delivered`.
- **Steps:**
  1. Confirm delivery of the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Delivered`.
- **Covers:** AC-3 negative, A1, A2.

### TC-21 — Confirm delivery of a Cancelled order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Cancelled`.
- **Steps:**
  1. Confirm delivery of the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Cancelled`.
- **Covers:** AC-3 negative, A1, A2.

---

## AC-4: A Placed or Paid order can be cancelled; its status becomes Cancelled

### TC-05 — Cancel a Placed order → Cancelled
- **Priority:** High
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected result:** Operation succeeds. Status is `Cancelled`.
- **Covers:** AC-4.

### TC-06 — Cancel a Paid order → Cancelled
- **Priority:** High
- **Preconditions:** An order exists with status `Paid`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected result:** Operation succeeds. Status is `Cancelled`.
- **Covers:** AC-4.

### TC-22 — Cancel a Delivered order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Delivered`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected result:** Operation is refused. Status remains `Delivered`. The AC-5 message is **not** expected here, since the order is not Shipped (A1, A3).
- **Covers:** AC-4 negative, A1, A2.

### TC-23 — Cancel an already Cancelled order is refused
- **Priority:** Medium
- **Preconditions:** An order exists with status `Cancelled`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected result:** Operation is refused (A1). Status remains `Cancelled`.
- **Covers:** AC-4 negative, A1, A2.

### TC-24 — Cancelled order cannot resume the normal flow
- **Priority:** High
- **Preconditions:** An order exists with status `Cancelled`.
- **Steps:**
  1. Attempt, in turn: record a payment, mark as shipped, confirm delivery.
  2. Read the order's status after each attempt.
- **Expected result:** All three attempts are refused. Status remains `Cancelled` after each.
- **Covers:** A2 (consolidated check; overlaps TC-13, TC-17, TC-21).

---

## AC-5: Cancelling a Shipped order is refused with "Shipped orders cannot be cancelled."

### TC-07 — Cancel a Shipped order is refused with exact message
- **Priority:** High
- **Preconditions:** An order exists with status `Shipped`.
- **Steps:**
  1. Cancel the order.
  2. Capture the error returned.
  3. Read the order's status.
- **Expected result:** Operation is refused. Error text is exactly `Shipped orders cannot be cancelled.` (A3). Status remains `Shipped`.
- **Covers:** AC-5.

### TC-08 — Refused cancellation of a Shipped order has no side effects
- **Priority:** Medium
- **Preconditions:** An order exists with status `Shipped`; note its status-history / last-modified timestamp if available.
- **Steps:**
  1. Cancel the order (expect refusal).
  2. Inspect the order's status history / last-modified timestamp.
- **Expected result:** No new history entry, no change to last-modified timestamp, no partial update (A4).
- **Covers:** AC-5, A4.

### TC-09 — Shipped order can still be delivered after a refused cancellation
- **Priority:** Medium
- **Preconditions:** An order exists with status `Shipped`.
- **Steps:**
  1. Cancel the order (expect refusal with AC-5 message).
  2. Confirm delivery of the order.
  3. Read the order's status.
- **Expected result:** Step 2 succeeds. Status is `Delivered`. The refused cancellation did not block or corrupt the order.
- **Covers:** AC-5, AC-3.

---

## Full lifecycle and terminal states

### TC-25 — Happy path end to end
- **Priority:** High
- **Preconditions:** None.
- **Steps:**
  1. Create an order. Verify status `Placed`.
  2. Record a payment. Verify status `Paid`.
  3. Mark as shipped. Verify status `Shipped`.
  4. Confirm delivery. Verify status `Delivered`.
- **Expected result:** Each step succeeds and the status matches at each checkpoint. If a status history is kept, it lists exactly `Placed → Paid → Shipped → Delivered` in order.
- **Covers:** AC-1, AC-2, AC-3.

### TC-26 — Delivered is terminal
- **Priority:** Medium
- **Preconditions:** An order exists with status `Delivered`.
- **Steps:**
  1. Attempt, in turn: record a payment, mark as shipped, confirm delivery, cancel.
  2. Read the order's status after each attempt.
- **Expected result:** All four attempts are refused. Status remains `Delivered` after each (A2).
- **Covers:** A2 (consolidated check; overlaps TC-12, TC-16, TC-20, TC-22).

### TC-27 — No skipping steps in the forward flow
- **Priority:** High
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Mark as shipped (expect refusal, status still `Placed`).
  2. Confirm delivery (expect refusal, status still `Placed`).
  3. Record a payment (expect success, status `Paid`).
  4. Confirm delivery (expect refusal, status still `Paid`).
  5. Mark as shipped (expect success, status `Shipped`).
- **Expected result:** As listed per step. Only the next valid transition is ever accepted.
- **Covers:** AC-1, AC-2, AC-3, A1.

---

## Robustness

### TC-28 — Transition on a non-existent order
- **Priority:** Medium
- **Preconditions:** An order ID that does not exist.
- **Steps:**
  1. Attempt each of: record a payment, mark as shipped, confirm delivery, cancel, against the non-existent ID.
- **Expected result:** Each attempt is refused with a "not found"-type error. No order is created as a side effect.
- **Covers:** Robustness.

### TC-29 — Status is persisted across reload
- **Priority:** Medium
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Record a payment.
  2. Re-fetch the order from storage (new request / new session / restart service if feasible).
- **Expected result:** Status is `Paid` on re-fetch, not just in the in-memory response of step 1.
- **Covers:** AC-1, persistence.

### TC-30 — Concurrent conflicting transitions on the same order
- **Priority:** Medium
- **Preconditions:** An order exists with status `Paid`.
- **Steps:**
  1. Simultaneously issue "mark as shipped" and "cancel" against the order.
  2. Read the final status.
- **Expected result:** Exactly one operation succeeds and the other is refused (A7). Final status is either `Shipped` or `Cancelled`, never both applied and never an undefined/intermediate value. If `Shipped` won, the refused cancel returns the AC-5 message; if `Cancelled` won, the refused ship is refused per A1.
- **Covers:** AC-2, AC-4, AC-5, A7.

### TC-31 — Repeated same transition does not double-apply
- **Priority:** Low
- **Preconditions:** An order exists with status `Placed`.
- **Steps:**
  1. Record a payment twice in quick succession (two separate requests).
  2. Read the order's status and status history.
- **Expected result:** First request succeeds (status `Paid`). Second request is refused per TC-10. Status history shows a single `Placed → Paid` entry, not two.
- **Covers:** AC-1, A1, A4.

---

## Transition matrix (reference)

Rows are current status; columns are the operation attempted. ✅ = succeeds with the shown target status; ❌ = refused, status unchanged.

| Current \ Operation | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| **Placed** | ✅ Paid (TC-02) | ❌ (TC-14) | ❌ (TC-18) | ✅ Cancelled (TC-05) |
| **Paid** | ❌ (TC-10) | ✅ Shipped (TC-03) | ❌ (TC-19) | ✅ Cancelled (TC-06) |
| **Shipped** | ❌ (TC-11) | ❌ (TC-15) | ✅ Delivered (TC-04) | ❌ with AC-5 message (TC-07) |
| **Delivered** | ❌ (TC-12) | ❌ (TC-16) | ❌ (TC-20) | ❌ (TC-22) |
| **Cancelled** | ❌ (TC-13) | ❌ (TC-17) | ❌ (TC-21) | ❌ (TC-23) |

## Open points for the product owner

These do not block testing under the stated assumptions, but the answers would tighten the expected results.

1. What error message (if any) is expected for refused transitions other than AC-5? Currently only "refused, status unchanged" is asserted.
2. Is cancelling an already Cancelled order a refusal or a no-op success? Tested as refusal (A1); flip TC-23 if the intended behaviour is idempotent success.
3. Is a status history / audit trail in scope? TC-08, TC-25 and TC-31 reference it conditionally.
4. Should cancelling a Paid order trigger a refund? Out of scope for this story; flagged so it is not silently assumed covered.
