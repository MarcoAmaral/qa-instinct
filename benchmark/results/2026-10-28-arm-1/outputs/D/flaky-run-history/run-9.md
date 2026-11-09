## Detected Flaky Tests

**From CI history (10 runs, same commit c0ffee1, Playwright 4 workers, no retries):**

### Flaky (changing verdict on unchanged code)

| Test | Failures | Passes | Rate | Cause Class | Evidence |
| --- | --- | --- | --- | --- | --- |
| cart › updates the total when the quantity changes | 3 | 7 | 30% | Test timing | Hard sleep `page.waitForTimeout(300)` instead of waiting for the total element to update. Missing web-first assertion. |
| search › filters results by tag | 4 | 6 | 40% | Order or shared state | Passes 20/20 when run alone (`--workers=1 --repeat-each=20`). Fails in suite. Root cause: tags.spec.ts renames the shared seeded tag "summer" during its own run; search test depends on that tag's name. Test isolation failure. |
| orders › shows the latest order first | 2 | 8 | 20% | Product intermittent defect | Repeat run alone with isolated data (new user per run, web-first assertions, `--repeat-each=50`) failed 3/50 (~6% rate). GET /orders lacks the newly created order for up to 2 seconds after POST /orders. Eventual consistency or race in backend. |

### Deterministic Failures (no flakiness; report separately)

| Test | Failures | Pattern | Action |
| --- | --- | --- | --- |
| profile › saves a new avatar | 10 | Always fails, same message | File as product defect. Expected "avatar.png", received `undefined`. Not flaky; needs investigation of avatar upload flow or test setup. |

### Stable (no action)

- login › signs in with valid credentials: 0 failures in 10 runs. ✓

---

## Next Steps by Cause

**Test Timing:** `cart › updates the total when the quantity changes`
- Replace `page.waitForTimeout(300)` with a web-first assertion. Wait for the total text to change (e.g., `expect(totalElement).toHaveText(/€58\.00/)`), not a fixed delay.
- Repeat: `npx playwright test cart.spec.ts --workers=4 --repeat-each=20`. Target: 0 failures in 20 runs.

**Shared State:** `search › filters results by tag`
- Fix test isolation: create or restore the "summer" tag within the test's setup, do not rely on tags.spec.ts leaving it in a known state.
- Or: sequence tests with `--grep` to run search before tags, and accept that dependency (not recommended; isolation is preferred).
- Repeat: `npx playwright test search.spec.ts --workers=4 --repeat-each=20`. Target: 0 failures.

**Product Intermittent Defect:** `orders › shows the latest order first`
- File defect report with backend team: `/qa-defect` severity Major, observed frequency 6% (~3 failures per 50 orders). GET /orders is missing newly created orders for up to 2 seconds post-creation.
- Quarantine the test with `@quarantine` tag and an owner pending a backend fix.
- While quarantined, add a separate non-blocking CI job (`--grep @quarantine`) so a backend fix is visible when it lands.
- Deadline: rule's sprint period from quarantine date.
- Retire when: backend fix is confirmed on the defect report AND the test still fails if the order is not returned (red-green proof: introduce a 3-second delay in the backend and confirm the test now catches it).

**Deterministic Failure:** `profile › saves a new avatar`
- File as product defect: avatar upload returns `undefined` instead of the filename. Not a flaky test; investigate the avatar upload endpoint or test data setup.

---

**Quarantine Ledger** (to be created at `flaky/ledger.md`):

| Test ID | Cause Class | Defect Report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| orders › shows the latest order first | Product intermittent defect | [open] | [assign] | 2026-10-28 | [sprint end] | @quarantine |

**Flake rate: 1 quarantined out of ~120 total tests (~0.8%).** Below threshold for escalation (rule boundary assumed >10%).
