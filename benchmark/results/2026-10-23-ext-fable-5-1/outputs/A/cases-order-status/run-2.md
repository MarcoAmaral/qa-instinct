**Assumptions**
- Statuses are exactly: Placed, Paid, Shipped, Delivered, Cancelled. No other status exists.
- Delivered and Cancelled are terminal; no transition is allowed out of them.
- Transitions not listed in the ACs (e.g. shipping a Placed order, paying a Paid order) are refused. Error messages for those are unspecified, so tests only assert that the status is unchanged and the operation is rejected.
- Operations are atomic: a refused operation leaves the order exactly as it was.
- The "Shipped orders cannot be cancelled." message is matched exactly, including the trailing period.

**Test cases**

| ID | Covers | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Creation | None | Create a new order | Status is Placed |
| TC-02 | AC-1 | Order in Placed | Record a payment | Status is Paid |
| TC-03 | AC-2 | Order in Paid | Mark as shipped | Status is Shipped |
| TC-04 | AC-3 | Order in Shipped | Confirm delivery | Status is Delivered |
| TC-05 | AC-4 | Order in Placed | Cancel | Status is Cancelled |
| TC-06 | AC-4 | Order in Paid | Cancel | Status is Cancelled |
| TC-07 | AC-5 | Order in Shipped | Cancel | Refused with message "Shipped orders cannot be cancelled."; status remains Shipped |
| TC-08 | Happy path end to end | None | Create, pay, ship, deliver in sequence | Statuses observed in order: Placed, Paid, Shipped, Delivered |
| TC-09 | AC-1 negative | Order in Paid | Record a payment | Refused; status remains Paid |
| TC-10 | AC-1 negative | Order in Shipped | Record a payment | Refused; status remains Shipped |
| TC-11 | AC-1 negative | Order in Delivered | Record a payment | Refused; status remains Delivered |
| TC-12 | AC-1 negative | Order in Cancelled | Record a payment | Refused; status remains Cancelled |
| TC-13 | AC-2 negative | Order in Placed | Mark as shipped | Refused; status remains Placed |
| TC-14 | AC-2 negative | Order in Shipped | Mark as shipped | Refused; status remains Shipped |
| TC-15 | AC-2 negative | Order in Delivered | Mark as shipped | Refused; status remains Delivered |
| TC-16 | AC-2 negative | Order in Cancelled | Mark as shipped | Refused; status remains Cancelled |
| TC-17 | AC-3 negative | Order in Placed | Confirm delivery | Refused; status remains Placed |
| TC-18 | AC-3 negative | Order in Paid | Confirm delivery | Refused; status remains Paid |
| TC-19 | AC-3 negative | Order in Delivered | Confirm delivery | Refused; status remains Delivered |
| TC-20 | AC-3 negative | Order in Cancelled | Confirm delivery | Refused; status remains Cancelled |
| TC-21 | AC-4/AC-5 negative | Order in Delivered | Cancel | Refused; status remains Delivered |
| TC-22 | AC-4 negative | Order in Cancelled | Cancel | Refused; status remains Cancelled |
| TC-23 | AC-5 message exactness | Order in Shipped | Cancel | Message equals "Shipped orders cannot be cancelled." exactly, with no extra text |
| TC-24 | AC-5 then AC-3 | Order in Shipped | Cancel (refused), then confirm delivery | Cancellation refused; delivery succeeds; final status is Delivered |
| TC-25 | Terminal state | Order in Cancelled (from Placed) | Attempt pay, ship, deliver, cancel | All refused; status remains Cancelled |
| TC-26 | Terminal state | Order in Cancelled (from Paid) | Attempt pay, ship, deliver, cancel | All refused; status remains Cancelled |
| TC-27 | Isolation | Two orders A (Placed) and B (Paid) | Cancel A | A is Cancelled; B remains Paid |
| TC-28 | Persistence | Order in Paid | Reload the order from storage | Status is still Paid |

**Transition matrix used to derive TC-09 to TC-22** (rows are current status, columns are operations; ✓ is allowed, ✗ is refused):

| From | Pay | Ship | Deliver | Cancel |
|---|---|---|---|---|
| Placed | ✓ Paid | ✗ | ✗ | ✓ Cancelled |
| Paid | ✗ | ✓ Shipped | ✗ | ✓ Cancelled |
| Shipped | ✗ | ✗ | ✓ Delivered | ✗ (AC-5 message) |
| Delivered | ✗ | ✗ | ✗ | ✗ |
| Cancelled | ✗ | ✗ | ✗ | ✗ |

**Open points for the product owner**
- Error messages for refused transitions other than AC-5 are unspecified.
- Whether any status is reachable from Delivered or Cancelled (e.g. returns or reactivation) is unspecified; tests assume not.
