# LOY-3 Loyalty points — BDD scenarios

**Context discovery.** The working directory contains no source code, so nothing below is verified against a real system. Every step is derived from the ticket text and the assumptions listed next. Treat the scenarios as candidates for the Three Amigos session, not as verified behaviour.

## Assumptions (ticket is silent)

| # | Assumption | Why it matters |
| --- | --- | --- |
| A1 | Points are earned on the order **subtotal before** the tier discount and before any redeemed points are deducted. | AC-1 says "subtotal"; otherwise discounts would shrink earnings and the examples would differ. |
| A2 | Tier is based on **lifetime points earned**, not the current balance, so redeeming points never demotes a member. | AC-2 says "points" without saying which; balance-based tiers would punish redemption. Flagged for the PO. |
| A3 | A tier reached by an order applies from the **next** order, not the one that earned it. | Avoids circular pricing within one checkout. |
| A4 | Redemption value is **100 points = $1.00**, applied after the tier discount. | Ticket gives no exchange rate; needed for the happy path. |
| A5 | AC-4 "load fast" is read as **the points page is interactive within 2 seconds at the 95th percentile** on the reference staging environment. | "Fast" is not measurable; the number is a placeholder to be confirmed. |
| A6 | Points are credited when an order is **placed**, not on delivery, and no points are earned on a cancelled order. | Needed for the earning scenario and a QA-added cancellation check. |
| A7 | Tier thresholds are inclusive at the lower edge: 500 is Silver, 2,000 is Gold. | AC-2 says "from 500" and "from 2,000". |
| A8 | Basic members get no discount. | AC-2 lists only Silver and Gold discounts. |

## AC quality check (SMART)

- **AC-1** Specific, measurable, testable. Needs confirmation of rounding on exact whole dollars and on amounts under $1.
- **AC-2** Testable once A2 and A3 are confirmed. Two rules are bundled (tier assignment and discount); the scenarios split them.
- **AC-3** Specific and testable. Exact message text is given. Missing: zero, negative, and non-numeric redemption inputs (added by QA).
- **AC-4** Not measurable as written. Rewritten under A5; it must be a non-functional check with a stated threshold and environment.

## Feature file

```gherkin
@loyalty @LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member
    And prices are shown in US dollars

  # ---------- AC-1: earning ----------

  @smoke @p0 @earn
  Scenario: Placing an order earns one point per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance is 24
    And the order confirmation shows "You earned 24 points"

  @regression @p1 @earn
  Scenario Outline: Points are earned on the whole-dollar part of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 24.99    | 24     |
      | 100.00   | 100    |
      | 499.99   | 499    |

  # Added by QA, the ticket does not say whether the tier discount reduces earned points (assumption A1)
  @regression @p1 @earn
  Scenario: Points are earned on the subtotal before the tier discount
    Given I am a Silver member
    And my points balance is 600
    When I place an order with a subtotal of $100.00
    Then the order total is $95.00
    And my points balance is 700

  # Added by QA, the ticket does not cover order cancellation (assumption A6)
  @regression @p2 @earn
  Scenario: Cancelling an order removes the points it earned
    Given my points balance is 0
    And I placed an order with a subtotal of $40.00
    When I cancel that order
    Then my points balance is 0

  # ---------- AC-2: tiers ----------

  @smoke @p0 @tier
  Scenario Outline: Tier is assigned from lifetime points earned
    Given I have earned <lifetime> points in total
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples:
      | lifetime | tier   |
      | 0        | Basic  |
      | 499      | Basic  |
      | 500      | Silver |
      | 1999     | Silver |
      | 2000     | Gold   |
      | 5000     | Gold   |

  @smoke @p0 @tier @discount
  Scenario Outline: Tier discount is applied to every order
    Given I am a <tier> member
    When I place an order with a subtotal of $100.00
    Then the order shows a loyalty discount of $<discount>
    And the order total is $<total>

    Examples:
      | tier   | discount | total  |
      | Basic  | 0.00     | 100.00 |
      | Silver | 5.00     | 95.00  |
      | Gold   | 10.00    | 90.00  |

  @regression @p1 @tier
  Scenario: Reaching the Silver threshold promotes the member for the next order
    Given I have earned 480 points in total
    And my tier is "Basic"
    When I place an order with a subtotal of $20.00
    Then that order has no loyalty discount
    And my tier is shown as "Silver"
    And my next order with a subtotal of $100.00 has a loyalty discount of $5.00

  # Added by QA, the ticket does not say whether redeeming points can lower a tier (assumption A2)
  @regression @p1 @tier
  Scenario: Redeeming points does not lower the tier
    Given I have earned 2,000 points in total
    And my points balance is 2,000
    When I redeem 1,900 points on an order
    Then my points balance is 100
    And my tier is still shown as "Gold"

  # ---------- AC-3: redemption ----------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    When I try to redeem 101 points on an order
    Then I see the message "You don't have enough points."
    And my points balance is still 100
    And the order total is unchanged

  @smoke @p0 @redeem
  Scenario: Redeeming points within the balance discounts the order
    Given my points balance is 500
    When I redeem 300 points on an order with a subtotal of $50.00
    Then the order shows a points discount of $3.00
    And the order total is $47.00
    And my points balance is 200

  @regression @p1 @redeem
  Scenario: Redeeming the exact balance is allowed and leaves zero
    Given my points balance is 250
    When I redeem 250 points on an order with a subtotal of $50.00
    Then the order shows a points discount of $2.50
    And my points balance is 0

  # Added by QA, the ticket only covers the "too many" case; zero, negative and non-numeric input are undefined
  @regression @p2 @redeem
  Scenario Outline: Invalid redemption amounts are rejected without changing the balance
    Given my points balance is 100
    When I try to redeem "<amount>" points on an order
    Then I see a validation message
    And my points balance is still 100

    Examples:
      | amount |
      | 0      |
      | -10    |
      | abc    |
      | 10.5   |

  # Added by QA, the combined discount order is undefined (assumption A4)
  @regression @p1 @redeem @discount
  Scenario: Points redemption is applied after the tier discount
    Given I am a Gold member
    And my points balance is 1,000
    When I redeem 1,000 points on an order with a subtotal of $100.00
    Then the order shows a loyalty discount of $10.00
    And the order shows a points discount of $10.00
    And the order total is $80.00

  # ---------- AC-4: performance ----------

  # Rewritten by QA, "load fast" is not measurable; threshold and environment are assumption A5
  @nonfunctional @performance @p2
  Scenario: Points page is interactive within the agreed time
    Given the staging environment is under normal load
    And my account has 10,000 points transactions
    When I open the points page 20 times
    Then the page is interactive within 2 seconds in at least 19 of the 20 loads
```

## Step definitions (Playwright + Cucumber, TypeScript)

The stack is not stated, so Playwright with TypeScript is assumed. Selectors use `data-testid` values that do not yet exist and must be agreed with the developers.

```typescript
// steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

Given("I am signed in as a loyalty programme member", async function () {
  await this.page.goto(process.env.BASE_URL ?? "http://localhost:3000/");
  await this.page.getByLabel("Email").fill(process.env.TEST_EMAIL!);
  await this.page.getByLabel("Password").fill(process.env.TEST_PASSWORD!);
  await this.page.getByRole("button", { name: /sign in/i }).click();
});

Given("my points balance is {int}", async function (balance: number) {
  // Test data seeded through the API, not the UI
  await this.api.post("/test/loyalty/balance", { data: { balance } });
});

Given("I have earned {int} points in total", async function (lifetime: number) {
  await this.api.post("/test/loyalty/lifetime", { data: { lifetime } });
});

Given("I am a {word} member", async function (tier: string) {
  const lifetime = { Basic: 0, Silver: 500, Gold: 2000 }[tier];
  await this.api.post("/test/loyalty/lifetime", { data: { lifetime } });
});

When("I place an order with a subtotal of ${float}", async function (subtotal: number) {
  await this.checkout.placeOrderWithSubtotal(subtotal); // page object
});

When("I try to redeem {int} points on an order", async function (points: number) {
  await this.page.getByTestId("redeem-points-input").fill(String(points));
  await this.page.getByTestId("redeem-points-apply").click();
});

When("I open the points page", async function () {
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
  await expect(this.page.getByTestId("loyalty-tier")).toHaveText(tier);
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("the order total is ${float}", async function (total: number) {
  await expect(this.page.getByTestId("order-total")).toHaveText(`$${total.toFixed(2)}`);
});

Then("the order shows a loyalty discount of ${float}", async function (amount: number) {
  await expect(this.page.getByTestId("tier-discount")).toHaveText(`-$${amount.toFixed(2)}`);
});
```

The performance scenario should not run through Cucumber. Measure it with a Playwright trace or k6 against the agreed threshold and report the 95th percentile.

## Questions for the Three Amigos

1. Is the tier based on lifetime points or current balance? Scenarios assume lifetime (A2). The answer changes two scenarios.
2. What is one point worth at redemption, and is there a minimum redemption? Scenarios assume 100 points = $1.00 (A4).
3. Are points earned on the subtotal before or after the tier discount and before or after redemption? Scenarios assume before both (A1).
4. Does a newly reached tier discount the order that reached it, or only later orders? Scenarios assume later orders (A3).
5. What happens to earned points when an order is cancelled or refunded? Scenarios assume they are removed (A6).
6. What is the measurable target behind "load fast", and on which environment? Scenarios assume 2 seconds at the 95th percentile on staging (A5).
7. Which `data-testid` attributes will the points page and checkout expose for automation?

**Rules not applied.** The `qa-rules` skill is not installed, so the `context-discovery` and `testing-guidelines` rule texts were not available. Context discovery was done by searching the working directory, which is empty.
