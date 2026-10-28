# LOY-3 Loyalty points — BDD scenarios

## Context and assumptions

The workspace is empty, so these scenarios are grounded in the ticket only, not in observed system behaviour. Every step is a specification to confirm in Three Amigos, not a verified fact.

| # | Assumption | Why it matters |
| --- | --- | --- |
| A1 | Points are credited when the order is placed, on the subtotal **before** tier discount, tax and shipping. | AC-1 says "subtotal" but not which one or when. |
| A2 | Points are floored to whole dollars ($0.99 earns 0). | Implied by the $24.99 example. |
| A3 | Tier is derived from the member's **current points balance**, so redeeming can lower the tier. | AC-2 reads literally this way. Lifetime points would be the alternative; flagged for PO. |
| A4 | Tier discount applies to the subtotal; the amount is rounded half-up to the cent. | 5% of $24.99 is $1.2495. |
| A5 | Redemption rate is 100 points = $1.00 off, applied after the tier discount; points are deducted when the order is placed. | AC-3 covers only the failure case. |
| A6 | Redeeming exactly the balance succeeds and leaves 0 points. | Boundary of AC-3. |
| A7 | AC-4 "load fast" is not measurable. Working target: the points page is interactive within 2 s at the 95th percentile on staging for a member with 1,000 points transactions. | Marked `@candidate` until the PO confirms the number. |

## AC quality check (SMART)

| AC | Verdict | Note |
| --- | --- | --- |
| AC-1 | Pass | Specific, measurable, has an example. |
| AC-2 | Partial | Thresholds are clear; "points" is ambiguous (balance vs lifetime, see A3); discount rounding undefined (A4). |
| AC-3 | Partial | Error path only; the success path and redemption rate are missing (A5, A6). |
| AC-4 | Fail | "Fast" is not measurable. Rewritten under A7. |

## Feature file

```gherkin
@loyalty
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------- AC-1: earning ----------

  @smoke @p0
  Scenario: Points are earned on the whole-dollar subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance is 24
    And the order confirmation shows "You earned 24 points"

  @regression @p1
  Scenario Outline: Points are floored to whole dollars
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 1.99     | 1      |
      | 24.99    | 24     |
      | 100.00   | 100    |

  # Added by QA, the ticket does not say which subtotal counts when a discount applies (A1)
  @regression @p1
  Scenario: Points are earned on the subtotal before the tier discount
    Given my points balance is 500
    And my tier is "Silver"
    When I place an order with a subtotal of $100.00
    Then the order total is $95.00
    And my points balance is 600

  # Added by QA, the ticket does not say whether earning is cumulative
  @regression @p1
  Scenario: Points from several orders accumulate
    Given my points balance is 10
    When I place an order with a subtotal of $20.00
    And I place an order with a subtotal of $30.00
    Then my points balance is 60

  # Added by QA, non-members are outside the story but share the checkout
  @regression @p2
  Scenario: A non-member earns no points
    Given I am signed in as a customer who is not a loyalty programme member
    When I place an order with a subtotal of $50.00
    Then no points are credited
    And the order confirmation does not mention points

  # ---------- AC-2: tiers ----------

  @smoke @p0
  Scenario Outline: Tier is determined by points balance
    Given my points balance is <points>
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples:
      | points | tier   |
      | 0      | Basic  |
      | 499    | Basic  |
      | 500    | Silver |
      | 1999   | Silver |
      | 2000   | Gold   |
      | 5000   | Gold   |

  @smoke @p0
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <points>
    When I place an order with a subtotal of $<subtotal>
    Then a tier discount of $<discount> is applied
    And the order total is $<total>

    Examples:
      | points | subtotal | discount | total |
      | 499    | 100.00   | 0.00     | 100.00 |
      | 500    | 100.00   | 5.00     | 95.00  |
      | 1999   | 24.99    | 1.25     | 23.74  |
      | 2000   | 100.00   | 10.00    | 90.00  |

  # Added by QA, the ticket does not say when a tier change takes effect
  @regression @p1
  Scenario: Crossing a tier threshold applies from the next order
    Given my points balance is 480
    When I place an order with a subtotal of $20.00
    Then no tier discount is applied to that order
    And my points balance is 500
    And my tier is shown as "Silver"
    When I place an order with a subtotal of $100.00
    Then a tier discount of $5.00 is applied

  # Added by QA, follows from A3 (tier based on balance); PO to confirm this is intended
  @regression @p1 @candidate
  Scenario: Redeeming points below a threshold lowers the tier
    Given my points balance is 500
    And my tier is "Silver"
    When I redeem 100 points on an order with a subtotal of $50.00
    Then my points balance is 400
    And my tier is shown as "Basic"

  # ---------- AC-3: redemption ----------

  # Added by QA, the ticket defines the failure path but not the success path (A5)
  @smoke @p0
  Scenario: Redeeming points within the balance reduces the order total
    Given my points balance is 300
    When I redeem 200 points on an order with a subtotal of $50.00
    Then the order total is $48.00
    And my points balance is 100

  @smoke @p0
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    When I try to redeem 101 points on an order with a subtotal of $50.00
    Then I see the message "You don't have enough points."
    And no points are redeemed
    And my points balance is 100
    And the order total is $50.00

  # Added by QA, boundary of AC-3 (A6)
  @regression @p1
  Scenario: Redeeming exactly the balance succeeds
    Given my points balance is 100
    When I redeem 100 points on an order with a subtotal of $50.00
    Then the order total is $49.00
    And my points balance is 0

  # Added by QA, the ticket is silent on zero and negative inputs
  @regression @p2
  Scenario Outline: Invalid redemption amounts are rejected without touching the balance
    Given my points balance is 100
    When I try to redeem "<amount>" points on an order with a subtotal of $50.00
    Then I see the message "<message>"
    And my points balance is 100

    Examples:
      | amount | message                               |
      | 0      | Enter at least 1 point to redeem      |
      | -5     | Enter at least 1 point to redeem      |
      | abc    | Enter a whole number of points        |

  # Added by QA, a cancelled order must not keep redeemed points
  @regression @p2
  Scenario: Points redeemed on a cancelled order are returned
    Given my points balance is 300
    And I redeemed 200 points on an order that is not yet shipped
    When that order is cancelled
    Then my points balance is 300

  # ---------- AC-4: points page ----------

  @smoke @p0
  Scenario: Points page shows balance, tier and history
    Given my points balance is 650
    And I have earned points on 3 orders
    When I open the points page
    Then I see a balance of 650 points
    And I see my tier "Silver"
    And I see 3 history entries with date, order number and points

  # Added by QA, AC-4 "load fast" rewritten as a measurable target (A7); number to be confirmed
  @nfr @p1 @candidate
  Scenario: Points page is interactive within the agreed time
    Given I have 1,000 points transactions
    When I open the points page
    Then the page is interactive within 2 seconds at the 95th percentile over 20 loads on staging
```

## Step definitions (Playwright + Cucumber, TypeScript)

Stack is not stated; Playwright with Cucumber is assumed. Selectors use `data-testid` values the team still has to agree.

```typescript
// steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

Given("I am signed in as a loyalty programme member", async function () {
  await this.api.createMember({ email: process.env.TEST_MEMBER_EMAIL! });
  await this.page.goto(process.env.BASE_URL!);
  await this.loginPage.login(process.env.TEST_MEMBER_EMAIL!, process.env.TEST_PASSWORD!);
});

Given("my points balance is {int}", async function (points: number) {
  await this.api.setPointsBalance(this.member.id, points);
});

When("I place an order with a subtotal of ${float}", async function (subtotal: number) {
  await this.checkoutPage.placeOrderWithSubtotal(subtotal);
});

When("I redeem {int} points on an order with a subtotal of ${float}", async function (points: number, subtotal: number) {
  await this.checkoutPage.addItemsForSubtotal(subtotal);
  await this.page.getByTestId("redeem-points-input").fill(String(points));
  await this.page.getByRole("button", { name: /apply points/i }).click();
  await this.checkoutPage.placeOrder();
});

When("I try to redeem {int} points on an order with a subtotal of ${float}", async function (points: number, subtotal: number) {
  await this.checkoutPage.addItemsForSubtotal(subtotal);
  await this.page.getByTestId("redeem-points-input").fill(String(points));
  await this.page.getByRole("button", { name: /apply points/i }).click();
});

When("I open the points page", async function () {
  await this.page.goto(`${process.env.BASE_URL}/account/points`);
});

Then("my points balance is {int}", async function (points: number) {
  await this.page.goto(`${process.env.BASE_URL}/account/points`);
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(points));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("points-tier")).toHaveText(tier);
});

Then("a tier discount of ${float} is applied", async function (discount: number) {
  await expect(this.page.getByTestId("order-tier-discount")).toHaveText(`$${discount.toFixed(2)}`);
});

Then("the order total is ${float}", async function (total: number) {
  await expect(this.page.getByTestId("order-total")).toHaveText(`$${total.toFixed(2)}`);
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("no points are redeemed", async function () {
  await expect(this.page.getByTestId("order-points-discount")).toHaveText("$0.00");
});
```

## Questions for Three Amigos

1. Is tier based on current balance or lifetime points earned (A3)? The answer flips the "redeeming lowers tier" scenario.
2. What is the redemption rate and does redemption apply before or after the tier discount (A5)?
3. Do points earn on the subtotal before or after the tier discount and point redemption (A1)?
4. What is the page-load target for AC-4 (A7)? "Fast" cannot be tested as written.
5. What happens to earned and redeemed points on cancellation or refund?

## Rules not applied

The `qa-rules` skill is not installed, so the `context-discovery` and `testing-guidelines` rules could not be read. The workspace is also empty, so no scenario was checked against real code.
