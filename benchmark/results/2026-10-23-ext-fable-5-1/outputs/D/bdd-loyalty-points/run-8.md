# Feature LOY-3: Loyalty points — BDD scenarios

## AC quality check (SMART)

| AC | Verdict | Note |
| --- | --- | --- |
| AC-1 | Pass | Specific, measurable, worked example given. Rounding rule (floor) is explicit. |
| AC-2 | Pass with gaps | Tier thresholds are clear. Unclear whether tier is based on lifetime points or current balance, and whether the discount applies to subtotal or total. See assumptions. |
| AC-3 | Pass | Exact message and "redeems nothing" give a clear pass/fail. Point-to-dollar redemption rate is not stated. |
| AC-4 | **Reject** | "Load fast" is not measurable. Rewrite proposed below; scenario is tagged `@candidate` until the product owner confirms a number. |

**Proposed rewrite of AC-4:** "The points page renders the member's balance and tier within 2 seconds at the 95th percentile, measured on the staging environment under normal load."

## Assumptions

The workspace is empty, so these scenarios are written from the ticket alone and not from the real system. Each assumption below is one I made to keep going.

1. **Tier is based on lifetime earned points**, not the spendable balance. Otherwise redeeming would demote a member, which contradicts "discounts on later orders". Flagged for the product owner.
2. **The tier discount is applied to the order subtotal** before tax and shipping.
3. **Points are earned on the discounted subtotal**, so a Silver member paying $95.00 on a $100.00 order earns 95 points.
4. **Redemption rate** is 100 points = $1.00 off. The ticket gives no rate.
5. **Tier upgrades take effect on the next order**, not the order that crosses the threshold.
6. **Points are credited when the order is placed**, not when it ships. Refunds and cancellations are out of scope for LOY-3.
7. **Points cannot be negative** and a redemption of zero points is rejected.
8. **Page load target** is 2 seconds at the 95th percentile, pending confirmation.

## Feature file

```gherkin
@loyalty @LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------------------------------------------------------------
  # AC-1: earning points
  # ---------------------------------------------------------------

  @smoke @p0 @earn
  Scenario: Member earns one point per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance is 24
    And the order confirmation shows "You earned 24 points"

  @regression @p1 @earn
  Scenario Outline: Points are floored to the whole dollar
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
      | 100.50   | 100    |

  # Added by QA, the ticket does not say whether earning is cumulative across orders
  @regression @p1 @earn
  Scenario: Points accumulate across orders
    Given my points balance is 24
    When I place an order with a subtotal of $10.00
    Then my points balance is 34

  # Added by QA, assumption 3: points are earned on the discounted subtotal
  @regression @p2 @earn @candidate
  Scenario: Silver member earns points on the discounted subtotal
    Given my lifetime points are 500
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then the order subtotal after discount is $95.00
    And I earn 95 points

  # ---------------------------------------------------------------
  # AC-2: tiers and tier discounts
  # ---------------------------------------------------------------

  @smoke @p0 @tier
  Scenario Outline: Tier is determined by lifetime points at the boundaries
    Given my lifetime points are <points>
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

  @smoke @p0 @tier @discount
  Scenario Outline: Tier discount is applied to the order subtotal
    Given my lifetime points are <points>
    And my tier is <tier>
    When I add an item with a subtotal of $100.00 to my basket
    Then the tier discount shown is <discount>
    And the subtotal after discount is $<after>

    Examples:
      | points | tier   | discount | after  |
      | 499    | Basic  | 0%       | 100.00 |
      | 500    | Silver | 5%       | 95.00  |
      | 1999   | Silver | 5%       | 95.00  |
      | 2000   | Gold   | 10%      | 90.00  |

  # Added by QA, the ticket is silent on when an upgrade takes effect (assumption 5)
  @regression @p1 @tier @candidate
  Scenario: Tier upgrade applies to the next order, not the order that crosses the threshold
    Given my lifetime points are 480
    And my tier is Basic
    When I place an order with a subtotal of $30.00
    Then the order is charged with no tier discount
    And my lifetime points are 510
    And my tier is now Silver
    When I place another order with a subtotal of $100.00
    Then the subtotal after discount is $95.00

  # Added by QA, assumption 1: tier is based on lifetime points, so redeeming must not demote
  @regression @p1 @tier @redeem @candidate
  Scenario: Redeeming points does not lower the member's tier
    Given my lifetime points are 600
    And my points balance is 600
    And my tier is Silver
    When I redeem 300 points
    Then my points balance is 300
    And my tier is still Silver

  # Added by QA, the discount is a percentage and the ticket gives no rounding rule
  @regression @p2 @discount
  Scenario Outline: Tier discount rounds to the cent
    Given my tier is <tier>
    When I add an item with a subtotal of $<subtotal> to my basket
    Then the subtotal after discount is $<after>

    Examples:
      | tier   | subtotal | after |
      | Silver | 0.10     | 0.10  |
      | Silver | 24.99    | 23.74 |
      | Gold   | 24.99    | 22.49 |
      | Gold   | 0.05     | 0.05  |

  # ---------------------------------------------------------------
  # AC-3: redeeming points
  # ---------------------------------------------------------------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    When I try to redeem 101 points
    Then I see the message "You don't have enough points."
    And my points balance is still 100
    And no discount is applied to the order

  @regression @p1 @redeem
  Scenario Outline: Redemption at the balance boundary
    Given my points balance is 100
    When I try to redeem <requested> points
    Then the redemption is "<outcome>"
    And my points balance is <remaining>

    Examples:
      | requested | outcome  | remaining |
      | 99        | accepted | 1         |
      | 100       | accepted | 0         |
      | 101       | rejected | 100       |

  # Added by QA, the ticket defines only the failure path of redemption
  @smoke @p0 @redeem @candidate
  Scenario: Successful redemption applies a discount to the order
    Given my points balance is 500
    When I redeem 200 points on an order with a subtotal of $50.00
    Then the order shows a points discount of $2.00
    And my points balance is 300

  # Added by QA, the ticket does not cover zero, negative or non-numeric input
  @regression @p2 @redeem
  Scenario Outline: Invalid redemption amounts are rejected without changing the balance
    Given my points balance is 100
    When I try to redeem "<input>" points
    Then the redemption is rejected
    And my points balance is still 100

    Examples:
      | input |
      | 0     |
      | -1    |
      | abc   |
      | 1.5   |
      |       |

  # Added by QA, a double submit or a second tab must not redeem twice
  @regression @p1 @redeem
  Scenario: Submitting the same redemption twice only redeems once
    Given my points balance is 100
    When I submit a redemption of 100 points
    And I submit the same redemption again before the first completes
    Then exactly one redemption is recorded
    And my points balance is 0
    And the second attempt shows "You don't have enough points."

  # Added by QA, a Basic member with points must still be able to redeem
  @regression @p2 @redeem @tier
  Scenario: Basic member can redeem points independently of tier discount
    Given my lifetime points are 300
    And my points balance is 300
    And my tier is Basic
    When I redeem 300 points on an order with a subtotal of $20.00
    Then the order shows a points discount of $3.00
    And no tier discount is applied

  # ---------------------------------------------------------------
  # AC-4: points page performance
  # ---------------------------------------------------------------

  # AC-4 as written is not testable. This scenario uses assumption 8 and
  # stays @candidate until the product owner confirms the figure.
  @performance @p1 @candidate
  Scenario: Points page renders balance and tier within the agreed time
    Given my points balance is 1250
    And my tier is Silver
    When I open the points page
    Then the balance and tier are visible within 2 seconds
    And the measurement is taken at the 95th percentile over 20 loads on staging

  # Added by QA, the page must be correct before it is fast
  @smoke @p0 @points-page
  Scenario: Points page shows the current balance and tier
    Given my lifetime points are 1250
    And my points balance is 1250
    When I open the points page
    Then I see my balance of 1250 points
    And my tier is shown as "Silver"
    And I see that 750 more points are needed to reach Gold

  # Added by QA, the ticket does not say what a non-member sees
  @regression @p2 @points-page
  Scenario: Non-member is invited to join rather than shown a balance
    Given I am signed in as a customer who is not a loyalty programme member
    When I open the points page
    Then I see an invitation to join the loyalty programme
    And no balance or tier is shown
```

## Step definitions (Playwright + Cucumber, TypeScript)

Only the steps that need something beyond a page visit are shown. Test IDs are proposals for the Three Amigos session; the real ones should be agreed with the developer.

```typescript
// features/loyalty-points.feature → steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";
import { seedMember } from "../support/loyaltyApi";

Given("I am signed in as a loyalty programme member", async function () {
  this.member = await seedMember({ lifetimePoints: 0, balance: 0 });
  await this.page.goto(process.env.BASE_URL!);
  await this.page.getByLabel("Email").fill(this.member.email);
  await this.page.getByLabel("Password").fill(this.member.password);
  await this.page.getByRole("button", { name: /sign in/i }).click();
});

Given("my points balance is {int}", async function (balance: number) {
  await seedMember({ id: this.member.id, balance });
});

Given("my lifetime points are {int}", async function (lifetime: number) {
  await seedMember({ id: this.member.id, lifetimePoints: lifetime });
});

When("I place an order with a subtotal of ${float}", async function (subtotal: number) {
  await this.page.goto("/test-catalogue");
  await this.page.getByTestId("add-custom-item").fill(subtotal.toFixed(2));
  await this.page.getByRole("button", { name: /add to basket/i }).click();
  await this.page.getByRole("button", { name: /checkout/i }).click();
  await this.page.getByRole("button", { name: /place order/i }).click();
  await expect(this.page.getByTestId("order-confirmation")).toBeVisible();
});

Then("my points balance is {int}", async function (expected: number) {
  await this.page.goto("/account/points");
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(expected));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("points-tier")).toHaveText(tier);
});

When("I try to redeem {int} points", async function (points: number) {
  await this.page.goto("/checkout");
  await this.page.getByTestId("redeem-points-input").fill(String(points));
  await this.page.getByRole("button", { name: /redeem/i }).click();
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("no discount is applied to the order", async function () {
  await expect(this.page.getByTestId("points-discount")).toHaveText("$0.00");
});

Then(
  "the balance and tier are visible within {int} seconds",
  async function (seconds: number) {
    const start = Date.now();
    await expect(this.page.getByTestId("points-balance")).toBeVisible({
      timeout: seconds * 1000,
    });
    await expect(this.page.getByTestId("points-tier")).toBeVisible({
      timeout: seconds * 1000,
    });
    this.lastLoadMs = Date.now() - start;
  }
);
```

The 95th percentile step belongs in a k6 or Playwright load script, not a single Cucumber run. A single-run assertion in the step above gives an early signal; the percentile is checked in the performance pipeline.

## Questions for the Three Amigos session

1. Is tier based on lifetime points or current balance? Assumption 1 says lifetime.
2. What is the redemption rate? Assumption 4 says 100 points = $1.00.
3. Do points earned on an order count toward the discount on that same order? Assumption 5 says no.
4. What happens to points when an order is refunded or cancelled? Out of scope here, but it will be asked.
5. What is the number behind "fast" in AC-4? Assumption 8 proposes 2 seconds at p95.
6. Can tier discount and points redemption stack on one order? The scenarios assume yes.

## Rule not applied

The `context-discovery` rule could not be loaded because no `qa-rules` skill is installed. The workspace is empty, so the scenarios are grounded in the ticket and the assumptions above, not in the real system. Every step and test ID is a proposal until it is checked against the implementation.
