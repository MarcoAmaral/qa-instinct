# Test Cases: Order Status Changes (Story ORD-4)

**Assumptions:**
- Orders can only transition through the sequence: Placed → Paid → Shipped → Delivered (or Cancelled at any point before Shipped).
- System rejects invalid transitions with the specified error message for AC-5.
- Store operators have permission to perform all status-change operations.
- Timestamps are recorded for each transition.

---

## Setup

| Precondition | Action |
| --- | --- |
| New order in database | System creates order with status `Placed` |

---

## Test Cases

### TC-1: Order created with Placed status
| Step | Expected Result |
| --- | --- |
| Create a new order | Order status is `Placed` |

---

### TC-2: AC-1 — Record payment on Placed order
| Step | Expected Result |
| --- | --- |
| Order status is `Placed` | Initial state valid |
| Record payment | Order status changes to `Paid` |
| Query order again | Status persists as `Paid` |

---

### TC-3: AC-1 — Record payment on non-Placed order (negative test)
| Step | Expected Result |
| --- | --- |
| Order status is `Shipped` | Initial state invalid for payment recording |
| Attempt to record payment | Operation rejected or error returned |

---

### TC-4: AC-2 — Mark Paid order as shipped
| Step | Expected Result |
| --- | --- |
| Order status is `Paid` | Initial state valid |
| Mark as shipped | Order status changes to `Shipped` |
| Query order again | Status persists as `Shipped` |

---

### TC-5: AC-2 — Mark non-Paid order as shipped (negative test)
| Step | Expected Result |
| --- | --- |
| Order status is `Placed` | Initial state invalid for shipping |
| Attempt to mark as shipped | Operation rejected or error returned |

---

### TC-6: AC-3 — Confirm delivery of Shipped order
| Step | Expected Result |
| --- | --- |
| Order status is `Shipped` | Initial state valid |
| Confirm delivery | Order status changes to `Delivered` |
| Query order again | Status persists as `Delivered` |

---

### TC-7: AC-3 — Confirm delivery of non-Shipped order (negative test)
| Step | Expected Result |
| --- | --- |
| Order status is `Paid` | Initial state invalid for delivery confirmation |
| Attempt to confirm delivery | Operation rejected or error returned |

---

### TC-8: AC-4 — Cancel Placed order
| Step | Expected Result |
| --- | --- |
| Order status is `Placed` | Initial state valid |
| Cancel order | Order status changes to `Cancelled` |
| Query order again | Status persists as `Cancelled` |

---

### TC-9: AC-4 — Cancel Paid order
| Step | Expected Result |
| --- | --- |
| Order status is `Paid` | Initial state valid |
| Cancel order | Order status changes to `Cancelled` |
| Query order again | Status persists as `Cancelled` |

---

### TC-10: AC-5 — Attempt to cancel Shipped order
| Step | Expected Result |
| --- | --- |
| Order status is `Shipped` | Initial state invalid for cancellation |
| Attempt to cancel order | Operation rejected with error message: "Shipped orders cannot be cancelled." |
| Query order again | Status remains `Shipped` (unchanged) |

---

### TC-11: AC-5 — Attempt to cancel Delivered order
| Step | Expected Result |
| --- | --- |
| Order status is `Delivered` | Initial state invalid for cancellation |
| Attempt to cancel order | Operation rejected with error message or similar (assumed: no cancellation after Shipped) |
| Query order again | Status remains `Delivered` (unchanged) |

---

### TC-12: AC-4 — Attempt to cancel already Cancelled order (edge case)
| Step | Expected Result |
| --- | --- |
| Order status is `Cancelled` | Initial state is terminal |
| Attempt to cancel order again | Operation rejected or idempotent response |

---

### TC-13: Status transition audit trail
| Step | Expected Result |
| --- | --- |
| Order transitions: Placed → Paid → Shipped → Delivered | All transitions logged with timestamp and user |
| Retrieve order history | Each status and transition time is recorded |

---

## Assumptions Documented for Editor Review

1. **Terminal status assumption**: `Cancelled` and `Delivered` are terminal states (no further transitions possible).
2. **Error handling**: AC-5 specifies the exact error message for Shipped orders; behavior for Cancelled orders is assumed to follow the same rule.
3. **Permissions**: All test cases assume the operator has permission to perform the status-change operation.
4. **Idempotency**: Not specified; test cases assume operations fail rather than silently succeed on repeat attempts.
5. **Audit logging**: Not required by the story, but TC-13 assumes a system best practice of recording transitions.
