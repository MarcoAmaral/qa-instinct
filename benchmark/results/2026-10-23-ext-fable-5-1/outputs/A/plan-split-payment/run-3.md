# Test Plan: Split Payment (Release 5.3)

## 1. Scope and assumptions

**In scope:** paying one order with two cards, amount selection, cent arithmetic, two PayGate charges, automatic refund of the first charge when the second is declined, and non-regression of single-card checkout.

**Out of scope:** more than two cards, split across non-card methods, PayGate's own internal behaviour, PCI re-certification.

**Assumptions (stated where the brief is silent):**

- A1. Single currency (USD), all amounts are integer cents. Zero-decimal currencies are not supported in 5.3.
- A2. A valid split requires both cards to carry at least 1 cent. First-card amount equal to the total or zero is rejected as invalid input, not treated as single-card.
- A3. The UI offers a "split evenly" default plus a custom first-card amount. The remainder-cent rule applies to the even split.
- A4. The 60-second refund clock starts when PayGate returns the decline for the second charge.
- A5. PayGate sandbox provides test cards for approve, decline, timeout, and refund-failure outcomes.
- A6. A PayGate stub exists or will be built by developers in the first two days so testing is not blocked on Monday, Wednesday, and Friday.
- A7. An automated regression suite exists for single-card checkout and runs in CI. If it does not, building a minimal one is the first developer task.
- A8. Feature is behind a feature flag so release can proceed with split disabled if exit criteria are not met.
- A9. Today is Saturday 24 Oct 2026. Working days are Mon 26 Oct to Fri 6 Nov. Release is Fri 6 Nov. Sandbox days are 27 Oct, 29 Oct, 3 Nov, 5 Nov.

## 2. Risk analysis

Priority drives effort. P1 risks get real-gateway coverage on every sandbox day. P2 get stub coverage plus at least one sandbox run. P3 get stub or review coverage only.

| ID | Risk | Likelihood | Impact | Priority |
|----|------|-----------|--------|----------|
| R1 | Second charge declined, first charge not refunded, or refunded late. Customer loses money, chargebacks follow. | Medium | Critical | P1 |
| R2 | Single-card checkout regresses. 4,000 orders a day affected. | Medium | Critical | P1 |
| R3 | Double charge from retries or duplicate submit when PayGate times out on either leg. | Medium | Critical | P1 |
| R4 | Process crash or restart between first charge success and second charge attempt leaves an orphaned charge. | Low | Critical | P1 |
| R5 | Cent arithmetic wrong: sum of legs differs from order total, remainder cent on wrong card, rounding in display vs. charge. | Medium | High | P2 |
| R6 | Refund itself fails or times out and no retry or alert exists. | Medium | High | P2 |
| R7 | Client can tamper with amounts so legs do not sum to the total, or sends negative or oversized values. | Low | High | P2 |
| R8 | Order, receipt, email, and finance records show wrong state after partial success or refund. | Medium | Medium | P2 |
| R9 | Same card entered twice, or second card identical to first after tokenisation. | Medium | Low | P3 |
| R10 | Added latency from two sequential gateway calls degrades checkout under daily load. | Low | Medium | P3 |
| R11 | Accessibility and usability of the split UI. | Medium | Low | P3 |
| R12 | Plan risk: only four sandbox days, so gateway-dependent defects found late cannot be re-verified before release. | High | High | Mitigated in section 5 |

## 3. Test approach by layer

**Unit tests (developers, days 1 to 3).** Pure functions for amount splitting and validation. Exhaustive edge cases for cents are cheap here and remove most of R5 and R7 from manual effort.

**Component tests against the stub (developers and tester, every day).** The payment orchestration state machine with scripted gateway outcomes: approve/approve, approve/decline, approve/timeout, decline/anything, approve/decline/refund-fail, crash between legs. This is where R1, R3, R4, and R6 get their depth.

**End-to-end against PayGate sandbox (tester, Tue and Thu only).** Confirms the stub matches the real gateway and measures the actual refund time. Each sandbox day has a fixed agenda (section 5) so nothing is wasted.

**Regression (CI, every build).** Existing single-card suite plus a smoke run against the sandbox on each sandbox day. Covers R2.

**Exploratory (tester, 2 hours).** Split UI, back-button and refresh during payment, browser tab duplication, same-card entry. Covers R9 and R11.

**Review rather than test.** Load impact (R10) is assessed by reviewing the gateway call pattern and the latency numbers from sandbox runs, not by a load test. Monitoring and alerting for orphaned charges is reviewed as a release gate.

## 4. Test design

### 4.1 Amount splitting (R5, R7)

| Case | Total | First card input | Expected first | Expected second |
|------|-------|-----------------|----------------|-----------------|
| Even split, odd total | 1001 | even | 501 | 500 |
| Even split, even total | 1000 | even | 500 | 500 |
| Smallest splittable | 2 | even | 1 | 1 |
| Smallest total odd | 3 | even | 2 | 1 |
| Custom minimum | 1000 | 1 | 1 | 999 |
| Custom maximum | 1000 | 999 | 999 | 1 |
| Custom equals total | 1000 | 1000 | reject | |
| Custom zero | 1000 | 0 | reject | |
| Custom over total | 1000 | 1001 | reject | |
| Negative | 1000 | -1 | reject | |
| Non-integer cents | 1000 | 33.3 | reject | |
| Total of 1 cent | 1 | any | split not offered | |
| Large total | 99999999 | even | 50000000 | 49999999 |
| Tampered request, legs do not sum to total | 1000 | 400 + 500 | reject server-side | |

Every accepted case asserts first plus second equals total, and that the amounts sent to PayGate equal the amounts shown to the customer.

### 4.2 Charge orchestration and refund (R1, R3, R4, R6)

| Scenario | Gateway outcomes | Expected result |
|----------|-----------------|-----------------|
| Happy path | approve, approve | Order paid, two charge records, one receipt |
| First declined | decline | No second attempt, order unpaid, customer can retry |
| Second declined | approve, decline | First refunded within 60 s, order unpaid, customer informed |
| Second timeout | approve, timeout | No blind retry of second leg. Status query then refund if not captured |
| First timeout | timeout | No duplicate first charge on retry. Idempotency key verified |
| Refund fails | approve, decline, refund error | Retry with backoff, alert raised, charge flagged for reconciliation |
| Refund slow | approve, decline, refund takes 70 s | Measured and reported. Alert if over 60 s |
| Crash between legs | approve, process killed | On restart, first charge is refunded or second leg resumed, never left orphaned |
| Double submit | two identical requests | Exactly two charges total, not four |
| Second card same as first | approve, approve on same token | Per A2 this is allowed if PayGate accepts it. Confirm on sandbox |

Refund timing is measured on each sandbox day with at least 10 approve/decline runs. Record minimum, median, and maximum.

### 4.3 Single-card regression (R2)

- Full existing automated suite on every build.
- Manual smoke on each sandbox day: one approve, one decline, one refund on single-card.
- Verify the split UI is absent and single-card is unchanged when the feature flag is off.
- Verify order and finance records for single-card orders have no new or changed fields that downstream reports depend on.

### 4.4 Records and communication (R8)

For each orchestration scenario above, check the order status, payment records, customer email, and the finance export. Specifically check that a refunded first charge appears as a refund and not as a successful payment.

### 4.5 Exploratory (R9, R11)

Two-hour charter: break the split UI. Refresh and back during each step, duplicate tab, keyboard-only completion, screen reader labels on the amount field.

## 5. Sandbox day schedule

| Day | Agenda | Owner |
|-----|--------|-------|
| Tue 27 Oct | Confirm sandbox test cards for decline, timeout, refund failure. Record real response shapes and timings. Validate the stub against these. Single-card smoke. | Tester plus one developer |
| Thu 29 Oct | First end-to-end split on a dev build. Happy path, second declined, refund timing baseline. | Tester |
| Tue 3 Nov | Full section 4.2 run on release candidate. 10-run refund timing sample. Full single-card smoke. | Tester plus one developer |
| Thu 5 Nov | Re-test of fixes only. Final single-card smoke. Go or no-go. | Tester |

Code freeze for gateway-touching changes is end of day Wed 4 Nov. Anything changed after that cannot be verified on the real gateway and ships behind the flag turned off.

## 6. Overall schedule and effort

Tester capacity is about 5 person-days across the 10 days.

| Days | Activity | Tester effort |
|------|----------|---------------|
| Mon 26 Oct | Finalise cases, agree stub contract with developers | 0.5 |
| Tue 27 Oct | Sandbox day 1 | 0.5 |
| Wed 28 Oct | Stub-based orchestration tests on first build | 0.5 |
| Thu 29 Oct | Sandbox day 2 | 0.5 |
| Fri 30 Oct | Records and communication checks, exploratory | 0.5 |
| Mon 2 Nov | Retest defects on stub | 0.5 |
| Tue 3 Nov | Sandbox day 3 | 0.5 |
| Wed 4 Nov | Retest, regression review, code freeze | 0.5 |
| Thu 5 Nov | Sandbox day 4, sign-off report | 0.5 |
| Fri 6 Nov | Release support, monitor first split orders | 0.5 |

Developers own unit tests, the stub, component tests for the state machine, and the crash-between-legs test, since those need test hooks in the code.

## 7. Entry and exit criteria

**Entry to sandbox day 2:** unit tests for section 4.1 passing, stub in place, feature flag working.

**Exit for release with split enabled:**

- All P1 scenarios passed on the real sandbox on 3 Nov or 5 Nov.
- Refund completed within 60 seconds in every sampled run.
- No open P1 or P2 defects.
- Single-card regression suite green on the release build, and single-card smoke passed on 5 Nov.
- An alert exists for any first charge older than 60 seconds with no matching second charge or refund.
- A reconciliation query exists that finance can run to find orphaned charges.

If any criterion fails, release ships with the flag off and the split feature is enabled after the next sandbox verification.

## 8. Risks to this plan

- **Sandbox outage on a scheduled day.** Mitigation: the stub is validated on 27 Oct so stub results carry more weight. If 3 Nov is lost, 5 Nov becomes the full run and release ships flag-off if fixes are needed.
- **Build not ready by 29 Oct.** Mitigation: that day is used to extend stub validation and single-card regression instead. The 3 Nov run becomes the first full end-to-end run.
- **Half-time tester is pulled elsewhere.** Mitigation: developers run the sandbox agendas, which are written to be executable by anyone.
- **Crash-between-legs test cannot be built in time.** Mitigation: it is replaced by a code review of the recovery path plus the orphaned-charge alert as the release gate.
