# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Standard shipping is the default shipping method
- Members are authenticated users with verified member status
- Non-members are either anonymous or unregistered users
- Subtotal calculation excludes taxes and shipping fees
- Order subtotal can include decimal values (cents)
- Both members and non-members can select either standard or express shipping
- Shipping is calculated per order (not per item)

---

## AC-1: Standard Shipping Fee for Non-Members

| Test Case ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| SHIP-9-AC1-001 | Standard shipping free when subtotal is $50.00 or more (non-member) | Non-member user; Standard shipping selected | Add items totaling $50.00; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC1-002 | Standard shipping free when subtotal exceeds $50.00 (non-member) | Non-member user; Standard shipping selected | Add items totaling $75.50; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC1-003 | Standard shipping costs $5.99 when subtotal is $49.99 (non-member) | Non-member user; Standard shipping selected | Add items totaling $49.99; Proceed to checkout | Standard shipping fee displays as $5.99 |
| SHIP-9-AC1-004 | Standard shipping costs $5.99 when subtotal is below $50.00 (non-member) | Non-member user; Standard shipping selected | Add items totaling $25.00; Proceed to checkout | Standard shipping fee displays as $5.99 |
| SHIP-9-AC1-005 | Standard shipping costs $5.99 when subtotal is $0.01 (non-member) | Non-member user; Standard shipping selected | Add items totaling $0.01; Proceed to checkout | Standard shipping fee displays as $5.99 |
| SHIP-9-AC1-006 | Shipping fee boundary condition at exactly $50.00 | Non-member user; Standard shipping selected | Add items totaling exactly $50.00; Proceed to checkout | Standard shipping fee displays as $0.00 |

---

## AC-2: Standard Shipping Fee for Members

| Test Case ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| SHIP-9-AC2-001 | Standard shipping free for members at $0.01 subtotal | Member user authenticated; Standard shipping selected | Add items totaling $0.01; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC2-002 | Standard shipping free for members at $49.99 subtotal | Member user authenticated; Standard shipping selected | Add items totaling $49.99; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC2-003 | Standard shipping free for members at $50.00 subtotal | Member user authenticated; Standard shipping selected | Add items totaling $50.00; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC2-004 | Standard shipping free for members at high subtotal | Member user authenticated; Standard shipping selected | Add items totaling $500.00; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC2-005 | Member status verified before applying free shipping | Member user logs in after adding items (non-member session) | Add items as non-member ($40.00), then authenticate as member; Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-AC2-006 | Member loses free shipping after logout | Member user adds items and logs out; Standard shipping selected | Add items as member, logout, proceed to checkout | Standard shipping fee displays as $5.99 |

---

## AC-3: Express Shipping Fee

| Test Case ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| SHIP-9-AC3-001 | Express shipping costs $12.99 for non-members | Non-member user; Express shipping selected | Add items; Select express shipping; Proceed to checkout | Express shipping fee displays as $12.99 |
| SHIP-9-AC3-002 | Express shipping costs $12.99 regardless of subtotal (non-member) | Non-member user; Express shipping selected | Add items totaling $0.01; Select express shipping; Proceed to checkout | Express shipping fee displays as $12.99 |
| SHIP-9-AC3-003 | Express shipping costs $12.99 for high subtotal (non-member) | Non-member user; Express shipping selected | Add items totaling $200.00; Select express shipping; Proceed to checkout | Express shipping fee displays as $12.99 |
| SHIP-9-AC3-004 | Express shipping costs $7.99 for members | Member user authenticated; Express shipping selected | Add items; Select express shipping; Proceed to checkout | Express shipping fee displays as $7.99 |
| SHIP-9-AC3-005 | Express shipping costs $7.99 for members at any subtotal | Member user authenticated; Express shipping selected | Add items totaling $0.01; Select express shipping; Proceed to checkout | Express shipping fee displays as $7.99 |
| SHIP-9-AC3-006 | Express shipping costs $7.99 for members at high subtotal | Member user authenticated; Express shipping selected | Add items totaling $300.00; Select express shipping; Proceed to checkout | Express shipping fee displays as $7.99 |

---

## Integration & Edge Cases

| Test Case ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| SHIP-9-INT-001 | Shipping fee updates when items added/removed | Non-member; Standard shipping selected; Initial subtotal $40.00 | Add item costing $15.00 to reach $55.00; Proceed to checkout | Shipping fee updates from $5.99 to $0.00 |
| SHIP-9-INT-002 | Shipping fee updates when items removed below threshold | Non-member; Standard shipping selected; Initial subtotal $60.00 | Remove item costing $15.00 to reach $45.00; Proceed to checkout | Shipping fee updates from $0.00 to $5.99 |
| SHIP-9-INT-003 | Correct fee displayed when switching between standard and express (non-member) | Non-member user | Add items ($30.00), select standard shipping, then select express shipping | Express fee ($12.99) displays; switching back shows standard fee ($5.99) |
| SHIP-9-INT-004 | Correct fee displayed when switching between standard and express (member) | Member user authenticated | Add items ($30.00), select standard shipping, then select express shipping | Standard shows $0.00; Express shows $7.99 |
| SHIP-9-INT-005 | Shipping fee persists through checkout flow | Non-member; Standard shipping; $60.00 subtotal | Select shipping; Proceed through billing address; Review order summary | Shipping fee remains $0.00 on review page |
| SHIP-9-INT-006 | Correct total calculated with shipping | Non-member; Standard shipping; $40.00 subtotal | Proceed to checkout review | Order total displays as $45.99 (subtotal + shipping) |
| SHIP-9-INT-007 | Correct total calculated for member with standard shipping | Member authenticated; Standard shipping; $40.00 subtotal | Proceed to checkout review | Order total displays as $40.00 (subtotal only) |
| SHIP-9-INT-008 | Correct total calculated for member with express shipping | Member authenticated; Express shipping; $40.00 subtotal | Proceed to checkout review | Order total displays as $47.99 (subtotal + express fee) |
| SHIP-9-EDG-001 | Shipping calculated correctly with fractional cents | Non-member; Standard shipping; $50.01 subtotal | Proceed to checkout | Standard shipping fee displays as $0.00 |
| SHIP-9-EDG-002 | Shipping calculated correctly just below threshold | Non-member; Standard shipping; $49.98 subtotal | Proceed to checkout | Standard shipping fee displays as $5.99 |
| SHIP-9-EDG-003 | Empty cart behavior | Non-member user; Standard shipping selected | Attempt to proceed to checkout with empty cart | Shipping fee not displayed; error message or disabled checkout button |
