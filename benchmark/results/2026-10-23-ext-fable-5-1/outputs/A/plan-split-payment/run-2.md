# Split Payment (release 5.3) — Risk-Based Test Plan

## 1. Scope, assumptions and risk ranking

**Scope.** Paying one order with two cards through PayGate, including amount splitting in cents, the automatic refund of the first charge when the second is declined, and protection of the existing single-card checkout. Out of scope: PayGate's own correctness, three or more cards, partial refunds of split orders after fulfilment, and changes to card data capture.

**Assumptions made where the brief is silent.**

- Release day is Friday 6 November 2026. Working days are Monday to Friday with no holidays. Sandbox days in the window are 27 Oct, 29 Oct, 3 Nov and 5 Nov.
- The tester's half time is spent as four full days on the sandbox days plus one day spread across the rest. Developers own unit and integration tests and build a PayGate stub for non-sandbox days.
- The first card is charged first. The second card is charged only if the first succeeds. The order is confirmed only when both succeed.
- The "remainder cent" rule applies to a quick split option such as 50/50 or percentage entry. Customer-typed cent amounts are used exactly.
- The refund is a full refund of the first charge via PayGate's refund call. The 60 seconds run from receipt of the decline response.
- The first-card amount must be at least 1 cent and at most the total minus 1 cent. Using the same card twice is allowed and treated as two charges.
- Split payment ships behind a feature flag that can be turned off without a redeploy.
- PayGate's sandbox provides test cards that force decline, timeout and refund failure.
- The existing single-card checkout has an automated regression suite that can run against the stub.

**Risk register, ranked by likelihood times impact.** Testing effort follows this order.

| # | Risk | Likelihood | Impact | Priority |
|---|------|-----------|--------|----------|
| R1 | Second charge declined but first charge not refunded, refunded late, or refunded twice. Customer loses money with no order. | High | Critical | 1 |
| R2 | Single-card checkout breaks or slows because it shares the gateway client and checkout flow with the new code. | Medium | Critical | 2 |
| R3 | Cent arithmetic wrong: charges do not sum to the order total, remainder on the wrong card, zero or negative amounts, float rounding. | High | High | 3 |
| R4 | Double charging on retry, double submit, refresh, or gateway timeout where the charge actually went through. | Medium | Critical | 4 |
| R5 | Stub behaviour differs from the real gateway, so defects only appear on sandbox days or in production. | High | High | 5 |
| R6 | Failure mid-flow: crash after first charge, refund call fails or times out, no alert raised, order stuck in limbo. | Medium | High | 6 |
| R7 | Client-side tampering of the split amounts or card totals lets a customer pay less than the order total. | Low | High | 7 |
| R8 | Records wrong downstream: receipts, order history, refund records and finance reconciliation show one charge instead of two. | Medium | Medium | 8 |
| R9 | Input validation and UI gaps: amount over total, non-numeric, currency formatting, back button, mobile layout. | High | Low | 9 |
| R10 | Latency doubles because of two sequential gateway calls, causing timeouts or abandoned checkouts. | Low | Medium | 10 |

## 2. Test approach by risk

**Levels and who runs them.**

| Level | Runs against | Owner | When |
|-------|-------------|-------|------|
| Unit tests for split arithmetic, state machine and refund timer | In-process | Developers | Continuously |
| Integration tests for charge, decline and refund paths | PayGate stub | Developers, reviewed by tester | Mon, Wed, Fri |
| End-to-end and exploratory testing | PayGate sandbox | Tester | Tue, Thu only |
| Single-card regression suite | Stub, then sandbox | Developers run it; tester reviews results | Every build, plus each sandbox day |
| Production verification | Live PayGate, small real amounts, internal cards | Tester with a developer | Release day |

**R1 Refund on second decline.** Sandbox tests: second card declined immediately; second card times out; second card declined and then the refund call fails; refund call times out; PayGate returns an ambiguous response. For each, verify the first charge is refunded exactly once, the order is marked failed, the customer sees a clear message, and the time from decline response to refund acknowledgement is under 60 seconds. Record the timing for every run. Run ten declined splits in parallel to check the timer holds under concurrency. Verify an alert fires when the refund cannot be completed. The stub reproduces these same cases on non-sandbox days so developers can fix without waiting for Tuesday.

**R2 Single-card regression.** The full existing regression suite runs on every build against the stub. On each sandbox day the tester also runs a manual single-card smoke of approve, decline, refund and receipt. On 27 October, before any split code is tested, the tester records single-card latency and behaviour against the sandbox as a baseline. The same measurements are repeated on 5 November and compared. Any degradation blocks release regardless of split-payment status.

**R3 Cent arithmetic.** Developers unit test the split function with the tester supplying the cases. Cases include: total of 1 cent is rejected; total of 3 cents split evenly gives 2 and 1; odd totals such as 100.01 split evenly put the extra cent on the first card; first amount equal to total; first amount of zero; first amount above total; amounts entered with three decimals; values prone to float error such as 0.10 plus 0.20; large totals near the gateway maximum; percentage splits that produce fractional cents. Every case asserts that the two charges sum exactly to the order total and that neither is below 1 cent. Tester repeats a sample of these in the sandbox to confirm PayGate receives the integer cent values.

**R4 Double charging.** Sandbox and stub: double-click submit; browser refresh after the first charge succeeds; network drop during the second charge; gateway timeout when the charge actually succeeded. Verify idempotency keys are sent for each charge and the refund, and that PayGate shows exactly one charge per card per order afterwards.

**R5 Stub fidelity.** On the first sandbox day the tester captures real PayGate responses for approve, decline, timeout and refund, and developers align the stub to them that evening. Any difference found later between stub and sandbox is logged as a defect against the stub and fixed before the next stub-based run.

**R6 Mid-flow failure.** Stub only, with developer help: kill the service after the first charge and before the second; restart and confirm a recovery job refunds or completes the order and raises an alert. Verify the order never stays in an intermediate state for more than the refund window. Check logs identify order, both charge references and the refund reference.

**R7 Tampering.** Tester intercepts the checkout request and modifies the first amount, the second amount and the total. The server must recompute the split from the server-side order total and reject mismatches. Confirm no card data touches new logging.

**R8 Downstream records.** After each sandbox session, check receipts, order history, admin order view and the finance export show two charges and, for failed orders, one refund. Confirm the amounts match PayGate's dashboard to the cent.

**R9 Validation and UI.** Stub-based exploratory session: boundary amounts, non-numeric input, locale formatting with commas, back button after first charge, mobile viewport, feature flag off hides the option. Accessibility check on the new amount field.

**R10 Latency.** Measure end-to-end checkout time for split versus single card during a sandbox session. Flag if split checkout exceeds twice the single-card baseline. No load test is planned because the sandbox cannot support it; production monitoring covers this after a dark launch.

## 3. Schedule, responsibilities and exit criteria

**Schedule.** Tester works full days on the four sandbox days. Developers must deliver a build with the stub by end of Monday 26 October or the plan slips one sandbox session.

| Date | Day | Activity |
|------|-----|----------|
| Mon 26 Oct | 1 | Tester reviews spec, writes arithmetic cases, agrees test cards and stub scenarios with developers. Stub delivered. |
| Tue 27 Oct | 2 | Sandbox 1. Single-card baseline. Capture real responses. Split happy path if build is ready. |
| Wed 28 Oct | 3 | Developers align stub to captured responses, run unit and integration tests. Tester reviews results. |
| Thu 29 Oct | 4 | Sandbox 2. R1 refund paths with timing, R4 double charge, R3 sample. |
| Fri 30 Oct | 5 | Developers fix. Regression suite on stub. |
| Mon 2 Nov | 6 | Tester verifies fixes on stub, R6 crash recovery, R9 exploratory. |
| Tue 3 Nov | 7 | Sandbox 3. Full re-run of R1 and R4, R7 tampering, R8 records. Code freeze at end of day. |
| Wed 4 Nov | 8 | Release candidate built. Regression suite on stub. Developers fix only blockers. |
| Thu 5 Nov | 9 | Sandbox 4. Release candidate verification, single-card baseline comparison, go/no-go decision. |
| Fri 6 Nov | 10 | Deploy with flag off. Enable for internal users. Real small-value split with a forced decline. Monitor refund alert and single-card error rate for two hours before public enable. |

**Responsibilities.**

- Tester: test design, sandbox sessions, exploratory testing, defect triage, go/no-go recommendation.
- Developers: unit and integration tests, PayGate stub, regression suite execution, fixes, alerting and recovery job.
- Release owner: go/no-go decision. Assumed to be the product owner.

**Entry criteria for each sandbox day.** Build deployed to the test environment by the previous evening, regression suite green on the stub, known blockers listed.

**Exit criteria for release.**

- All R1 scenarios pass in the sandbox with every refund under 60 seconds, including the parallel run.
- Single-card regression suite green on the release candidate, and sandbox baseline on 5 November matches 27 October.
- No open defects of critical or high severity. Medium defects accepted in writing by the release owner.
- Alert for failed refund verified to fire.
- Tampering tests rejected server-side.
- Feature flag verified to disable split payment without redeploy.

**Risks to this plan and mitigations.**

- Only four sandbox sessions exist, and the last is the day before release. If the build is not testable by 29 October, recommend releasing with the flag off and enabling after a sandbox session the following week.
- If a critical defect is found on 5 November, there is no sandbox day left for verification. Default decision is to ship dark and verify in production with internal cards before enabling.
- The tester has roughly 40 hours. Arithmetic and validation testing is deliberately pushed to developers' unit tests so sandbox time goes to the refund and double-charge paths.
- If PayGate's sandbox is down on a scheduled day, run the planned session on the stub and move sandbox verification to the next slot. Two lost sandbox days means the release ships dark.
