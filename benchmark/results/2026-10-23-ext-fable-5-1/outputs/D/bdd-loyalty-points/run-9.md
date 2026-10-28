**LOY-3 Loyalty points: BDD scenarios**

Grounding: the working directory contains no code, so the scenarios below are derived from the ticket text and the assumptions listed here. Nothing in them is verified against a running system.

## Assumptions and AC check

- **Subtotal** means the sum of item prices before tax, shipping, tier discount and redemption. Points are the whole-dollar part of that figure (floor, never rounded up).
- **Points are credited when the order is placed.** The ticket does not say when; reversal on cancellation is out of scope here.
- **Tier is based on the current points balance**, read literally from AC-2. This means redeeming can lower the tier. The product owner should confirm whether "points earned" was intended instead.
- **Tier is fixed at checkout.** The order that crosses a threshold does not get the new discount; the next order does.
- **Tier discounts do not stack.** Gold gets 10%, not 15%. Fractional discounts round to the nearest cent.
- **Point value** is not in the ticket. Assumed 100 points = $1.00 off, applied after the tier discount, capped at the order amount.
- **Invalid redemption amounts** (zero, negative, fractional, non-numeric) are rejected. The ticket gives no message for these, so the scenarios assert only refusal and an unchanged balance.
- **AC-4 fails the SMART check.** "Fast" is not measurable. Rewritten as: the points page shows balance and tier within 2 seconds at the 95th percentile for a member with 1,000 points transactions. The threshold is QA's placeholder and the scenario is tagged `@candidate` until the product owner confirms it.
- AC-1, AC-2 and AC-3 are specific, measurable and testable as written.

## Feature file

```gherkin
@loyalty
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  # ---------- AC-1: earning ----------

  @smoke @p0
  Scenario Outline: Points earned are the whole dollars of the order subtotal
    Given I am a loyalty programme member with a balance of 0 points
    When I place an order with a subtotal of $<subtotal>
    Then I earn <points> points
    And my points balance is <points>

    Examples:
      | subtotal | points |
      | 24.99    | 24     |
      | 25.00    | 25     |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 1.01     | 1      |
      | 999.99   | 999    |

  # Added by QA, the ticket says "subtotal" but not what it excludes; assumed tax, shipping and discounts are outside it
  @regression @p1
  Scenario: Points are earned on the subtotal, not on tax, shipping or the discounted total
    Given I am a loyalty programme member with a balance of 600 points
    When I place an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.00
    Then a "Silver" discount of $2.00 is applied
    And the order total is $46.20
    And I earn 40 points
    And my points balance is 640

  # Added by QA, the ticket does not say that points accumulate across orders
  @regression @p1
  Scenario: Points accumulate across orders
    Given I am a loyalty programme member with a balance of 10 points
    When I place an order with a subtotal of $24.99
    And I place another order with a subtotal of $10.50
    Then my points balance is 44

  # Added by QA, the ticket does not say what a shopper outside the programme earns
  @regression @p2
  Scenario: A shopper who is not a member earns no points and gets no tier discount
    Given I am signed in as a customer who has not joined the loyalty programme
    When I place an order with a subtotal of $24.99
    Then no points are earned
    And no tier discount is applied

  # ---------- AC-2: tiers and tier discounts ----------

  @smoke @p0
  Scenario Outline: Tier is determined by the points balance
    Given I am a loyalty programme member with a balance of <balance> points
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 10000   | Gold   |

  @smoke @p0
  Scenario Outline: Tier discount is applied to every order
    Given I am a loyalty programme member with a balance of <balance> points
    When I place an order with a subtotal of $100.00
    Then a "<tier>" discount of $<discount> is applied
    And the discounted subtotal is $<total>

    Examples:
      | balance | tier   | discount | total  |
      | 499     | Basic  | 0.00     | 100.00 |
      | 500     | Silver | 5.00     | 95.00  |
      | 1999    | Silver | 5.00     | 95.00  |
      | 2000    | Gold   | 10.00    | 90.00  |

  # Added by QA, the ticket does not say how a fractional discount is rounded; assumed to the nearest cent
  @regression @p2
  Scenario Outline: Tier discount is rounded to the nearest cent
    Given I am a loyalty programme member with a balance of <balance> points
    When I place an order with a subtotal of $24.99
    Then a "<tier>" discount of $<discount> is applied
    And the discounted subtotal is $<total>
    And I earn 24 points

    Examples:
      | balance | tier   | discount | total |
      | 500     | Silver | 1.25     | 23.74 |
      | 2000    | Gold   | 2.50     | 22.49 |

  # Added by QA, the ticket does not say whether the order that crosses a threshold gets the new discount; assumed the tier is fixed at checkout
  @regression @p1
  Scenario: Reaching a tier applies the discount to later orders, not to the order that reached it
    Given I am a loyalty programme member with a balance of 480 points
    When I place an order with a subtotal of $30.00
    Then no tier discount is applied to that order
    And my points balance is 510
    And my tier is shown as "Silver"
    When I place another order with a subtotal of $30.00
    Then a "Silver" discount of $1.50 is applied

  # Added by QA, AC-2 ties tier to "points", read as the current balance, so redeeming can lower the tier; confirm with the product owner
  @regression @p1
  Scenario: Redeeming points below a threshold lowers the tier
    Given I am a loyalty programme member with a balance of 2000 points
    And I am at checkout with an order subtotal of $5.00
    When I redeem 100 points and place the order
    Then my points balance is 1905
    And my tier is shown as "Silver"

  # ---------- AC-3: redeeming ----------

  @smoke @p0
  Scenario: Redeeming more points than the balance is refused
    Given I am a loyalty programme member with a balance of 300 points
    And I am at checkout with an order subtotal of $50.00
    When I redeem 301 points
    Then I see the message "You don't have enough points."
    And no redemption discount is applied to the order
    And my points balance is 300

  @regression @p1
  Scenario Outline: Redemption is accepted up to the exact balance
    Given I am a loyalty programme member with a balance of 300 points
    And I am at checkout with an order subtotal of $50.00
    When I redeem <redeem> points
    Then the redemption is <result>
    And my points balance before placing the order is <balance>

    Examples:
      | redeem | result   | balance |
      | 299    | accepted | 1       |
      | 300    | accepted | 0       |
      | 301    | refused  | 300     |

  # Added by QA, the ticket does not give the value of a point; assumed 100 points = $1.00 off, applied after the tier discount
  @regression @p1
  Scenario: Redeemed points reduce the order total after the tier discount
    Given I am a loyalty programme member with a balance of 600 points
    And I am at checkout with an order subtotal of $50.00
    When I redeem 500 points and place the order
    Then a "Silver" discount of $2.50 is applied
    And a redemption discount of $5.00 is applied
    And the discounted subtotal is $42.50
    And I earn 50 points
    And my points balance is 150

  # Added by QA, the ticket is silent on zero, negative and non-numeric amounts; assumed they are rejected without touching the balance
  @regression @p2
  Scenario Outline: Invalid redemption amounts are rejected
    Given I am a loyalty programme member with a balance of 300 points
    And I am at checkout with an order subtotal of $50.00
    When I enter "<amount>" as the points to redeem
    Then the redemption is refused
    And my points balance is 300

    Examples:
      | amount |
      | 0      |
      | -1     |
      | 1.5    |
      | abc    |
      |        |

  # Added by QA, the ticket does not say what happens when the points are worth more than the order; assumed the discount is capped and only the points used are deducted
  @regression @p2
  Scenario: Redemption is capped at the order amount
    Given I am a loyalty programme member with a balance of 1500 points
    And I am at checkout with an order subtotal of $10.00
    When I redeem 1500 points and place the order
    Then a "Silver" discount of $0.50 is applied
    And a redemption discount of $9.50 is applied
    And the discounted subtotal is $0.00
    And only 950 points are deducted
    And my points balance is 560

  # Added by QA, points must not be lost when the order is never placed
  @regression @p1
  Scenario: Points are not deducted when checkout is abandoned after redeeming
    Given I am a loyalty programme member with a balance of 300 points
    And I am at checkout with an order subtotal of $50.00
    When I redeem 200 points
    And I leave checkout without placing the order
    Then my points balance is 300

  # ---------- AC-4: points page ----------

  # Added by QA, the ticket names a points page but not what it shows; assumed balance, tier and points to the next tier
  @regression @p1
  Scenario Outline: Points page shows balance, tier and progress to the next tier
    Given I am a loyalty programme member with a balance of <balance> points
    When I open the points page
    Then my balance is shown as "<shown>"
    And my tier is shown as "<tier>"
    And the next tier message is "<next>"

    Examples:
      | balance | shown | tier   | next                     |
      | 0       | 0     | Basic  | 500 points to Silver     |
      | 1250    | 1,250 | Silver | 750 points to Gold       |
      | 2000    | 2,000 | Gold   | You are at the top tier  |

  # AC-4 is not measurable as written; the 2-second threshold is QA's assumption, confirm with the product owner
  @candidate @nfr @p2
  Scenario: Points page loads within the agreed time
    Given I am a loyalty programme member with 1,000 points transactions in my history
    When I open the points page
    Then my balance and tier are visible within 2 seconds

  # ---------- Validation of the expected gain ----------

  # Added by QA, validates the story's goal end to end: points earned now give a discount on a later order
  @e2e @p0
  Scenario: Points earned on earlier orders give a discount on a later order
    Given I am a loyalty programme member with a balance of 0 points
    When I place an order with a subtotal of $499.99
    Then no tier discount is applied
    And my points balance is 499
    When I place an order with a subtotal of $1.00
    Then my points balance is 500
    And my tier is shown as "Silver"
    When I am at checkout with an order subtotal of $20.00
    And I redeem 100 points and place the order
    Then a "Silver" discount of $1.00 is applied
    And a redemption discount of $1.00 is applied
    And the discounted subtotal is $18.00
    And my points balance is 420
```

## Step definitions (Playwright + Cucumber, TypeScript)

The ticket does not name a stack, so Playwright with Cucumber is assumed. Balance setup goes through a test API rather than the UI so scenarios stay independent.

```typescript
// features/loyalty.feature -> steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

Given("I am a loyalty programme member with a balance of {int} points", async function (balance: number) {
  this.member = await this.testApi.createMember({ points: balance });
  await this.page.goto(process.env.BASE_URL!);
  await this.signIn(this.member);
});

When("I place an order with a subtotal of ${float}", async function (subtotal: number) {
  await this.checkout.addItemsTotalling(subtotal);
  await this.checkout.placeOrder();
});

Then("I earn {int} points", async function (points: number) {
  await expect(this.page.getByTestId("order-points-earned")).toHaveText(String(points));
});

Then("my points balance is {int}", async function (balance: number) {
  await this.page.goto("/account/points");
  await expect(this.page.getByTestId("points-balance")).toHaveText(balance.toLocaleString("en-US"));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("points-tier")).toHaveText(tier);
});

Then("a {string} discount of ${float} is applied", async function (tier: string, amount: number) {
  const row = this.page.getByTestId("tier-discount-line");
  await expect(row).toContainText(tier);
  await expect(row).toContainText(amount.toFixed(2));
});

When("I redeem {int} points", async function (points: number) {
  await this.page.getByLabel("Points to redeem").fill(String(points));
  await this.page.getByRole("button", { name: /redeem/i }).click();
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("my balance and tier are visible within {int} seconds", async function (seconds: number) {
  const started = Date.now();
  await expect(this.page.getByTestId("points-balance")).toBeVisible({ timeout: seconds * 1000 });
  await expect(this.page.getByTestId("points-tier")).toBeVisible({ timeout: seconds * 1000 });
  expect(Date.now() - started).toBeLessThanOrEqual(seconds * 1000);
});
```

Suggested `data-testid` hooks for the developers: `points-balance`, `points-tier`, `points-next-tier`, `order-points-earned`, `tier-discount-line`, `redemption-discount-line`, `redeem-points-input`.

Rules not applied: the `context-discovery` and `testing-guidelines` rules were not loaded and the `qa-rules` skill is not installed, so they could not be read. The working directory is also empty, so no scenario was checked against real code, routes or messages. Treat every element name and message other than "You don't have enough points." as an assumption to confirm in the Three Amigos session.
