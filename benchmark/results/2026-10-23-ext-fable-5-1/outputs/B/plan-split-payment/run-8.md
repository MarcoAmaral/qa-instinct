# Test Plan: Split Payment (Release 5.3)

## 1. Summary

Split payment lets a customer pay one order with two cards through PayGate. The two highest risks are breaking the existing single-card checkout and leaving a customer charged on card one when card two is declined. This plan spends most of the limited effort on those two risks, uses a local PayGate stub on non-sandbox days, and reserves the four sandbox days for real-gateway verification.

Target release date: Friday 6 November 2026. Sandbox days available before release: 27 Oct, 29 Oct, 3 Nov, 5 Nov.

## 2. Assumptions

- Release is 10 working days from Saturday 24 October, so Friday 6 November 2026. Code freeze is end of Wednesday 4 November.
- The feature ships behind a feature flag, off by default. If no flag exists, the developers add one in week one. This is the main safety net for single-card checkout.
- The developers can build a PayGate stub that replays recorded sandbox responses. The first sandbox day is used partly to record those responses.
- The UI offers an exact amount for card one and an "equal split" shortcut. The remainder-cent rule applies to the shortcut. If no shortcut exists, the rule is tested at the calculation layer only.
- Both amounts must be greater than zero and at least PayGate's minimum charge, assumed to be 50 cents. Confirm with the developers in week one.
- Charges are sequential: card one, then card two. The refund is issued by our system calling PayGate's refund API, not by PayGate automatically.
- PayGate supports idempotency keys. Each charge and refund carries its own key.
- One currency, web checkout only. Mobile apps and saved-card wallets are out of scope.
- The existing single-card suite has automated regression coverage that runs in CI. If it does not, the first day of effort goes to a manual single-card smoke checklist.
- The tester's half-time allocation can be rearranged so they work full days on Tuesdays and Thursdays and are off on other days. That matches sandbox availability.
- Customer-service refunds of split orders after the fact are handled by the existing refund tooling and are out of scope beyond a single check that both transactions are visible.

## 3. Scope

In scope:

- Split amount entry, validation, and the remainder-cent rule.
- Two sequential PayGate charges with correct amounts, order references, and idempotency keys.
- Automatic refund of card one when card two is declined, within 60 seconds.
- Failure handling when PayGate times out, errors, or is unreachable between the two charges or during the refund.
- Order, receipt, and transaction records showing both charges.
- Single-card checkout regression.
- Logging and monitoring for refund failures.
- PCI hygiene: no card numbers in logs or error messages.

Out of scope:

- Three or more cards.
- Mobile apps, wallets, gift cards, store credit.
- Load testing of PayGate itself.
- Chargeback and dispute flows.

## 4. Risk Register

Priority drives test depth and order. Likelihood and impact are rated High, Medium, Low.

| ID | Risk | Likelihood | Impact | Priority | Main mitigation |
|----|------|-----------|--------|----------|-----------------|
| R1 | Single-card checkout regresses. About 4,000 orders a day affected. | M | H | 1 | Automated regression on every build, real-sandbox single-card run on each sandbox day, feature flag off at launch. |
| R2 | Card two declined but card one is not refunded, or refund takes over 60 seconds. | H | H | 1 | Dedicated decline and refund test matrix on stub and sandbox. Timing measured with real gateway. Alerting on refund failure. |
| R3 | Refund itself fails because PayGate is down or returns an error. Customer charged with no order and no automatic recovery. | M | H | 1 | Stub-driven fault injection. Verify retry, alert, and manual queue. |
| R4 | Cent arithmetic wrong: amounts do not sum to the order total, or remainder goes to the wrong card. | M | H | 2 | Property-based unit tests. Boundary table in section 6. |
| R5 | Double charge on retry or timeout. The customer is charged twice on card one or card two. | M | H | 2 | Idempotency tests with replayed requests and simulated timeouts. |
| R6 | Crash or restart between charge one and charge two leaves an orphan charge. | L | H | 2 | Kill the process between calls under the stub. Verify recovery job or refund. |
| R7 | Input validation gaps: zero, negative, over total, decimals, text, same card twice. | H | M | 3 | Exploratory and scripted UI tests. |
| R8 | Records and receipts show one charge, breaking reconciliation and customer-service refunds. | M | M | 3 | Check order, receipt email, admin view, and reconciliation export. |
| R9 | Checkout latency doubles because two gateway calls run in sequence. | M | M | 3 | Measure on sandbox. Compare to single-card baseline. |
| R10 | Card data or full PAN appears in logs or error payloads. | L | H | 3 | Log review during sandbox runs. |
| R11 | Sandbox unavailable on a scheduled day, or feature is late for the first sandbox day. | M | M | Plan risk | Stub for all logic tests. Section 8 contingencies. |

## 5. Test Approach

Testing runs in four layers, matched to who can do it and on which days.

**Unit and property tests, developers, any day.** The split calculation is pure logic and must be fully covered without the gateway. Required property tests: for every total from 1 cent to a large value and every valid first-card amount, the two amounts sum to the total, both are positive integers, and under equal split the first card gets the extra cent. Validation rules are tested here too.

**Integration tests against the PayGate stub, tester and developers, any day.** The stub replays real sandbox responses recorded on 27 October and can be told to decline, time out, return 5xx, or drop the connection at a chosen step. This is where the decline and refund matrix, idempotency, and crash-recovery tests run. These tests are automated so they run on every build.

**End-to-end tests against the PayGate sandbox, tester, Tuesdays and Thursdays only.** Confirms that the stub matched reality: real decline codes, real refund timing, real auth and capture behaviour. Single-card regression also runs here. Each sandbox day has a fixed agenda in section 7, and the build to test is frozen the evening before.

**Exploratory and non-functional, tester, any day.** UI edge cases, receipts, admin views, log review, and latency comparison.

The tester owns test design, the sandbox-day runs, exploratory testing, and sign-off. The developers own unit tests, the stub, and automation of the integration matrix. Bugs found on a sandbox day are fixed the next day and re-verified on the stub, then confirmed on the next sandbox day.

## 6. Key Test Scenarios

**Amount and rounding, priority 2.** Each case checks both charge amounts and the order total.

| Order total in cents | Split input | Expected card one | Expected card two |
|---|---|---|---|
| 1 | equal | 1 | 0, must be rejected as below minimum |
| 101 | equal | 51 | 50 |
| 100 | equal | 50 | 50 |
| 999 | equal | 500 | 499 |
| 1,000,001 | equal | 500,001 | 500,000 |
| 5,000 | exact 50 | 50 | 4,950 |
| 5,000 | exact 4,950 | 4,950 | 50 |
| 5,000 | exact 5,000 | reject, second card would be zero | |
| 5,000 | exact 5,001 | reject | |
| 5,000 | exact 0 or negative | reject | |
| 5,000 | exact 10.005 or text | reject, no silent rounding | |
| 5,000 | same card number on both | reject or confirm, decision needed from product |

**Decline and refund matrix, priority 1.** Run on stub first, then on sandbox with real test cards.

| Step outcome | Expected result |
|---|---|
| Card one approved, card two approved | Order placed, two transactions recorded, one receipt with both amounts. |
| Card one declined | Card two never attempted. Customer sees decline for card one only. No refund needed. |
| Card one approved, card two declined | Refund of card one issued automatically. Refund confirmed within 60 seconds. Order not placed. Customer told clearly which card failed and that card one is refunded. |
| Card one approved, card two times out with unknown result | System must query status or void before refunding. No double refund, no orphan charge. |
| Card one approved, card two declined, refund API returns error | Retry with backoff. Alert raised. Order flagged for manual refund. Customer message does not promise a refund that did not happen. |
| Card one approved, PayGate unreachable before card two | Same as refund path. Verify behaviour when PayGate stays down past the 60-second target. |
| Customer submits twice, or network retries charge one | Exactly one charge per card. Idempotency key reused. |
| Process killed between charge one and charge two | On restart, orphan charge is refunded or the order is completed. Verified by log and transaction records. |

**Regression, priority 1.** Full automated single-card suite on every build. On each sandbox day: single-card approve, single-card decline, single-card refund, guest checkout, and a saved-card checkout if that exists. With the flag off, the UI must be identical to release 5.2.

**Records and receipts, priority 3.** Order detail, receipt email, admin transaction list, and reconciliation export all show two charges with correct amounts and last four digits. After an auto-refund, the refund appears linked to the original charge.

**Non-functional, priority 3.** Measure end-to-end checkout time for split versus single card over ten runs on a sandbox day. Review application logs after each sandbox run for card numbers, CVV, or full gateway payloads. Confirm an alert fires on refund failure in the test environment.

## 7. Schedule

Working days run from Monday 26 October to Friday 6 November. Sandbox days are marked.

| Date | Day | Activity | Who |
|---|---|---|---|
| Mon 26 Oct | 1 | Agree stub design, idempotency approach, feature flag, validation rules, and test-card list. Review this plan. | All three |
| Tue 27 Oct | 2, sandbox | Record real PayGate responses for approve, each decline code, timeout, refund, and refund-of-refund. Measure refund latency on a plain charge. Run single-card regression on sandbox as baseline. | Tester full day |
| Wed 28 Oct | 3 | Developers finish stub and unit tests. Tester writes integration matrix cases against the stub. | Devs, tester |
| Thu 29 Oct | 4, sandbox | First end-to-end on dev build: happy path and card-two-declined refund. Capture timing. Single-card smoke. | Tester full day |
| Fri 30 Oct | 5 | Developers fix findings. Automated integration matrix lands in CI. | Devs |
| Mon 2 Nov | 6 | Fault injection on stub: refund failure, timeout, crash between charges, idempotency. Exploratory UI pass. | Tester half day |
| Tue 3 Nov | 7, sandbox | Full decline and refund matrix on sandbox. Latency comparison. Receipts and records check. Full single-card regression on sandbox. | Tester full day |
| Wed 4 Nov | 8 | Final fixes. Log review for PCI. Alerting check. Code freeze end of day. | Devs, tester |
| Thu 5 Nov | 9, sandbox | Release-candidate run: happy path, card-two-declined with 60-second check, refund-failure path, full single-card regression. Sign-off decision. | Tester full day |
| Fri 6 Nov | 10 | Deploy with flag off. Verify single-card in production. Enable flag for internal staff only. Watch dashboards. | All three |

Tester effort is five days, placed on the four sandbox days plus one stub day. This exceeds half time on sandbox weeks and under-runs it otherwise, which needs manager agreement in day one.

## 8. Entry and Exit Criteria

Entry to a sandbox day:

- The build is deployed to the test environment by the previous evening.
- All unit and stub integration tests pass in CI.
- PayGate sandbox confirmed reachable at start of day.

Exit for release:

- All priority 1 scenarios pass on the real sandbox on 5 November.
- Refund after card-two decline observed within 60 seconds on at least five consecutive sandbox runs.
- Refund-failure path raises an alert and leaves a manual-recovery record.
- Single-card regression passes on sandbox with the flag on and with the flag off.
- No open severity 1 or 2 defects. Severity 1 is money lost or wrong, or single-card checkout broken. Severity 2 is a wrong record, a misleading customer message, or a validation hole that allows a bad amount.
- No card data in logs.

## 9. Contingencies

- **Feature not ready for 29 October.** Use that day for a deeper single-card regression baseline and extra response recording. The first real end-to-end moves to 3 November, and 5 November becomes the only re-verification day. Any severity 1 bug found on 3 November that is not confirmed fixed on 5 November blocks the release.
- **Sandbox outage on a scheduled day.** Run the stub matrix instead and request an extra sandbox window from PayGate. If two of the four days are lost, ship with the flag off and enable only after a post-release sandbox run.
- **60-second target not achievable because PayGate refund latency is itself slow.** Report measured latency from 27 October to product on the same day so the requirement can be adjusted before code freeze.
- **Idempotency not supported by PayGate.** Escalate on day one. Without it, the timeout cases need a status query before every retry and the schedule gains at least a day of developer work.

## 10. Release and Monitoring

Release with the flag off. Enable for internal staff on day one, then for a small percentage of customers once at least 20 split orders have reconciled correctly. Dashboards must show split-order count, card-two decline rate, auto-refund success rate, and refund latency. An alert on any refund failure goes to the on-call developer. Finance runs the reconciliation export on the first morning after customer enablement and confirms every split order balances.

## 11. Deliverables

- This plan, reviewed on 26 October.
- Automated unit and stub integration tests in CI.
- Sandbox-day run logs with timings, one per sandbox day.
- Defect list with severity.
- Sign-off note on 5 November stating pass or fail against section 8.
