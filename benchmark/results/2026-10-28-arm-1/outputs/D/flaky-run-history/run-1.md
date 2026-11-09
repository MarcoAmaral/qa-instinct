## Flaky Test Analysis: Commit c0ffee1

### Test Classification

#### Flaky Tests (verdict varies on unchanged code)

| Test | Cause Class | Failure Rate | Action |
|------|-------------|--------------|--------|
| **cart > updates the total when the quantity changes** | Test timing | 3/10 (30%) | **Fix the test**: Replace `page.waitForTimeout(300)` with web-first wait (`waitForSelector()`, `locator().toBeVisible()`, or equivalent). The hard sleep is insufficient for the DOM update. |
| **search > filters results by tag** | Order/shared state | 4/10 (40%) | **Fix the test isolation**: The test passes 20/20 alone (`--workers=1 --repeat-each=20`). Root cause: `tags.spec.ts` mutates the seeded "summer" tag during parallel runs. Isolate by using test-specific tag names or isolating `tags.spec.ts` setup. |
| **orders > shows the latest order first** | Product intermittent defect | 2/10 (20%), 3/50 alone (6%) | **File defect + quarantine**: Backend eventual consistency—GET /orders is missing the newly created order for up to 2 seconds after POST /orders. File `/qa-defect` with observed frequency (3/50 = 6%, ~100ms–2sec delay). Tag `@flaky` and move to `@quarantine` pending product fix. |

#### Deterministic Failure (always fails, not flaky)

| Test | Result | Action |
|------|--------|--------|
| **profile > saves a new avatar** | 0/10 passes | **File defect separately**: Returns `undefined` instead of "avatar.png" in all 10 runs. Not flaky—deterministic bug. Investigate selector, setup, or backend response. File `/qa-defect` for triage. Do not quarantine; this blocks the feature. |

#### Stable (no action)

| Test | Result |
|------|--------|
| **login > signs in with valid credentials** | 10/10 passes |

---

## Ledger Entry (assume `flaky/ledger.md` exists)

**Quarantined share:** 1 test quarantined (orders) ÷ 120 tests in suite = **0.8%** (well below escalation threshold).

| Test ID | Cause Class | Defect Report | Owner | Quarantined on | Deadline | Status |
|---------|-------------|---------------|-------|----------------|----------|--------|
| orders > shows the latest order first | Product intermittent defect | [DR-001: GET /orders eventual consistency] | [Backend lead] | 2026-10-28 | 2026-11-11 | Quarantined pending backend fix |

---

## Next Steps by Role

**Test Author (cart, search tests):**
- Replace hard sleep with web-first assertion (`waitForLoadState('networkidle')` or selector wait).
- Isolate `search.spec.ts` data: generate or seed unique tag names per test run; restore after.
- Re-run `--repeat-each=20` on each spec to confirm fix before un-tagging.

**Backend Team:**
- Investigate GET /orders latency: eventual consistency in order creation, caching layer, or database replication lag.
- Reproduce: create order, poll GET /orders in a loop, log first appearance time.

**QA Lead:**
- Tag `cart` and `search` tests with `@flaky` (do not quarantine yet; these are fixable today).
- File `/qa-defect` for `profile > saves a new avatar` as a product bug (deterministic, blocks feature).
- File `/qa-defect` for `orders` eventual consistency; move that test to `@quarantine` once the defect is filed.
- Exclude `@quarantine` from `@regression` runs; keep a side job running quarantined tests to show when the fix lands.

---

## Assumptions

- Sprint length: 2 weeks (deadline = quarantine date + 14 days).
- "Avatar.png" failure is not a seeded test (not a known intermittent by design).
- CI environment is consistent across 10 runs (no infrastructure changes between R1–R10).
- Playwright retries = 0 as stated; no retries masked flakes in the report.
