# Test Plan: Split Payment (Release 5.3)

## 1. Summary

Split payment lets a customer pay one order with two cards through PayGate. The feature touches money movement, an external gateway, and the single-card checkout that processes about 4,000 orders a day. Testing is risk-based: effort goes first to double charging, wrong amounts, and the 60-second automatic refund, then to single-card regression, then to everything else.

The plan fits the hard constraints: four PayGate sandbox days before release, one half-time tester (roughly 5 tester-days), and two developers who share testing work. Anything the sandbox cannot cover in those four days is covered with a PayGate stub or deferred to a documented production verification.

## 2. Assumptions

Where the brief is silent, this plan assumes the following. Each should be confirmed with the product owner on day 1; a wrong assumption changes test cases, not the overall approach.

| # | Assumption |
|---|---|
| A1 | The customer enters an explicit amount for card 1. A "split evenly" or percentage shortcut also exists, which is where the remainder-cent rule applies. If no shortcut exists, the rounding tests reduce to validation of the entered amount. |
| A2 | Card 1 is charged first, then card 2. Charges are sequential, not parallel. |
| A3 | If card 1 is declined, card 2 is not attempted and the order is not placed. |
| A4 | The 60-second refund window starts when PayGate returns the decline for card 2. |
| A5 | Each card amount must be at least PayGate's minimum charge, assumed to be 50 cents, and at most the order total minus that minimum. Zero on either card is rejected. |
| A6 | Card details are never stored by us; PayGate tokenises them. PCI scope does not change. |
| A7 | A single currency per order. No currency conversion between the two cards. |
| A8 | Refunds, partial refunds, and returns after a completed split order are handled by the existing refund flow and are in scope only for a smoke check. |
| A9 | The feature ships behind a feature flag that can be switched off without a deploy. If no flag exists, this is raised as a release blocker on day 1 because it is the only cheap rollback for a money-moving feature. |
| A10 | A PayGate stub or mock exists or can be built by the developers in the first two days, exposing the same response shapes as the sandbox. |
| A11 | Release day is Friday 6 November 2026. Sandbox days are Tuesday 27 October, Thursday 29 October, Tuesday 3 November, and Thursday 5 November. |

## 3. Scope

**In scope**

- Split amount entry, validation, and the remainder-cent rule.
- Two sequential PayGate charges and their outcomes: both succeed, card 1 declined, card 2 declined, timeouts, and gateway errors.
- Automatic refund of card 1 within 60 seconds when card 2 is declined.
- Order state, receipts, and customer-facing messaging for each outcome.
- Idempotency and duplicate submission protection.
- Regression of single-card checkout, including performance under normal daily load.
- Logging, alerting, and reconciliation data for finance and support.

**Out of scope**

- More than two cards.
- Non-card payment methods combined with a card.
- Changes to PayGate itself or its sandbox behaviour.
- Full PCI audit (covered by A6; a short review of what we log is included).
- Load testing of split payment beyond a modest concurrency check, since volume is expected to be a small fraction of orders.

## 4. Risk Analysis

Likelihood and impact are rated High, Medium, or Low. Priority drives order of testing and how much of the sandbox time each item gets.

| ID | Risk | Likelihood | Impact | Priority | Why it matters |
|---|---|---|---|---|---|
| R1 | Card 2 declined and card 1 is not refunded, or refunded late or twice | M | H | P1 | Customer loses money with no goods. Direct chargeback and reputational cost. |
| R2 | Customer is charged more than the order total, through double submission, retry after timeout, or both cards charged the full amount | M | H | P1 | Money error. Retries after gateway timeout are a classic double-charge source. |
| R3 | Rounding or amount arithmetic wrong, including the remainder cent, floating-point conversion, or amounts over cents limits | M | H | P1 | Even a 1 cent error across orders fails reconciliation and erodes trust. |
| R4 | Single-card checkout regresses functionally or slows down | M | H | P1 | 4,000 orders a day. Any breakage costs more than the new feature earns. |
| R5 | Order placed as paid when only one card actually succeeded, or marked failed when both succeeded | M | H | P1 | Fulfilment ships unpaid goods or holds paid orders. |
| R6 | Sandbox unavailable on a planned day, or sandbox cannot simulate a decline on card 2 | M | H | P1 | Removes a quarter of integration test time. Mitigated with a stub. |
| R7 | PayGate timeout or 5xx on card 2 leaves order in an unknown state with no refund or retry | M | M | P2 | Unknown states need manual recovery by support. |
| R8 | Feature flag off path breaks or leaks split UI | L | H | P2 | Rollback must actually work. |
| R9 | Receipts, emails, and order history show wrong per-card amounts or card last-four digits | M | M | P2 | Support load and customer confusion. |
| R10 | Validation allows zero, negative, or over-total amounts on card 1, or accepts the same card twice | M | M | P2 | Garbage orders, gateway rejections, possible exploitation of promo logic. |
| R11 | Sensitive card data or full PAN appears in logs or error messages | L | H | P2 | Compliance breach. |
| R12 | Refund webhook or asynchronous confirmation from PayGate is dropped or arrives out of order | M | M | P2 | Refund recorded as pending forever. |
| R13 | Reconciliation and finance reports cannot tie two charges to one order | M | M | P3 | Month-end pain, not customer-facing. |
| R14 | Accessibility and mobile layout of the split amount control | M | L | P3 | Usability, lower money risk. |
| R15 | Concurrency: two browser tabs or back-button resubmission of the same split order | L | M | P3 | Overlaps R2; tested as part of it. |

## 5. Test Approach

**Layered to protect sandbox time.** The sandbox is the bottleneck, so every scenario is first automated against a PayGate stub that the developers own (A10). Sandbox days are reserved for confirming that the stub's assumptions about PayGate are correct, running the end-to-end decline-and-refund path, and timing the 60-second refund against the real gateway.

**Developers test too.** Each developer owns unit and component tests for their area and runs the stub-based integration suite before every merge. The tester owns exploratory testing, the sandbox sessions, regression, and the release decision inputs.

**Automation first for money paths.** All arithmetic, validation, and state-machine tests are automated and run in CI. Manual effort is spent on exploratory testing, sandbox sessions, and UI checks.

**Regression is mostly reuse.** The existing single-card automated suite runs on every build. A short manual smoke of single-card checkout runs on each sandbox day and on release day.

## 6. Test Design by Risk

### R3: Amount arithmetic (automated unit and API tests, developer-owned, tester reviews)

- Even split of odd totals: 10.01 splits to 5.01 and 5.00; 0.03 splits to 0.02 and 0.01; 99.99 splits to 50.00 and 49.99.
- Even split of even totals produces equal halves with no remainder.
- Card 1 plus card 2 always equals the order total, property-tested across random totals from 1 cent to 9,999,999 cents.
- Inputs arrive as integers in cents end to end; no float appears in the request to PayGate. Verified by asserting the serialised payload.
- Order total changes after the split is chosen (coupon applied, item removed) recalculates or invalidates the split.
- Boundary: card 1 at the minimum charge, card 1 at total minus minimum, card 1 exactly half, card 1 equal to total (should be rejected per A5 or converted to single-card).

### R10: Validation (automated API tests plus manual UI exploration)

- Reject zero, negative, non-numeric, more than two decimal places, and amounts above total.
- Reject the same tokenised card used for both halves. If product decides to allow it, assert both charges still succeed and refund correctly.
- Server-side validation enforced regardless of client; test with direct API calls that bypass the UI.
- Currency symbol, locale decimal separators, and paste of formatted values such as "1,234.56".

### R2, R15: Double charge and idempotency (stub-based automated, confirmed on sandbox)

- Submit the same split checkout twice in quick succession. Expect one order and at most one charge per card.
- Simulate a timeout from PayGate on card 1 where the charge actually succeeded. Expect the retry to use the same idempotency key and not create a second charge.
- Same for card 2.
- Back button after success, then resubmit. Expect rejection or a clean duplicate-order message.
- Two tabs on the same cart submitting different splits.

### R1, R7, R12: Card 2 declined and automatic refund (highest sandbox priority)

- Card 2 hard decline (insufficient funds, do not honour, stolen card codes). Expect card 1 refund issued, order marked failed, customer told clearly which card failed and that the first card has been refunded.
- Refund timing measured from decline response to refund request acknowledged by PayGate. Target under 60 seconds; record the actual value on every run. Also record the time until refund is visible in PayGate's sandbox dashboard, since customers will judge by their statement, not our logs.
- Refund request itself fails or times out. Expect retry with backoff, an alert raised, and the order flagged for manual action. Confirm the retry does not issue a second refund once the first eventually succeeds.
- PayGate returns 5xx or network error on card 2 instead of a clean decline. Expect the same refund path or an explicit unknown-state handling with alerting, never a silent paid order.
- Refund confirmation arrives asynchronously after the order was already marked failed, or arrives twice. Expect idempotent handling.
- The job or worker that processes refunds is down at the time of decline. Expect the refund to be picked up when it restarts and still logged as late if it exceeded 60 seconds.
- Card 1 declined: card 2 is never attempted, no refund is needed, customer can correct and retry.

### R5: Order state (automated state-machine tests plus exploratory)

- Enumerate every combination of outcomes for charge 1, charge 2, and refund and assert the resulting order status, fulfilment eligibility, and customer message. A table of expected results is produced on day 2 and reviewed with the product owner.
- Fulfilment system or downstream event is only triggered on both charges confirmed.
- Order history and admin view show both charges and any refund with amounts and timestamps.

### R4: Single-card regression (automated suite plus manual smoke plus performance)

- Full existing single-card automated suite on every build.
- Manual smoke on each sandbox day: happy path, declined card, 3DS or challenge flow if used, saved card, guest checkout.
- Performance: a 30-minute run at roughly twice the normal peak rate against the stub, comparing checkout latency and error rate to the current release baseline. Assumption: a baseline exists; if not, one is captured on day 1 against the current release.
- Feature flag off: no split UI, no split code path reachable via API, single-card checkout identical to today.

### R8: Feature flag and rollback

- Toggle flag off while a split checkout is in progress. Expect the in-flight order to complete or fail cleanly, not hang.
- Toggle flag on and off without deploy in staging and confirm the change takes effect within the expected propagation time.

### R9: Receipts and communications

- Receipt email, on-screen confirmation, and order history show two lines with correct amounts and last-four digits.
- Failed split order email tells the customer which card was refunded and how long the refund takes to appear.
- Partial refund after a completed split order: smoke check only, confirm the existing flow does not crash and finance can see which card was refunded.

### R11: Data handling

- Review logs, error traces, and analytics events produced during all test runs for PAN, CVV, expiry, or raw card tokens that should not be there.
- Error messages shown to the customer contain no gateway-internal detail.

### R13: Reconciliation

- Export the day's transactions from the stub or sandbox and confirm that finance can link both charges and any refund to one order ID. Done once with a finance representative on the second sandbox day.

### R14: UI and accessibility

- Keyboard-only operation of the split control, screen reader labels for both amounts, mobile viewport layout, and error message placement. One exploratory session.

## 7. Environments and Test Data

| Item | Detail |
|---|---|
| PayGate stub | Developer-owned, deployed to the integration environment, configurable per request to return success, specific decline codes, timeouts, 5xx, and delayed refund confirmations. |
| PayGate sandbox | Tuesdays and Thursdays only. Standard sandbox test cards for success and each decline code. Confirm on day 1 that the sandbox offers a way to force a decline on a second charge; if it does not, the decline-on-card-2 scenario is proven on the stub and only the refund call is proven on sandbox. |
| Staging | Feature flag on, pointed at sandbox on sandbox days and at the stub otherwise. |
| Regression environment | Feature flag off, existing single-card suite and performance baseline. |
| Test data | A fixed set of orders with totals chosen to exercise rounding: 0.01, 0.03, 10.01, 99.99, 100.00, 1,000,000.01. Test cards for success, insufficient funds, do not honour, expired, and stolen. |

## 8. Schedule

Working days run Monday 26 October to Friday 6 November 2026. The tester is available half of each day. Sandbox days are marked.

| Day | Date | Tester (half day) | Developers |
|---|---|---|---|
| 1 | Mon 26 Oct | Confirm assumptions A1 to A11 with product owner. Write outcome-state table. Check sandbox decline-on-card-2 capability and feature flag existence. Capture single-card performance baseline if missing. | Build or extend PayGate stub. Start unit tests for arithmetic and validation. |
| 2 | Tue 27 Oct, sandbox | Sandbox session 1: verify stub matches real responses for success and each decline code. Note any shape differences. Single-card manual smoke. | Fix stub discrepancies. Continue feature build. |
| 3 | Wed 28 Oct | Review developer unit tests against section 6. Write automated API tests for validation and idempotency against the stub. | Arithmetic and validation complete. Idempotency keys implemented. |
| 4 | Thu 29 Oct, sandbox | Sandbox session 2: first end-to-end decline-on-card-2 with refund timing. Reconciliation export with finance. Single-card smoke. | Refund path complete. Alerting wired. |
| 5 | Fri 30 Oct | Exploratory testing of order states, receipts, and UI on stub. Triage defects. | Fix defects from sessions 1 and 2. |
| 6 | Mon 2 Nov | Feature flag on and off tests. Log review for sensitive data. Performance run at twice peak against stub. | Fix defects. Code freeze for new behaviour at end of day. |
| 7 | Tue 3 Nov, sandbox | Sandbox session 3: full P1 and P2 scenario run including timeouts, refund retry, and asynchronous confirmation. Repeat refund timing, five runs minimum. Single-card smoke. | Fixes only. |
| 8 | Wed 4 Nov | Regression suite review, accessibility session, retest fixed defects on stub. Draft release report. | Fixes only. |
| 9 | Thu 5 Nov, sandbox | Sandbox session 4: retest all defects fixed since session 3. Final refund timing. Final single-card smoke. Go or no-go recommendation by end of day. | Fixes only, release candidate cut. |
| 10 | Fri 6 Nov, release | Production verification plan executed after deploy (section 10). Monitor alerts. | On call for rollback. |

**Slack.** There is none. If a sandbox day is lost (R6), the plan is to move that session's scenarios to the stub and ask the product owner to accept the residual risk explicitly, or to slip the release to the next sandbox day, Tuesday 10 November.

## 9. Entry and Exit Criteria

**Entry to sandbox session 3 (day 7)**

- All P1 scenarios pass against the stub in CI.
- No open P1 defects.
- Feature flag verified working.

**Exit for release recommendation**

- All P1 scenarios passed on the real sandbox in session 3 or 4.
- Refund timing under 60 seconds in every measured run on sandbox, with the median and worst case recorded in the release report.
- Single-card regression suite green on the release candidate, and the performance run shows no more than a 5 percent increase in median checkout latency and no increase in error rate against the baseline.
- No open defects rated High in money, order state, or refund areas. Open Medium defects have a product owner sign-off and a support workaround.
- Alerting confirmed to fire for refund failures and unknown-state orders in staging.
- Rollback through the feature flag demonstrated in staging.

## 10. Production Verification and Rollback

Because the sandbox cannot fully replicate production PayGate behaviour, release day includes a controlled verification.

1. Deploy with the feature flag off. Confirm single-card checkout is unaffected using production monitoring for 30 minutes.
2. Enable the flag for internal users only, if the flag supports targeting. Otherwise enable for all with the team watching.
3. Place one real split order with two company test cards for a small amount. Confirm both charges and the receipt.
4. Place one real split order where card 2 is a card known to decline, for example an expired company card. Confirm the automatic refund and its timing in PayGate's live dashboard.
5. Monitor for 2 hours: split order count, split failure rate, refund latency, refund failures, unknown-state orders, and single-card error rate.
6. Rollback trigger: any refund failure, any order in unknown state, any double charge, or single-card error rate above baseline. Rollback action is flag off, then investigate.

## 11. Roles

| Role | Responsibility |
|---|---|
| Tester | Owns this plan, exploratory testing, sandbox sessions, regression sign-off, release report, go or no-go recommendation. |
| Developer 1 | PayGate stub, arithmetic and validation unit tests, idempotency tests. |
| Developer 2 | Refund path and state-machine tests, alerting, feature flag tests. |
| Product owner | Confirms assumptions on day 1, signs off outcome-state table and any accepted residual risk. |
| Finance representative | One hour on day 4 for reconciliation check. |
| Support lead | Reviews customer-facing messages for failed split orders by day 5. |

## 12. Defect Handling

Defects are triaged daily at a 15-minute stand-up. Severity is set by money impact first, customer visibility second. Any defect that can cause a customer to be charged more than the order total, or not be refunded, is a release blocker regardless of how rare it appears.

## 13. Residual Risks Accepted at Release

These remain even if every exit criterion is met and should be stated in the release report.

- Refund timing is measured on sandbox, which may be faster or slower than production PayGate. Mitigated by the production verification step and the refund latency alert.
- Sandbox decline codes may not cover every real-world decline reason. Mitigated by treating any unrecognised decline as a decline and refunding.
- Only four sandbox sessions means some P3 scenarios are proven on the stub only. Listed individually in the release report.
- Half-time tester capacity leaves no time for load testing split payment at volume. Acceptable because split orders are expected to be a small share of total orders; revisit if adoption exceeds 10 percent of checkouts.
