# Test Cases for CART-12: Change Quantity of Item in Cart

## AC-1: Quantity Field Accepts Whole Numbers 1-20

| Test Case ID | Scenario | Given | When | Then | Expected Result |
|---|---|---|---|---|---|
| TC-AC1-001 | Set valid minimum quantity | Item in cart with quantity 5 | User enters "1" in quantity field | System updates cart | Quantity changes to 1, item remains in cart |
| TC-AC1-002 | Set valid maximum quantity | Item in cart with quantity 5 | User enters "20" in quantity field | System updates cart | Quantity changes to 20, item remains in cart |
| TC-AC1-003 | Set valid mid-range quantity | Item in cart with quantity 5 | User enters "10" in quantity field | System updates cart | Quantity changes to 10, item remains in cart |
| TC-AC1-004 | Reject decimal quantity | Item in cart with quantity 5 | User enters "5.5" in quantity field | Field validation runs | Decimal is rejected or rounded, previous quantity retained |
| TC-AC1-005 | Reject negative quantity | Item in cart with quantity 5 | User enters "-5" in quantity field | Field validation runs | Negative value is rejected, previous quantity retained |
| TC-AC1-006 | Reject non-numeric input | Item in cart with quantity 5 | User enters "ABC" in quantity field | Field validation runs | Non-numeric input is rejected, previous quantity retained |
| TC-AC1-007 | Reject empty quantity | Item in cart with quantity 5 | User clears quantity field and leaves focus | Field validation runs | Empty field is rejected, previous quantity retained |

## AC-2: Setting Quantity to 0 Triggers Confirmation

| Test Case ID | Scenario | Given | When | Then | Expected Result |
|---|---|---|---|---|---|
| TC-AC2-001 | Confirm item removal | Item in cart with quantity 5 | User enters "0" and clicks "Remove this item?" confirm button | Item removal is confirmed | Item is removed from cart, cart total updates |
| TC-AC2-002 | Cancel item removal | Item in cart with quantity 5 | User enters "0", sees confirmation dialog, clicks "Cancel" | Cancellation occurs | Item remains in cart with previous quantity (5) |
| TC-AC2-003 | Dismiss removal dialog | Item in cart with quantity 5 | User enters "0", sees confirmation dialog, clicks X or outside | Dialog closes without action | Item remains in cart with previous quantity (5) |
| TC-AC2-004 | Confirmation dialog appears immediately | Item in cart with quantity 1 | User changes quantity to "0" | Dialog appears before processing | "Remove this item?" message displays |
| TC-AC2-005 | Remove last item from cart | Only item in cart with quantity 2 | User enters "0" and confirms removal | Item is removed | Cart becomes empty, appropriate empty cart message shows |
| TC-AC2-006 | Remove middle item from cart | 3 items in cart, changing second item to 0 | User enters "0" and confirms removal | Item is removed | Other items remain, cart total updates correctly |

## AC-3: Quantity Above 20 Shows Error Message

| Test Case ID | Scenario | Given | When | Then | Expected Result |
|---|---|---|---|---|---|
| TC-AC3-001 | Reject quantity 21 | Item in cart with quantity 5 | User enters "21" in quantity field | Validation rejects value | Error message "You can buy at most 20 of this item." displays, quantity stays 5 |
| TC-AC3-002 | Reject high quantity | Item in cart with quantity 8 | User enters "100" in quantity field | Validation rejects value | Error message displays, quantity stays 8 |
| TC-AC3-003 | Error message is visible | Item in cart with quantity 5 | User enters "25" in quantity field | Error appears | Message is clearly visible near quantity field |
| TC-AC3-004 | Quantity reverts after error | Item in cart with quantity 12 | User enters "30", error shows, user re-focuses field | Reversion occurs | Quantity displays original value (12) |
| TC-AC3-005 | Multiple rejection attempts | Item in cart with quantity 7 | User enters "50", error shows; user enters "99" | Each attempt shows error | Previous quantity (7) maintained after each rejection |
| TC-AC3-006 | Accept quantity after rejection attempt | Item in cart with quantity 5 | User enters "30" (rejected), then enters "15" | Valid quantity entered | Quantity updates to 15, no error message |

## Additional Edge Cases

| Test Case ID | Scenario | Given | When | Then | Expected Result |
|---|---|---|---|---|---|
| TC-EDGE-001 | Rapid quantity changes | Item in cart with quantity 5 | User quickly changes to 10, then 15, then 8 | All changes process sequentially | Final quantity is 8, cart updates correctly |
| TC-EDGE-002 | Leading zeros | Item in cart with quantity 5 | User enters "007" in quantity field | System processes input | Either treats as 7 or rejects, behavior documented |
| TC-EDGE-003 | Quantity change with network delay | Item in cart with quantity 5 | User enters "12" and network latency occurs | Loading state appears | Quantity updates once confirmed, no duplicate submissions |
| TC-EDGE-004 | Accessibility - keyboard navigation | Item in cart with quantity 5 | User tabs to quantity field, enters value, presses Enter | Field accepts keyboard input | Quantity updates as with mouse input |
| TC-EDGE-005 | Accessibility - screen reader | Item in cart with quantity 5 | Screen reader user attempts to change quantity | Field is properly labeled | Error messages and confirmations are read aloud |

## Assumptions

1. **Testing Scope**: Test cases cover both unit testing (validation logic) and integration testing (cart updates)
2. **Error Message Display**: Error messages appear inline near the quantity field and persist until corrected
3. **Confirmation Dialog**: A modal or inline confirmation is used for zero-quantity removal
4. **Cart Updates**: Changes to quantity immediately reflect in cart totals and item pricing
5. **Quantity Field Input**: Assumes an HTML input field or similar control where users type or increment/decrement via buttons
6. **Previous Quantity Retention**: "Previous quantity" refers to the quantity before the invalid entry attempt
7. **No Auto-Quantity-Increment**: Assumes no buttons for +/- incrementing separate from the text field; tests focus on direct text input
