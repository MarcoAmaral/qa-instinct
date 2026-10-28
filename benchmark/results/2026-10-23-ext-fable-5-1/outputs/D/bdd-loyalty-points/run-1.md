The workspace is empty, so the scenarios below are drafted from the story alone. Every assumption is stated up front.

# LOY-3 — Loyalty points: BDD scenarios

## Context discovery

The working directory contains no source code, feature files or documentation, so no scenario below is verified against a real implementation. Everything is derived from the four acceptance criteria and marked where QA had to infer a rule.

## Assumptions

Each assumption fills a gap in the story; confirm or correct them in Three Amigos.

| # | Assumption | Why it matters |
| - | ---------- | -------------- |
| A1 | "Subtotal" is the merchandise total before shipping, tax and discounts. | AC-1 does not say; points on a discounted or taxed amount would differ. |
| A2 | Points are credited when the order is placed, not when it ships or clears a return window. | AC-1 does not say when the balance updates. |
| A3 | Tier is derived from the current points balance, so redeeming points can drop a member's tier. | AC-2 ties tier to "points" without saying earned-to-date versus current balance. |
| A4 | The tier discount is applied to the order subtotal; points are then earned on that discounted subtotal (per A1 the subtotal after discount). | AC-1 and AC-2 interact and the story does not say which wins. |
| A5 | A member redeems points by entering an amount on the points page or at checkout; the exact point-to-dollar rate is unspecified, so scenarios assert only on the balance and the message. | AC-3 defines only the over-redemption case. |
| A6 | Redeeming exactly the full balance is allowed and leaves zero points. | AC-3 says "more than"; the boundary needs a scenario. |
| A7 | Redeeming zero or a negative amount is rejected with a validation message; the wording is unspecified, so the scenario asserts the balance is unchanged and some error is shown. | AC-3 is silent. |
| A8 | "Load fast" is read as the page reaching a usable state within 2 seconds on a member with up to 10,000 point transactions, at the 95th percentile. | AC-4 is not measurable as written; see the AC quality check. |
| A9 | Points, tier and discount are shown on a single "points page" under the member's account. | Needed for Then steps to name an observable surface. |

## AC quality check (SMART)

| AC | Verdict | Notes |
| -- | ------- | ----- |
| AC-1 | Pass | Specific and measurable; the example nails rounding down. Timing of credit unspecified (A2). |
| AC-2 | Pass with gaps | Thresholds are clear. "Points" is ambiguous between balance and lifetime earned (A3). Does Basic get 0% discount? Assumed yes. |
| AC-3 | Pass with gaps | Message and outcome are concrete. Exact-balance and zero or negative inputs undefined (A6, A7). |
| AC-4 | Fail | "Fast" is not measurable. Rewritten under A8; the scenario is tagged `@candidate` until the product owner sets a number. |

## Feature file

```gherkin
@loyalty @LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------- AC-1: earning points ----------

  @smoke @p0 @earn
  Scenario: Points are earned on every whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance is 24

  @regression @p1 @earn
  Scenario Outline: Points are rounded down to the whole dollar
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | 0.00     | 0      |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 1.01     | 1      |
      | 24.99    | 24     |
      | 25.00    | 25     |
      | 499.99   | 499    |
      | 1999.99  | 1999   |

  # Added by QA, the story does not say points accumulate across orders
  @regression @p1 @earn
  Scenario: Points from several orders accumulate
    Given my points balance is 100
    When I place an order with a subtotal of $50.00
    And I place an order with a subtotal of $10.50
    Then my points balance is 160

  # Added by QA, assumption A1: points are earned on the subtotal, not on shipping or tax
  @regression @p2 @earn
  Scenario: Shipping and tax do not earn points
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, shipping of $9.99 and tax of $3.20
    Then my points balance is 40

  # ---------- AC-2: tiers and tier discounts ----------

  @smoke @p0 @tier
  Scenario Outline: Tier is determined by the points balance
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
      | 50000  | Gold   |

  @smoke @p0 @tier @discount
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <points>
    And my tier is "<tier>"
    When I add items with a subtotal of $100.00 to my basket
    And I proceed to checkout
    Then a loyalty discount of $<discount> is shown
    And the order total before shipping and tax is $<total>

    Examples:
      | points | tier   | discount | total  |
      | 100    | Basic  | 0.00     | 100.00 |
      | 500    | Silver | 5.00     | 95.00  |
      | 2000   | Gold   | 10.00    | 90.00  |

  # Added by QA, the story does not say whether crossing a threshold takes effect immediately
  @regression @p1 @tier
  Scenario: Tier upgrades as soon as the threshold is reached
    Given my points balance is 480
    And my tier is "Basic"
    When I place an order with a subtotal of $20.00
    Then my points balance is 500
    And my tier is shown as "Silver"

  # Added by QA, assumption A3: tier follows the current balance, so redeeming can lower it
  @regression @p1 @tier @redeem
  Scenario: Tier drops when a redemption takes the balance below the threshold
    Given my points balance is 500
    And my tier is "Silver"
    When I redeem 1 point
    Then my points balance is 499
    And my tier is shown as "Basic"

  # Added by QA, assumption A4: AC-1 and AC-2 interact and the story does not say which applies first
  @regression @p1 @earn @discount
  Scenario: Points are earned on the subtotal after the tier discount
    Given my points balance is 2000
    And my tier is "Gold"
    When I place an order with a subtotal of $100.00
    Then a loyalty discount of $10.00 is applied
    And I earn 90 points
    And my points balance is 2090

  # ---------- AC-3: redeeming points ----------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    When I redeem 101 points
    Then I see the message "You don't have enough points."
    And my points balance is still 100
    And no discount is applied to my order

  # Added by QA, happy path for redemption is implied by the story but has no AC
  @smoke @p0 @redeem
  Scenario: Redeeming part of the balance reduces it by the redeemed amount
    Given my points balance is 100
    When I redeem 40 points
    Then my points balance is 60
    And the redemption is applied to my order

  # Added by QA, assumption A6: the boundary of "more than the balance"
  @regression @p1 @redeem
  Scenario: Redeeming exactly the balance leaves zero points
    Given my points balance is 100
    When I redeem 100 points
    Then my points balance is 0
    And I do not see the message "You don't have enough points."

  # Added by QA, assumption A7: zero and negative amounts are not covered by AC-3
  @regression @p2 @redeem
  Scenario Outline: Redeeming an invalid amount is rejected without changing the balance
    Given my points balance is 100
    When I redeem <amount> points
    Then a validation error is shown
    And my points balance is still 100

    Examples:
      | amount |
      | 0      |
      | -1     |
      | 1.5    |

  # Added by QA, a member with no points is the most common state for a new member
  @regression @p2 @redeem
  Scenario: A member with no points cannot redeem any
    Given my points balance is 0
    When I redeem 1 point
    Then I see the message "You don't have enough points."
    And my points balance is still 0

  # Added by QA, two redemptions of the same balance must not both succeed
  @regression @p1 @redeem
  Scenario: A repeated submission cannot redeem the same points twice
    Given my points balance is 100
    When I submit a redemption of 100 points twice in quick succession
    Then exactly one redemption is applied
    And my points balance is 0
    And the second submission shows the message "You don't have enough points."

  # ---------- AC-4: points page performance ----------

  # Assumption A8: "fast" rewritten as a measurable target pending product owner confirmation
  @candidate @nonfunctional @performance @p2
  Scenario: The points page loads within the agreed time
    Given I have 10000 point transactions in my history
    When I open the points page
    Then my balance, tier and transaction history are visible within 2 seconds
    And the 95th percentile load time over 20 visits is at most 2 seconds
```

## Open questions for Three Amigos

- Does "points" in AC-2 mean the current balance or lifetime points earned? The two produce opposite results in the tier-drop scenario.
- What is the point-to-dollar redemption rate, and can points be redeemed only at checkout or also from the points page?
- Are points earned on the discounted subtotal or the undiscounted one?
- What is the number behind "fast" in AC-4? The scenario is tagged `@candidate` until it is set.
- What happens to earned points when an order is cancelled or refunded? No AC covers it and no scenario is written for it.

## Step definitions (Playwright + Cucumber, TypeScript)

```typescript
// features/loyalty-points.feature -> steps/loyaltySteps.ts
import { Given, When, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

Given("I am signed in as a loyalty programme member", async function () {
  await this.page.goto(process.env.BASE_URL ?? "http://localhost:3000/");
  await this.page.getByLabel("Email").fill(process.env.TEST_MEMBER_EMAIL!);
  await this.page.getByLabel("Password").fill(process.env.TEST_MEMBER_PASSWORD!);
  await this.page.getByRole("button", { name: /sign in/i }).click();
});

Given("my points balance is {int}", async function (points: number) {
  // Seeds the balance through a test-only API; replace with the project's fixture.
  await this.api.post("/test/loyalty/balance", { data: { points } });
});

Given("my tier is {string}", async function (tier: string) {
  await this.page.goto("/account/points");
  await expect(this.page.getByTestId("loyalty-tier")).toHaveText(tier);
});

When("I place an order with a subtotal of ${float}", async function (subtotal: number) {
  await this.api.post("/test/orders", { data: { subtotal } });
});

When("I open the points page", async function () {
  await this.page.goto("/account/points");
});

When("I redeem {int} points", async function (amount: number) {
  await this.page.goto("/account/points");
  await this.page.getByTestId("redeem-amount-input").fill(String(amount));
  await this.page.getByRole("button", { name: /redeem/i }).click();
});

Then("my points balance is {int}", async function (points: number) {
  await this.page.goto("/account/points");
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(points));
});

Then("my points balance is still {int}", async function (points: number) {
  await expect(this.page.getByTestId("points-balance")).toHaveText(String(points));
});

Then("my tier is shown as {string}", async function (tier: string) {
  await expect(this.page.getByTestId("loyalty-tier")).toHaveText(tier);
});

Then("I see the message {string}", async function (message: string) {
  await expect(this.page.getByRole("alert")).toHaveText(message);
});

Then("I do not see the message {string}", async function (message: string) {
  await expect(this.page.getByText(message)).toHaveCount(0);
});

Then("a loyalty discount of ${float} is shown", async function (discount: number) {
  await expect(this.page.getByTestId("loyalty-discount")).toHaveText(
    `$${discount.toFixed(2)}`
  );
});
```

The `data-testid` values above are proposals, since no implementation exists to read them from. Agree them with the developer before automation starts.
