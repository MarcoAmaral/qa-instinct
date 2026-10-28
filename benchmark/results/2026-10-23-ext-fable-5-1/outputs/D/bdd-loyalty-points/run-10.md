# LOY-3 Loyalty points — BDD scenarios

## Context discovery

The working directory contains no source files, so no scenario below is grounded in real code, routes, labels or `data-testid` attributes. Every step is written at business level and must be checked against the implementation before it is treated as verified. Stack unknown; step definitions assume Playwright + Cucumber (TypeScript).

## AC quality check (SMART)

| AC | Verdict | Issue | Assumption used |
| --- | --- | --- | --- |
| AC-1 | Testable | "Subtotal" and the moment of crediting are undefined | Subtotal = sum of item prices before tier discount, points redemption, shipping and tax. Points are credited when the order is placed. |
| AC-2 | Testable, ambiguous | Which balance drives the tier (current vs lifetime)? Is the discount decided before or after the order's own points are credited? Rounding of discounts? | Tier derives from the **current** balance, so redeeming can lower it. The tier in force when the order is placed sets the discount. Discounts round half-up to the cent. Discount applies to the subtotal. |
| AC-3 | Testable | Point value and redemption flow undefined | 100 points = $1.00 off, entered on the checkout page. Tier discount is applied first, then the redeemed amount. |
| AC-4 | **Not measurable** | "Fast" has no pass/fail condition | Rewritten as: the points page shows balance and tier within 2 s at the 95th percentile for a member with up to 1,000 ledger entries. PO must confirm the figure. |

## Feature file

```gherkin
@loyalty @LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------- AC-1: earning ----------

  @smoke @p0 @earning
  Scenario Outline: Points are earned per whole dollar of the order subtotal
    Given my points balance is 0
    And my cart subtotal is "<subtotal>"
    When I place the order
    Then my points balance is <points>

    Examples: whole-dollar floor, including boundaries
      | subtotal  | points |
      | $24.99    | 24     |
      | $25.00    | 25     |
      | $1.00     | 1      |
      | $0.99     | 0      |
      | $0.00     | 0      |
      | $1,234.56 | 1234   |

  # Added by QA, AC-1 is silent on whether points are computed before or after discounts
  @regression @p1 @earning @candidate
  Scenario: Points are earned on the subtotal before the tier discount is applied
    Given my points balance is 600
    And my tier is "Silver"
    And my cart subtotal is $100.00
    When I place the order
    Then the order total is $95.00
    And my points balance is 700

  # Added by QA, the story only describes members
  @regression @p2 @earning
  Scenario: A customer who is not a member earns no points
    Given I am signed in as a customer who is not in the loyalty programme
    And my cart subtotal is $50.00
    When I place the order
    Then no points are credited to my account
    And the order confirmation shows no points earned

  # ---------- AC-2: tiers and discounts ----------

  @smoke @p0 @tier
  Scenario Outline: Tier is determined by the points balance
    Given my points balance is <balance>
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples: boundary values around 500 and 2,000
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 2001    | Gold   |

  @smoke @p0 @tier @discount
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    And my cart subtotal is $100.00
    When I proceed to checkout
    Then the order summary shows a "<tier>" discount of "<discount>"
    And the order total is "<total>"

    Examples:
      | balance | tier   | discount | total   |
      | 100     | Basic  | $0.00    | $100.00 |
      | 500     | Silver | $5.00    | $95.00  |
      | 2000    | Gold   | $10.00   | $90.00  |

  # Added by QA, AC-2 does not say how fractional cents are rounded
  @regression @p2 @discount @candidate
  Scenario: Tier discount rounds half-up to the cent
    Given my points balance is 500
    And my cart subtotal is $24.99
    When I proceed to checkout
    Then the order summary shows a "Silver" discount of "$1.25"
    And the order total is "$23.74"

  # Added by QA, AC-2 does not say whether the current order's points count toward its own discount
  @regression @p1 @tier @discount
  Scenario: Discount uses the tier in force when the order is placed
    Given my points balance is 499
    And my tier is "Basic"
    And my cart subtotal is $100.00
    When I place the order
    Then the order total is $100.00
    And my points balance is 599
    And my tier is shown as "Silver"

  # Added by QA, assumes the tier follows the current balance; confirm with PO
  @regression @p1 @tier @candidate
  Scenario: Redeeming points below a threshold lowers the tier
    Given my points balance is 2000
    And my tier is "Gold"
    When I redeem 100 points on an order
    Then my points balance is 1900
    And my tier is shown as "Silver"

  # ---------- AC-3: redeeming ----------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    And my cart subtotal is $50.00
    When I try to redeem 101 points
    Then I see the message "You don't have enough points."
    And my points balance is still 100
    And the order total is still $50.00

  @regression @p1 @redeem
  Scenario: Redeeming exactly the full balance succeeds
    Given my points balance is 100
    And my cart subtotal is $50.00
    When I redeem 100 points
    Then my points balance is 0
    And the order total is $49.00

  # Added by QA, assumes 100 points = $1.00; the ticket gives no point value
  @regression @p1 @redeem @candidate
  Scenario Outline: Redeemed points reduce the order total at the agreed rate
    Given my points balance is 1000
    And my cart subtotal is $50.00
    When I redeem <points> points
    Then the order total is "<total>"
    And my points balance is <remaining>

    Examples:
      | points | total  | remaining |
      | 100    | $49.00 | 900       |
      | 1000   | $40.00 | 0         |

  # Added by QA, AC-3 only covers the over-balance case
  @regression @p2 @redeem @candidate
  Scenario Outline: Non-positive or non-numeric redemption amounts are rejected
    Given my points balance is 100
    When I try to redeem "<input>" points
    Then I see a validation message
    And my points balance is still 100

    Examples:
      | input |
      | 0     |
      | -5    |
      | abc   |
      |       |

  # Added by QA, order of discounts is undefined; assumes tier discount first, then points
  @regression @p1 @redeem @discount @candidate
  Scenario: Tier discount and redeemed points combine on one order
    Given my points balance is 600
    And my cart subtotal is $100.00
    When I redeem 100 points
    Then the order summary shows a "Silver" discount of "$5.00"
    And the order summary shows a points discount of "$1.00"
    And the order total is "$94.00"

  # ---------- AC-4: points page ----------

  # Added by QA, AC-4 "should load fast" is not measurable; threshold is an assumption pending PO sign-off
  @nfr @performance @p2 @candidate
  Scenario: Points page loads within the agreed time budget
    Given my account has 1,000 points ledger entries
    When I open the points page
    Then my balance and tier are visible within 2 seconds
    And the 95th-percentile load time across 20 runs is under 2 seconds

  # Added by QA, the story implies a points page but never describes it
  @regression @p1 @points-page
  Scenario: Points page shows the current balance and tier
    Given my points balance is 750
    When I open the points page
    Then my balance is shown as 750
    And my tier is shown as "Silver"
```

## Step definitions (Playwright + Cucumber, TypeScript) — representative subset

```typescript
// steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

Given("I am signed in as a loyalty programme member", async function () {
  await this.api.createMember({ points: 0 });
  await this.page.goto(`${process.env.BASE_URL}/login`);
  await this.page.getByLabel("Email").fill(this.member.email);
  await this.page.getByLabel("Password").fill(this.member.password);
  await this.page.getByRole("button", { name: /sign in/i }).click();
});

Given("my points balance is {int}", async function (balance: number) {
  await this.api.setPointsBalance(this.member.id, balance); // test seam, to be confirmed
});

Given("my cart subtotal is {string}", async function (subtotal: string) {
  await this.api.seedCart(this.member.id, { subtotal: parseMoney(subtotal) });
});

When("I place the order", async function () {
  await this.page.goto(`${process.env.BASE_URL}/checkout`);
  await this.page.getByRole("button", { name: /place order/i }).click();
  await expect(this.page.getByTestId("order-confirmation")).toBeVisible();
});

When("I try to redeem {int} points", async function (points: number) {
  await this.page.goto(`${process.env.BASE_URL}/checkout`);
  await this.page.getByLabel("Points to redeem").fill(String(points));
  await this.page.getByRole("button", { name: /apply points/i }).click();
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("my points balance is {int}", async function (expected: number) {
  await this.page.goto(`${process.env.BASE_URL}/account/points`);
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(expected));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("points-tier")).toHaveText(tier);
});

Then("the order total is {string}", async function (total: string) {
  await expect(this.page.getByTestId("order-total")).toHaveText(total);
});
```

`data-testid` names (`points-balance`, `points-tier`, `order-total`, `order-confirmation`) and the `setPointsBalance` test seam are proposals for the Three Amigos, not existing hooks.

## Open questions for Three Amigos

1. **Tier basis**: current balance or lifetime points earned? Decides whether redeeming can demote a member (two `@candidate` scenarios depend on it).
2. **Point value**: what is 1 point worth at redemption, and is there a minimum redemption?
3. **Discount order**: tier discount before or after points, and can points cover the whole order?
4. **Earning basis**: are points computed on the subtotal before or after the tier discount and redemption?
5. **Cancellations and refunds**: are earned points reversed and redeemed points returned? Not covered above.
6. **AC-4 target**: confirm the 2 s / p95 budget, the device and network profile, and the data volume.

## Rules not applied

The `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed, so they were not loaded. Context discovery was attempted directly: the repository is empty, so nothing could be verified against the real system.
