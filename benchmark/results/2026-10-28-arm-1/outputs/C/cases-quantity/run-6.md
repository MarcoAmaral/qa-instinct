# Test Cases: Change the Quantity of an Item in the Cart (CART-12)

## TC-1: Accept valid quantity within range (1-20)

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 1 |
| **Steps** | 1. Select the quantity field<br>2. Enter "5"<br>3. Press Enter or click outside the field |
| **Expected Result** | Quantity updates to 5; item remains in cart; no error message |

## TC-2: Accept quantity at lower boundary

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "1" |
| **Expected Result** | Quantity updates to 1; item remains in cart |

## TC-3: Accept quantity at upper boundary

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "20" |
| **Expected Result** | Quantity updates to 20; item remains in cart |

## TC-4: Reject quantity of 0 with confirmation dialog

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "0"<br>3. Press Enter |
| **Expected Result** | Dialog appears with message "Remove this item?"; item quantity shows 5 (unchanged) |

## TC-5: Remove item when shopper confirms removal

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item; "Remove this item?" confirmation dialog is open |
| **Steps** | 1. Select **Confirm** or **Yes** button in the dialog |
| **Expected Result** | Item is removed from cart; cart displays without this item; confirmation dialog closes |

## TC-6: Keep item when shopper cancels removal

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5; "Remove this item?" confirmation dialog is open |
| **Steps** | 1. Select **Cancel** or **No** button in the dialog |
| **Expected Result** | Dialog closes; item remains in cart with quantity 5 (unchanged) |

## TC-7: Reject quantity above 20

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "21" |
| **Expected Result** | Error message displays: "You can buy at most 20 of this item."; quantity remains 5 |

## TC-8: Reject high quantity above 20

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 10 |
| **Steps** | 1. Select the quantity field<br>2. Enter "100" |
| **Expected Result** | Error message displays: "You can buy at most 20 of this item."; quantity remains 10 |

## TC-9: Reject decimal quantity

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "5.5" |
| **Expected Result** | Either: (a) field does not accept decimal input, OR (b) error message appears; quantity remains 5 |
| **Assumption** | Quantity field accepts only whole numbers; decimals are rejected or stripped |

## TC-10: Reject negative quantity

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "-5" |
| **Expected Result** | Either: (a) field does not accept negative input, OR (b) error message appears; quantity remains 5 |
| **Assumption** | Quantity field rejects negative values |

## TC-11: Reject non-numeric input

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Enter "abc" |
| **Expected Result** | Either: (a) field does not accept text input, OR (b) error message appears; quantity remains 5 |
| **Assumption** | Quantity field accepts only numeric input |

## TC-12: Handle empty quantity field

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item with quantity 5 |
| **Steps** | 1. Select the quantity field<br>2. Clear the field (delete all content)<br>3. Press Enter or click outside the field |
| **Expected Result** | Quantity reverts to 5 or shows a validation error; field is not left blank |
| **Assumption** | Empty quantity field is invalid and is either rejected or auto-reverts |

## TC-13: Update persists across page navigation

| Field | Value |
| --- | --- |
| **Precondition** | Cart contains 1 item; quantity successfully changed to 15 |
| **Steps** | 1. Navigate away from the cart page (e.g., browse products)<br>2. Return to the cart |
| **Expected Result** | Item quantity displays as 15; change has persisted |
| **Assumption** | Quantity changes are saved immediately or before navigation |

## Test Coverage Summary

- **AC-1 (Accept 1-20):** TC-1, TC-2, TC-3, TC-9, TC-11
- **AC-2 (Remove with confirmation):** TC-4, TC-5, TC-6
- **AC-3 (Reject 20+, keep previous):** TC-7, TC-8
- **Boundary & Edge Cases:** TC-9, TC-10, TC-11, TC-12
- **Persistence:** TC-13
