# Test Cases — ORD-4: Order status changes

## Assumptions

- A1: Statuses are exactly: Placed, Paid, Shipped, Delivered, Cancelled. No other status exists.
- A2: The lifecycle is linear: Placed → Paid → Shipped → Delivered. Skipping a step (e.g. shipping a Placed order) is not allowed and is refused.
- A3: Delivered and Cancelled are terminal. No transition out of them is allowed; attempts are refused.
- A4: A refused transition leaves the order status unchanged and returns an error. For transitions other than AC-5 the exact error text is unspecified; tests only assert that an error is returned and the status is unchanged.
- A5: The error message in AC-5 is matched exactly, including capitalisation and the trailing full stop.
- A6: Re-applying a transition that the order has already passed (e.g. paying a Paid order) is refused, not silently ignored.
- A7: Status is persisted and visible to both customer and staff views after each change.
- A8: Transitions can be triggered via whatever interface exists (API/UI); each test applies to all interfaces that expose the action.

Status key for tables: P = Placed, PD = Paid, S = Shipped, D = Delivered, C = Cancelled.

---

## 1. Order creation

| ID | Title | Preconditions | Steps | Expected result | AC |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create a new order. 2. Read its status. | Status is `Placed`. | Story |
| TC-02 | Placed status visible to customer and staff | Order created | 1. View order as customer. 2. View order as staff. | Both views show `Placed`. | Story, A7 |

## 2. Happy-path transitions

| ID | Title | Preconditions | Steps | Expected result | AC |
|---|---|---|---|---|---|
| TC-03 | Placed → Paid | Order in Placed | 1. Record a payment. 2. Read status. | Status is `Paid`. No error. | AC-1 |
| TC-04 | Paid → Shipped | Order in Paid | 1. Mark as shipped. 2. Read status. | Status is `Shipped`. No error. | AC-2 |
| TC-05 | Shipped → Delivered | Order in Shipped | 1. Confirm delivery. 2. Read status. | Status is `Delivered`. No error. | AC-3 |
| TC-06 | Full lifecycle end-to-end | New order | 1. Record payment. 2. Mark shipped. 3. Confirm delivery. Read status after each step. | Statuses in order: `Paid`, `Shipped`, `Delivered`. | AC-1–3 |
| TC-07 | Placed → Cancelled | Order in Placed | 1. Cancel the order. 2. Read status. | Status is `Cancelled`. No error. | AC-4 |
| TC-08 | Paid → Cancelled | Order in Paid | 1. Cancel the order. 2. Read status. | Status is `Cancelled`. No error. | AC-4 |
| TC-09 | Each status change visible to customer and staff | Order in Placed | 1. After each transition in TC-06, view order as customer and as staff. | Both views show the current status after every step. | Story, A7 |

## 3. Cancelling a Shipped order (AC-5)

| ID | Title | Preconditions | Steps | Expected result | AC |
|---|---|---|---|---|---|
| TC-10 | Cancel Shipped order is refused | Order in Shipped | 1. Attempt to cancel. | Request is refused. | AC-5 |
| TC-11 | Refusal message text is exact | Order in Shipped | 1. Attempt to cancel. 2. Capture error message. | Message is exactly `Shipped orders cannot be cancelled.` (case, wording, trailing period). | AC-5, A5 |
| TC-12 | Status unchanged after refused cancel | Order in Shipped | 1. Attempt to cancel. 2. Read status. | Status is still `Shipped`. | AC-5, A4 |
| TC-13 | Shipped order can still be delivered after refused cancel | Order in Shipped | 1. Attempt to cancel (refused). 2. Confirm delivery. | Status is `Delivered`. The refused cancel has no side effects. | AC-5, AC-3 |
| TC-14 | Repeated cancel attempts on Shipped order | Order in Shipped | 1. Attempt to cancel three times. | Each attempt refused with the same message; status remains `Shipped`. | AC-5 |

## 4. Invalid / out-of-order transitions (negative)

Each row: perform the action on an order in the given status, then read status. Expected: action refused, status unchanged (A2, A3, A4, A6).

| ID | Starting status | Action | Expected result |
|---|---|---|---|
| TC-15 | Placed | Mark shipped | Refused; status `Placed`. |
| TC-16 | Placed | Confirm delivery | Refused; status `Placed`. |
| TC-17 | Paid | Record payment (again) | Refused; status `Paid`. |
| TC-18 | Paid | Confirm delivery | Refused; status `Paid`. |
| TC-19 | Shipped | Record payment | Refused; status `Shipped`. |
| TC-20 | Shipped | Mark shipped (again) | Refused; status `Shipped`. |
| TC-21 | Delivered | Record payment | Refused; status `Delivered`. |
| TC-22 | Delivered | Mark shipped | Refused; status `Delivered`. |
| TC-23 | Delivered | Confirm delivery (again) | Refused; status `Delivered`. |
| TC-24 | Delivered | Cancel | Refused; status `Delivered`. |
| TC-25 | Cancelled | Record payment | Refused; status `Cancelled`. |
| TC-26 | Cancelled | Mark shipped | Refused; status `Cancelled`. |
| TC-27 | Cancelled | Confirm delivery | Refused; status `Cancelled`. |
| TC-28 | Cancelled | Cancel (again) | Refused; status `Cancelled`. |
| TC-29 | Any | Refused transition returns an error | For TC-15–28, an error is returned (not a silent no-op or success response). |
| TC-30 | Shipped | Cancel returns a different message than other refusals | The AC-5 message is used only for the Shipped→Cancel case. Other refused transitions must not reuse the text `Shipped orders cannot be cancelled.` |

## 5. Transition matrix (coverage check)

Rows = current status, columns = action. ✅ = allowed (new status), ❌ = refused.

| From \ Action | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| Placed | ✅ Paid (TC-03) | ❌ (TC-15) | ❌ (TC-16) | ✅ Cancelled (TC-07) |
| Paid | ❌ (TC-17) | ✅ Shipped (TC-04) | ❌ (TC-18) | ✅ Cancelled (TC-08) |
| Shipped | ❌ (TC-19) | ❌ (TC-20) | ✅ Delivered (TC-05) | ❌ AC-5 msg (TC-10–12) |
| Delivered | ❌ (TC-21) | ❌ (TC-22) | ❌ (TC-23) | ❌ (TC-24) |
| Cancelled | ❌ (TC-25) | ❌ (TC-26) | ❌ (TC-27) | ❌ (TC-28) |

All 20 cells are covered.

## 6. Robustness and edge cases

| ID | Title | Preconditions | Steps | Expected result | Notes |
|---|---|---|---|---|---|
| TC-31 | Status persists across reload | Order in Paid | 1. Reload page / re-fetch order from a fresh session. | Status is `Paid`. | A7 |
| TC-32 | Transition on non-existent order | None | 1. Record payment for an order ID that does not exist. | Refused with a not-found error; no order is created. | |
| TC-33 | Concurrent cancel and ship on a Paid order | Order in Paid | 1. Send cancel and mark-shipped at the same time. 2. Read status. | Exactly one succeeds. Final status is either `Shipped` or `Cancelled`, never both applied, never corrupted. The losing request is refused. | Race condition |
| TC-34 | Concurrent duplicate payment on a Placed order | Order in Placed | 1. Send two record-payment requests simultaneously. | Status is `Paid`. One request succeeds, the other is refused (or returns the already-Paid state without double-applying). | A6 |
| TC-35 | Transitions on one order do not affect another | Two orders A (Placed) and B (Placed) | 1. Record payment on A. 2. Read status of B. | A is `Paid`; B is still `Placed`. | Isolation |
| TC-36 | Status value is from the fixed set only | Any order, any transition | 1. After every transition in sections 2–4, inspect the stored status value. | Value is always one of Placed, Paid, Shipped, Delivered, Cancelled. No empty, null or other value. | A1 |
| TC-37 | Status not writable directly | Order in Placed | 1. Attempt to set status directly to `Delivered` (e.g. via a generic update endpoint or edit form) without going through the transition actions. | Refused, or field ignored. Status is still `Placed`. | Guards the "fixed set of statuses" intent |
| TC-38 | Status history / audit (if present) | Order in Placed | 1. Perform Placed→Paid→Shipped→Delivered. 2. View history. | Each transition is recorded in order with a timestamp. | Only applicable if the system keeps a history; otherwise mark N/A |

## 7. Out of scope / open points

- Whether a cancelled Paid order triggers a refund is not covered by this story; not tested here.
- Exact error text for refusals other than AC-5 is unspecified. TC-15–28 assert refusal and unchanged status only. Recommend the product owner define the messages.
- Whether Delivered orders can be returned or reopened is not in the story and is assumed not allowed (A3).
- Permissions (who may perform each transition) are not specified; all tests assume an authorised store operator.
