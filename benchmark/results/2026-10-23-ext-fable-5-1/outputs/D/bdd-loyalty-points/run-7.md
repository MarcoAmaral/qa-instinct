# LOY-3 Loyalty points — BDD scenarios

## AC quality check (SMART)

| AC | Verdict | Note |
| --- | --- | --- |
| AC-1 | Testable | Rounding rule is clear (floor of subtotal). Silent on refunds, cancellations and whether discounts or tax affect the subtotal. |
| AC-2 | Testable, one gap | Boundaries are explicit (500, 2,000). Silent on whether tier is based on current balance or lifetime points, and on downgrade after redemption. |
| AC-3 | Testable | Exact message given. Silent on the value of a point, the redemption step, and redeeming zero or negative points. |
| AC-4 | **Not testable as written** | "Fast" is not measurable. Rewrite proposed below; scenario tagged `@candidate` until the product owner confirms a figure. |

## Assumptions

- A-1: "Subtotal" is the sum of line items before discounts, tax and shipping. Points are computed on the amount the member actually paid for items, after any tier discount is applied. The ticket says "subtotal", so the base is the pre-discount figure; this needs confirming.
- A-2: Tier is derived from the member's **current points balance**, so redeeming points can lower the tier. Lifetime points would be the alternative; the story says "tier is Basic below 500 points", which reads as balance.
- A-3: Points are credited when the order is placed, not when it ships. Cancelled or refunded orders are out of scope.
- A-4: 100 points redeem $1 of discount, applied at checkout, after the tier discount. Any rate works for the scenarios; only the insufficient-balance rule is in the ticket.
- A-5: Tier discount applies to the order subtotal, is shown on the checkout page, and is applied to every order, including the order that crosses the threshold only on the **next** order (the tier at the moment of checkout is used).
- A-6: AC-4 rewrite proposed for the product owner: "The points page renders the balance and tier within 2 seconds at the 95th percentile on the reference device and network."

## Feature file

```gherkin
@loyalty @loy-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member
    And the loyalty programme is active

  # ---------- AC-1: earning ----------

  @smoke @p0 @earn
  Scenario: Placing an order earns one point per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance is 24
    And the order confirmation shows "You earned 24 points"

  @regression @p1 @earn
  Scenario Outline: Points earned are the whole dollars of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 1.01     | 1      |
      | 24.99    | 24     |
      | 25.00    | 25     |
      | 499.99   | 499    |
      | 1999.99  | 1999   |

  # Added by QA, the ticket does not say whether points accumulate or replace
  @regression @p1 @earn
  Scenario: Points from a new order are added to the existing balance
    Given my points balance is 100
    When I place an order with a subtotal of $50.00
    Then my points balance is 150

  # Added by QA, the ticket is silent on whether the base is before or after the tier discount (assumption A-1)
  @regression @p2 @earn @candidate
  Scenario: Points are calculated on the subtotal before the tier discount
    Given my points balance is 600
    And my tier is "Silver"
    When I place an order with a subtotal of $100.00
    Then the tier discount applied is $5.00
    And my points balance is 700

  # ---------- AC-2: tiers ----------

  @smoke @p0 @tier
  Scenario Outline: Tier is determined by the points balance
    Given my points balance is <balance>
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 501     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 2001    | Gold   |
      | 50000   | Gold   |

  @smoke @p0 @tier @checkout
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    And my tier is "<tier>"
    When I go to checkout with an order subtotal of $100.00
    Then the checkout page shows a tier discount of $<discount>
    And the order total before tax and shipping is $<total>

    Examples:
      | balance | tier   | discount | total  |
      | 499     | Basic  | 0.00     | 100.00 |
      | 500     | Silver | 5.00     | 95.00  |
      | 1999    | Silver | 5.00     | 95.00  |
      | 2000    | Gold   | 10.00    | 90.00  |

  @regression @p1 @tier
  Scenario: Crossing a tier threshold upgrades the member after the order
    Given my points balance is 480
    And my tier is "Basic"
    When I place an order with a subtotal of $30.00
    Then my points balance is 510
    And my tier is shown as "Silver"

  # Added by QA, the order that crosses the threshold must not get the new discount retroactively (assumption A-5)
  @regression @p1 @tier @checkout
  Scenario: The order that crosses a threshold is discounted at the tier held at checkout
    Given my points balance is 480
    And my tier is "Basic"
    When I go to checkout with an order subtotal of $30.00
    Then the checkout page shows a tier discount of $0.00
    When I place the order
    Then my tier is shown as "Silver"

  # Added by QA, the ticket is silent on downgrade after redemption (assumption A-2)
  @regression @p1 @tier @redeem @candidate
  Scenario: Redeeming points below a threshold downgrades the tier
    Given my points balance is 2000
    And my tier is "Gold"
    When I redeem 100 points
    Then my points balance is 1900
    And my tier is shown as "Silver"

  # Added by QA, the ticket does not say how discount and points interact when both apply (assumption A-4)
  @regression @p2 @checkout @redeem @candidate
  Scenario: Tier discount and redeemed points are both applied at checkout
    Given my points balance is 700
    And my tier is "Silver"
    When I go to checkout with an order subtotal of $100.00
    And I redeem 200 points
    Then the checkout page shows a tier discount of $5.00
    And the checkout page shows a points discount of $2.00
    And the order total before tax and shipping is $93.00

  # ---------- AC-3: redeeming ----------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    When I try to redeem 101 points
    Then I see the message "You don't have enough points."
    And my points balance is still 100
    And no points discount is applied to the order

  @smoke @p0 @redeem
  Scenario: Redeeming exactly the balance succeeds
    Given my points balance is 100
    When I redeem 100 points
    Then my points balance is 0
    And a points discount is applied to the order

  @regression @p1 @redeem
  Scenario Outline: Redemption is accepted or rejected at the balance boundary
    Given my points balance is <balance>
    When I try to redeem <requested> points
    Then the redemption is "<outcome>"
    And my points balance is <balance_after>

    Examples:
      | balance | requested | outcome  | balance_after |
      | 100     | 99        | accepted | 1             |
      | 100     | 100       | accepted | 0             |
      | 100     | 101       | rejected | 100           |
      | 0       | 1         | rejected | 0             |

  # Added by QA, the ticket does not define redeeming zero or a negative amount
  @regression @p2 @redeem @candidate
  Scenario Outline: Non-positive redemption amounts are rejected without changing the balance
    Given my points balance is 100
    When I try to redeem <requested> points
    Then I see a validation message
    And my points balance is still 100

    Examples:
      | requested |
      | 0         |
      | -1        |

  # Added by QA, a double submit must not redeem twice (assumption A-4)
  @regression @p1 @redeem
  Scenario: Submitting the same redemption twice redeems only once
    Given my points balance is 100
    When I redeem 60 points
    And I submit the same redemption again
    Then I see the message "You don't have enough points."
    And my points balance is 40

  # ---------- AC-4: points page ----------

  @smoke @p1 @points-page
  Scenario: The points page shows the balance and tier
    Given my points balance is 750
    When I open the points page
    Then the page shows a balance of 750 points
    And my tier is shown as "Silver"

  # Added by QA, AC-4 "should load fast" is not measurable; threshold per assumption A-6, to be confirmed by the product owner
  @regression @p2 @points-page @performance @candidate
  Scenario: The points page loads within the agreed time
    Given my points balance is 750
    When I open the points page
    Then the balance and tier are visible within 2 seconds

  # Added by QA, members without any order history must still see a valid page
  @regression @p2 @points-page
  Scenario: A new member sees a zero balance and Basic tier
    Given I have never placed an order
    When I open the points page
    Then the page shows a balance of 0 points
    And my tier is shown as "Basic"
```

## Step definitions (Playwright + Cucumber, TypeScript)

Test IDs are proposed and should be confirmed with the developers before implementation.

```typescript
// features/loyalty.feature -> steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

Given("I am signed in as a loyalty programme member", async function () {
  await this.api.loginAsMember(process.env.TEST_MEMBER_EMAIL!);
});

Given("the loyalty programme is active", async function () {
  await this.api.setFeatureFlag("loyalty", true);
});

Given("my points balance is {int}", async function (balance: number) {
  await this.api.setPointsBalance(this.memberId, balance);
});

Given("my tier is {string}", async function (tier: string) {
  const actual = await this.api.getTier(this.memberId);
  expect(actual).toBe(tier);
});

When("I place an order with a subtotal of ${float}", async function (subtotal: number) {
  await this.api.placeOrder(this.memberId, { subtotal });
});

When("I go to checkout with an order subtotal of ${float}", async function (subtotal: number) {
  await this.api.createCart(this.memberId, { subtotal });
  await this.page.goto("/checkout");
});

When("I place the order", async function () {
  await this.page.getByRole("button", { name: /place order/i }).click();
  await expect(this.page.getByTestId("order-confirmation")).toBeVisible();
});

When(/^I (?:try to )?redeem (-?\d+) points$/, async function (points: string) {
  await this.page.getByTestId("redeem-points-input").fill(points);
  await this.page.getByRole("button", { name: /redeem/i }).click();
});

When("I submit the same redemption again", async function () {
  await this.page.getByRole("button", { name: /redeem/i }).click();
});

When("I open the points page", async function () {
  this.navStart = Date.now();
  await this.page.goto("/account/points");
});

Then("my points balance is {int}", async function (expected: number) {
  await this.page.goto("/account/points");
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(expected));
});

Then("my points balance is still {int}", async function (expected: number) {
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(expected));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("points-tier")).toHaveText(tier);
});

Then("the order confirmation shows {string}", async function (text: string) {
  await expect(this.page.getByTestId("order-confirmation")).toContainText(text);
});

Then("the checkout page shows a tier discount of ${float}", async function (amount: number) {
  await expect(this.page.getByTestId("tier-discount")).toHaveText(`-$${amount.toFixed(2)}`);
});

Then("the tier discount applied is ${float}", async function (amount: number) {
  await expect(this.page.getByTestId("tier-discount")).toHaveText(`-$${amount.toFixed(2)}`);
});

Then("the checkout page shows a points discount of ${float}", async function (amount: number) {
  await expect(this.page.getByTestId("points-discount")).toHaveText(`-$${amount.toFixed(2)}`);
});

Then("the order total before tax and shipping is ${float}", async function (total: number) {
  await expect(this.page.getByTestId("order-subtotal-after-discounts")).toHaveText(`$${total.toFixed(2)}`);
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("I see a validation message", async function () {
  await expect(this.page.getByRole("alert")).toBeVisible();
});

Then("no points discount is applied to the order", async function () {
  await expect(this.page.getByTestId("points-discount")).not.toBeVisible();
});

Then("a points discount is applied to the order", async function () {
  await expect(this.page.getByTestId("points-discount")).toBeVisible();
});

Then("the redemption is {string}", async function (outcome: string) {
  if (outcome === "accepted") {
    await expect(this.page.getByTestId("points-discount")).toBeVisible();
  } else {
    await expect(this.page.getByRole("alert")).toHaveText("You don't have enough points.");
  }
});

Then("the page shows a balance of {int} points", async function (balance: number) {
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(balance));
});

Then("the balance and tier are visible within {int} seconds", async function (seconds: number) {
  await expect(this.page.getByTestId("points-balance")).toBeVisible({ timeout: seconds * 1000 });
  await expect(this.page.getByTestId("points-tier")).toBeVisible({ timeout: seconds * 1000 });
  expect(Date.now() - this.navStart).toBeLessThanOrEqual(seconds * 1000);
});

Given("I have never placed an order", async function () {
  await this.api.resetMember(this.memberId);
});
```

## Open points for the Three Amigos

1. Confirm tier basis: current balance (assumed) or lifetime points. Changes the downgrade scenario.
2. Confirm the point-earning base when a tier discount applies: pre-discount subtotal (assumed) or amount paid.
3. Confirm the redemption rate and where redeemed points are applied in the price stack.
4. Replace AC-4 with a measurable target; the 2-second figure is a placeholder.
5. Decide whether refunds and cancellations reverse earned points. Not covered here.

## Rules not applied

The `context-discovery` rule could not be applied: the `qa-rules` skill is not installed and the working directory contains no code, so no scenario was verified against an implementation. All scenarios are derived from the ticket text and the stated assumptions.
