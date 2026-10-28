# Test Plan: Split Payment (Release 5.3)

## 1. Summary

This plan concentrates effort on the places where split payment can lose or duplicate money: the cent arithmetic, the compensating refund, and ambiguous gateway outcomes. The second priority is protecting the existing single-card checkout. Most testing runs against a scripted PayGate mock every day. The four available sandbox windows are reserved for verifying that the mock matches real gateway behaviour and for end-to-end proof of the refund path.

| Item | Value |
|---|---|
| Plan date | Saturday 24 October 2026 |
| Test window | Monday 26 October to Thursday 5 November 2026 |
| Release date | Friday 6 November 2026 |
| PayGate sandbox windows | Tue 27 Oct, Thu 29 Oct, Tue 3 Nov, Thu 5 Nov |
| Tester capacity | About 5 person-days total |
| Developer test contribution assumed | About 1.5 person-days each |

## 2. Assumptions

Where the brief is silent, this plan proceeds on the following. Each is confirmed or corrected on day 1.

- **Split entry.** The customer types the first-card amount in major currency units. A separate "split evenly" option exists. The remainder-cent rule applies to that option and to any percentage-based split. The server, not the browser, computes and validates the final cent amounts.
- **Charge order.** Card 1 is charged first, then card 2. Charges are immediate captures. If the implementation uses authorise-then-capture, every "refund" case below is also run as a void.
- **Minimum amounts.** Each card must carry at least one cent, and at least PayGate's minimum charge. The PayGate minimum is confirmed in sandbox session 1.
- **Same card twice** is permitted and treated as two charges.
- **Single currency** per order. No multi-currency splits.
- **The 60-second clock** starts when the card 2 decline is received and stops when PayGate accepts the refund request. Settlement time is outside the measure.
- **Feature flag.** Split payment ships behind a server-side flag that defaults to off, and the flag can be flipped without a deploy.
- **PayGate** supports idempotency keys, a status-lookup call, distinct decline codes, and sandbox test cards that force approve, decline, and timeout. Confirmed in session 1.
- **Regression suite.** An automated single-card checkout suite exists. If it does not, the developers build a smoke subset of about ten scenarios in week 1 and this plan absorbs the cost.
- **No load environment.** Performance is covered by latency inspection in sandbox and by production monitoring after release.
- **Tester schedule.** The half-time tester concentrates hours on Tuesdays and Thursdays so that sandbox windows get full days.

## 3. Scope

In scope: split arithmetic and validation, two-charge orchestration, the automatic refund and its failure modes, idempotency, order and ledger state, receipts and reporting, feature flag behaviour, single-card checkout regression, security of amount handling, and operational alerting.

Out of scope: PayGate's own correctness, load testing beyond inspection, accessibility beyond a keyboard pass of the new form, and any wallet or non-card payment methods.

## 4. Risk Analysis

Priority drives effort. P1 risks get mock testing, sandbox verification, and a release-day check. P2 risks get mock testing and one sandbox pass. P3 risks get exploratory coverage only.

| ID | Risk | Likelihood | Impact | Priority |
|---|---|---|---|---|
| R1 | Split amounts do not sum to the order total, or the remainder cent lands on the wrong card. Customer is over- or under-charged. | Medium | High | P1 |
| R2 | Card 2 declines and the card 1 refund is missing, late, or duplicated. | Medium | High | P1 |
| R3 | Ambiguous outcome. Card 2 times out but actually succeeded. System refunds card 1 and the order is half paid. | Medium | High | P1 |
| R4 | Order marked paid or released to fulfilment with only one charge captured, for example after a crash between charges. | Medium | High | P1 |
| R5 | Double charge or double refund from customer double-submit, retries, or duplicate webhooks. | Medium | High | P1 |
| R6 | Refund itself fails or times out, with no alert and no operations queue. | Medium | High | P1 |
| R7 | Regression in single-card checkout, which carries about 4,000 orders a day. | Low to medium | Critical | P1 |
| R8 | Browser-side tampering of split amounts accepted by the server. Card data appears in logs. | Low | High | P2 |
| R9 | Ledger, receipts, and settlement reports do not reflect two charges and a refund. Finance reconciliation breaks. | Medium | Medium | P2 |
| R10 | 3-D Secure challenge on card 2 abandoned by the customer, leaving card 1 charged. | Medium | High | P2 |
| R11 | Poor validation and error messaging for amounts and partial failures. Customers retry and compound R5. | High | Medium | P2 |
| R12 | Doubled gateway latency pushes checkout past existing timeouts. | Low | Medium | P3 |

Plan-level risks are in section 10.

## 5. Test Approach

### 5.1 Unit and property tests for split arithmetic (R1, developers, tester reviews)

The developers write these on day 3 with the tester pairing. The invariants under test:

- Card 1 plus card 2 always equals the order total in cents.
- For an even split, card 1 minus card 2 is zero or one cent, never negative.
- Neither card amount is below the minimum, and neither is negative.
- All arithmetic is integer cents. No floating point anywhere in the path.

Worked examples the tester supplies as acceptance cases:

| Order total | Split request | Expected card 1 | Expected card 2 |
|---|---|---|---|
| 100.01 | even | 50.01 | 50.00 |
| 0.03 | even | 0.02 | 0.01 |
| 0.01 | even | rejected, cannot split | |
| 99.99 | card 1 = 99.99 | rejected, card 2 would be zero | |
| 99.99 | card 1 = 100.00 | rejected, exceeds total | |
| 99.99 | card 1 = 33.333 | rejected, more than two decimals | |
| 99.99 | card 1 = -5 | rejected | |
| 1,234.56 | card 1 = "1,234" | accepted as 1234.00 or rejected, per locale rule, but never silently parsed as 1.234 | |
| 10.00 | card 1 = 0 | rejected | |
| 10.00 | card 1 = 33% | 3.30 | 6.70 |
| 10.01 | card 1 = 50% | 5.01 | 5.00 |

### 5.2 Orchestration tests against a scripted PayGate mock (R2 to R6, R10, R12)

The developers build a mock that can be scripted per request to return approve, hard decline, soft decline, timeout, HTTP 5xx, slow response, duplicate webhook, and refund failure. The tester writes the scenarios. This runs every day and in the build pipeline, so it does not depend on sandbox availability.

| Card 1 | Card 2 | Expected behaviour |
|---|---|---|
| Approved | Approved | Order paid. Two charge records. Receipt shows both amounts. |
| Declined | Not attempted | No charge anywhere. Customer can correct and retry. |
| Approved | Hard decline | Refund of card 1 requested within 60 seconds. Order remains unpaid. Customer told clearly that card 1 has been refunded. |
| Approved | Soft decline | Same as hard decline. No automatic retry of card 2 without customer action. |
| Approved | Timeout or 5xx | System queries PayGate for card 2 status before deciding. No refund until status is known. If card 2 actually succeeded, order is paid. |
| Approved | Declined, refund declined | Retry with backoff. Alert fires. Order appears in an operations queue. Customer message is honest about the state. |
| Approved | Declined, refund times out | Status lookup before any retry. Exactly one refund ever lands. |
| Approved | Process killed before card 2 | On restart, a recovery job either completes or refunds. No orphan charge survives longer than the 60-second target. |
| Approved | 3-D Secure challenge abandoned | Treated as decline after the challenge timeout. Refund follows. |
| Double submit from the browser | | One charge per card. Second submission gets the result of the first. |
| Duplicate decline webhook | | One refund, not two. |
| Flag off mid-flight | | In-flight split completes or compensates. New sessions see single-card only. |

Timing of the 60-second target is measured in every decline scenario and recorded.

### 5.3 Sandbox sessions (tester-led, Tuesdays and Thursdays)

Each session has a primary objective and a fallback if the build is not ready.

| Session | Date | Primary objective | Fallback if build not ready |
|---|---|---|---|
| 1 | Tue 27 Oct | Characterise PayGate. Confirm test cards, decline codes, idempotency behaviour, status lookup, refund latency, minimum charge. Capture real responses as mock fixtures. | None needed. This session does not depend on the feature. |
| 2 | Thu 29 Oct | Happy path end to end. One decline and refund end to end. Compare mock fixtures to live responses and correct the mock. | Repeat session 1 for refund edge cases and 3-D Secure test cards. |
| 3 | Tue 3 Nov | Full compensation matrix from 5.2 against the real sandbox. Twenty timed decline-and-refund runs. Timeout and status-lookup cases. 3-D Secure abandon. | Partial matrix on whatever is deployable. Raise schedule risk. |
| 4 | Thu 5 Nov | Release candidate regression. Re-run every P1 scenario. Single-card checkout smoke against sandbox. Go or no-go evidence. | No fallback. Missing this session triggers the contingency in section 10. |

### 5.4 Single-card checkout regression (R7)

- Automated suite runs on every build with the flag off and with the flag on.
- Manual smoke of the top five single-card journeys on each sandbox day.
- Diff review of every change touching shared payment code, with the tester present for the walkthrough.
- Release day: flag off deploy first, then single-card smoke in production before the flag is turned on for anyone.

### 5.5 Security and data handling (R8)

- Server rejects any request where the submitted amounts do not sum to the server-held order total.
- Replay a captured checkout request with modified amounts and confirm rejection.
- Grep application and gateway logs from a test run for card numbers, CVV, and expiry. None may appear.
- Confirm the new endpoint sits behind the same authentication and rate limiting as the existing checkout.

### 5.6 Reporting and operations (R6, R9)

- Ledger shows two charge entries and, on compensation, one refund entry, all tied to one order ID.
- Customer receipt and email show both cards and both amounts. The refund email names the amount and last four digits of the correct card.
- Settlement export for a test day reconciles to the cent.
- The refund-failure alert is triggered deliberately in staging and reaches the on-call channel.
- An operations runbook exists for a stuck half-paid order and is walked through once by someone who did not write it.

### 5.7 Exploratory sessions (R11)

Two timed sessions of ninety minutes each, one on the split entry form and one on error messaging after partial failure. Charters cover keyboard-only entry, browser back button after card 1 success, session expiry between charges, and mobile viewport.

### 5.8 Release verification

- Deploy with the flag off. Run single-card production smoke.
- Enable the flag for internal staff accounts only.
- Place one real low-value split order that succeeds, and one that uses a known-declining card for card 2. Confirm the real refund arrives and the ledger reconciles.
- Enable for a small percentage of customers. Watch refund latency, refund failure count, and single-card conversion for 24 hours before full rollout.

## 6. Schedule

| Day | Date | Tester focus | Developer test tasks |
|---|---|---|---|
| 1 | Mon 26 Oct | Confirm assumptions. Risk review with developers. Write scenario tables. Request sandbox credentials and test cards. | Agree mock interface and failure-injection hooks. Confirm regression suite status. |
| 2 | Tue 27 Oct | Sandbox session 1. | Start mock using captured fixtures. |
| 3 | Wed 28 Oct | Pair on arithmetic property tests. Review mock. | Property tests. Mock complete. |
| 4 | Thu 29 Oct | Sandbox session 2. | Fix mock divergences found in session. |
| 5 | Fri 30 Oct | Compensation matrix against mock. Crash and timeout injection. | Failure-injection support. Alerting wired. |
| 6 | Mon 2 Nov | Single-card regression with flag on and off. Security checks. Reporting checks. | Defect fixes. |
| 7 | Tue 3 Nov | Sandbox session 3. | Attend session for live debugging. |
| 8 | Wed 4 Nov | Retest fixes against mock. Exploratory sessions. Runbook walkthrough. | Defect fixes. Code freeze at end of day. |
| 9 | Thu 5 Nov | Sandbox session 4. Test summary and go or no-go recommendation. | Only fixes for blockers found in session 4. |
| 10 | Fri 6 Nov | Release verification per 5.8. Monitoring. | Deploy. Flag control. On-call. |

## 7. Entry and Exit Criteria

Entry to sandbox session 3 requires: all scenarios in 5.2 passing against the mock, property tests green, and no open severity 1 defects.

Exit for release requires all of the following:

- Every P1 scenario passed in sandbox session 3 or 4.
- Twenty timed decline-and-refund runs in sandbox, all under 60 seconds, with the slowest recorded in the summary.
- Zero open severity 1 or 2 defects. Severity 3 defects have an owner and a target.
- Single-card regression suite green on the release build with the flag on and off.
- Refund-failure alert demonstrated end to end.
- Runbook for half-paid orders reviewed and published.
- Feature flag rollback demonstrated on staging.

## 8. Defect Severity

| Severity | Definition | Example |
|---|---|---|
| 1 | Money lost, duplicated, or stuck. Single-card checkout broken. | Refund not issued. Double charge. |
| 2 | Wrong amount or wrong state visible to customer or finance, but recoverable. | Remainder cent on card 2. Receipt shows one card. |
| 3 | Functional defect with a workaround. | Validation message unclear. |
| 4 | Cosmetic. | Alignment on the split form. |

## 9. Roles

- **Tester:** owns this plan, scenario tables, all sandbox sessions, exploratory sessions, regression execution, security checks, the test summary, and the go or no-go recommendation.
- **Developers:** own property tests, the PayGate mock, failure-injection hooks, alerting, the regression suite, and attend sandbox sessions 3 and 4.
- **Product or release owner:** confirms the assumptions in section 2 on day 1, and makes the go or no-go call. Assumed to exist.

Daily status goes to the team channel in three lines: what passed, what failed, what is blocked.

## 10. Plan Risks and Contingencies

- **Only four sandbox windows, and the last is the day before release.** Mitigation: the mock is corrected against real responses in sessions 1 and 2 so later confidence does not rest on sandbox alone. Contingency: if session 4 is lost or fails, release ships with the flag off and the flag is enabled only after a fifth session on Tuesday 10 November.
- **Build slips past Thursday 29 October.** Session 2 falls back to gateway characterisation. If the full feature is not in sandbox by session 3, recommend a no-go for Friday 6 November and a release on Tuesday 10 November after a sandbox pass that morning.
- **Half-time tester.** Sandbox days get full days from the tester. Developers absorb mock scenario execution on days 5 and 8 if the tester runs short.
- **Sandbox behaviour differs from production.** Accepted residual risk. Reduced by the staged rollout in 5.8 and the live decline test with a real card on release day.
- **No load testing.** Accepted residual risk. Latency per gateway call is recorded in sandbox and compared with the current single-card timeout budget. Production rollout is percentage-based so a latency problem affects few customers.
- **Regression suite may not exist.** If confirmed on day 1, the smoke subset is built on days 1 to 3 and the exploratory sessions shrink to one.
