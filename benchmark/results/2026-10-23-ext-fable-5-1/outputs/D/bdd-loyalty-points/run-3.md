# LOY-3 — Loyalty points: BDD scenarios

## Context discovery

The working directory is empty, so no code, schema or UI was available to ground the steps. Every scenario below is written from the ticket alone and is marked `@candidate` until checked against the real system. Step wording (page names, message text, field labels) is assumed, not verified.

## AC quality check (SMART)

| AC | Verdict | Note |
| --- | --- | --- |
| AC-1 | Testable | "Whole dollar" and the $24.99 example make truncation explicit. |
| AC-2 | Testable, but silent on which balance decides the tier (lifetime earned or current spendable) and on whether the discount applies before or after points are earned. |
| AC-3 | Testable | Exact message given. Silent on the happy path: the redemption rate (points to dollars) and whether a balance can be redeemed in full. |
| AC-4 | **Not testable** | "Fast" has no threshold. Rewritten below as a measurable assumption. |

## Assumptions

- **A1 Tier basis.** Tier is decided by the current points balance, not lifetime points, so redeeming can drop a member's tier. If the product intends lifetime points, scenarios tagged `@tier` need the Given lines changed, not the outcomes.
- **A2 Order of operations.** The tier discount is applied to the subtotal first, and points are earned on the discounted subtotal in whole dollars. The ticket does not say; this is the reading that avoids earning points on money the member did not pay.
- **A3 Redemption rate.** 100 points redeem for $1.00 off, and a member may redeem any multiple of 100 up to the full balance. The rate does not change the AC-3 outcomes.
- **A4 Tier applies at the moment of checkout.** The tier at order placement sets the discount, even if the order's own points would cross a boundary.
- **A5 AC-4 threshold.** "Fast" is read as: the points page reaches its first contentful paint within 2 seconds at the 95th percentile on a 4G profile, measured from a warm session. The product owner must confirm or replace this figure.
- **A6 Rounding.** Discounts are rounded to the nearest cent, half up.

## Feature file

```gherkin
@candidate @loyalty @LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member
    And my cart contains items with a subtotal as stated in each scenario

  # ---------- AC-1: earning ----------

  @smoke @p0 @earn
  Scenario Outline: Points are earned per whole dollar of the subtotal
    Given my points balance is 0
    And my cart subtotal is <subtotal>
    When I place the order
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $0.00    | 0      |
      | $999.01  | 999    |

  # Added by QA, the ticket shows one order; a member earns across several orders
  @regression @p1 @earn
  Scenario: Points accumulate across orders
    Given my points balance is 10
    And my cart subtotal is $24.99
    When I place the order
    Then my points balance is 34

  # Added by QA, assumption A2; the ticket does not say whether points are earned on the discounted or full subtotal
  @regression @p1 @earn @tier
  Scenario: A Silver member earns points on the discounted subtotal
    Given my points balance is 500
    And my cart subtotal is $100.00
    When I place the order
    Then the order total is $95.00
    And my points balance is 595

  # ---------- AC-2: tiers and discounts ----------

  @smoke @p0 @tier
  Scenario Outline: Tier is decided by the points balance
    Given my points balance is <balance>
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 2001    | Gold   |

  @smoke @p0 @tier
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    And my cart subtotal is $100.00
    When I place the order
    Then the order shows a discount of <discount>
    And the order total is <total>

    Examples:
      | balance | discount | total   |
      | 499     | $0.00    | $100.00 |
      | 500     | $5.00    | $95.00  |
      | 1999    | $5.00    | $95.00  |
      | 2000    | $10.00   | $90.00  |

  # Added by QA, assumption A6; a percentage off an odd subtotal needs a rounding rule
  @regression @p2 @tier
  Scenario Outline: Tier discount is rounded to the nearest cent
    Given my points balance is <balance>
    And my cart subtotal is <subtotal>
    When I place the order
    Then the order shows a discount of <discount>

    Examples:
      | balance | subtotal | discount |
      | 500     | $24.99   | $1.25    |
      | 2000    | $24.99   | $2.50    |
      | 500     | $0.10    | $0.01    |

  # Added by QA, assumption A4; the ticket does not say whether an order that crosses a boundary earns its own discount
  @regression @p1 @tier
  Scenario: The tier at checkout sets the discount, not the tier after the order
    Given my points balance is 450
    And my cart subtotal is $100.00
    When I place the order
    Then the order shows a discount of $0.00
    And my points balance is 550
    And my tier is shown as "Silver"

  # Added by QA, assumption A1; if tier follows the balance, redeeming can lower it
  @regression @p1 @tier @redeem
  Scenario: Redeeming points below a boundary lowers the tier
    Given my points balance is 500
    When I redeem 100 points
    Then my points balance is 400
    And my tier is shown as "Basic"

  # ---------- AC-3: redeeming ----------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is refused
    Given my points balance is 100
    When I redeem 101 points
    Then I see the message "You don't have enough points."
    And my points balance is 100
    And no discount is applied to the order

  @regression @p1 @redeem
  Scenario Outline: Redemption is refused at any balance when the amount exceeds it
    Given my points balance is <balance>
    When I redeem <amount> points
    Then I see the message "You don't have enough points."
    And my points balance is <balance>

    Examples:
      | balance | amount |
      | 0       | 1      |
      | 0       | 100    |
      | 2000    | 2001   |

  # Added by QA, the ticket gives only the failure; the happy path and the exact-balance boundary are untested without it (assumption A3)
  @smoke @p0 @redeem
  Scenario Outline: Redeeming up to the full balance succeeds
    Given my points balance is <balance>
    And my cart subtotal is $50.00
    When I redeem <amount> points
    Then the order shows a points discount of <discount>
    And my points balance is <remaining>

    Examples:
      | balance | amount | discount | remaining |
      | 100     | 100    | $1.00    | 0         |
      | 500     | 100    | $1.00    | 400       |
      | 2000    | 2000   | $20.00   | 0         |

  # Added by QA, the ticket is silent on invalid amounts; zero and negative values must not change the balance
  @regression @p2 @redeem
  Scenario Outline: Zero or negative redemption amounts are rejected
    Given my points balance is 500
    When I redeem <amount> points
    Then the redemption is rejected
    And my points balance is 500

    Examples:
      | amount |
      | 0      |
      | -1     |

  # Added by QA, assumption A2 plus A3; the ticket does not say how a tier discount and a points discount combine
  @regression @p1 @redeem @tier
  Scenario: Tier discount and points discount both apply to one order
    Given my points balance is 600
    And my cart subtotal is $100.00
    When I redeem 100 points
    And I place the order
    Then the order shows a discount of $5.00
    And the order shows a points discount of $1.00
    And the order total is $94.00
    And my points balance is 594

  # ---------- AC-4: points page performance ----------

  # Rewritten by QA, "fast" is not measurable; threshold is assumption A5 and needs product owner sign-off
  @performance @p2 @non-functional
  Scenario: The points page loads within the agreed threshold
    Given my points balance is 1500
    And I have a transaction history of 1,000 point entries
    When I open the points page
    Then the first contentful paint occurs within 2 seconds at the 95th percentile
    And my points balance and tier are visible without further interaction
```

## Playwright step definitions (TypeScript, Cucumber)

Selectors are placeholders. Replace the `data-testid` values with the ones the implementation exposes.

```typescript
// steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

const money = (s: string) => s.trim();

Given("I am signed in as a loyalty programme member", async function () {
  await this.page.goto(process.env.BASE_URL ?? "http://localhost:3000/");
  await this.page.getByLabel("Email").fill(process.env.TEST_EMAIL!);
  await this.page.getByLabel("Password").fill(process.env.TEST_PASSWORD!);
  await this.page.getByRole("button", { name: /sign in/i }).click();
});

Given("my points balance is {int}", async function (balance: number) {
  // Seed through the test API so the scenario does not depend on prior orders.
  await this.api.post("/test/loyalty/balance", { data: { balance } });
});

Given("my cart subtotal is {word}", async function (subtotal: string) {
  await this.api.post("/test/cart", { data: { subtotal } });
});

Given("I have a transaction history of {int} point entries", async function (n: number) {
  await this.api.post("/test/loyalty/history", { data: { entries: n } });
});

When("I place the order", async function () {
  await this.page.goto("/checkout");
  await this.page.getByRole("button", { name: /place order/i }).click();
  await expect(this.page.getByTestId("order-confirmation")).toBeVisible();
});

When("I redeem {int} points", async function (amount: number) {
  await this.page.goto("/checkout");
  await this.page.getByTestId("redeem-points-input").fill(String(amount));
  await this.page.getByTestId("redeem-points-btn").click();
});

When("I open the points page", async function () {
  await this.page.goto("/account/points");
});

Then("my points balance is {int}", async function (expected: number) {
  await this.page.goto("/account/points");
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(expected));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("points-tier")).toHaveText(tier);
});

Then("the order shows a discount of {word}", async function (discount: string) {
  await expect(this.page.getByTestId("order-tier-discount")).toHaveText(money(discount));
});

Then("the order shows a points discount of {word}", async function (discount: string) {
  await expect(this.page.getByTestId("order-points-discount")).toHaveText(money(discount));
});

Then("the order total is {word}", async function (total: string) {
  await expect(this.page.getByTestId("order-total")).toHaveText(money(total));
});

Then("no discount is applied to the order", async function () {
  await expect(this.page.getByTestId("order-points-discount")).toHaveText("$0.00");
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("the redemption is rejected", async function () {
  await expect(this.page.getByRole("alert")).toBeVisible();
  await expect(this.page.getByTestId("order-points-discount")).toHaveText("$0.00");
});

Then(
  "the first contentful paint occurs within {int} seconds at the 95th percentile",
  async function (seconds: number) {
    // Single-run guard only; the p95 figure comes from the load-test job, not this step.
    const fcp = await this.page.evaluate(
      () => performance.getEntriesByName("first-contentful-paint")[0]?.startTime ?? Infinity
    );
    expect(fcp).toBeLessThanOrEqual(seconds * 1000);
  }
);

Then("my points balance and tier are visible without further interaction", async function () {
  await expect(this.page.getByTestId("points-balance")).toBeVisible();
  await expect(this.page.getByTestId("points-tier")).toBeVisible();
});
```

## Open points for the three amigos

1. **Tier basis** (A1): current balance or lifetime earned? This changes whether redeeming can demote a member.
2. **Order of operations** (A2): are points earned on the full or the discounted subtotal, and do tier and points discounts stack?
3. **Redemption rate and granularity** (A3): the ticket has no happy path for redeeming.
4. **AC-4 threshold** (A5): replace "fast" with a number, a percentile and a device profile, or the scenario cannot fail.
5. **Refunds and cancellations**: the ticket says nothing about clawing back points when an order is refunded. No scenario was written because any outcome would be a guess.

Rule not applied: `context-discovery` could not be run against a codebase because the working directory is empty. The `qa-rules` skill is not installed, so the `testing-guidelines` rule referenced by the skill was not loaded.
