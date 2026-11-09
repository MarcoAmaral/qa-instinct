## Detection Results

**Flaky tests (verdict changed on unchanged code):**

| Test | Failures | Rate | Evidence |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3/10 | 30% | Failed on runs 2, 5, 9 |
| search > filters results by tag | 4/10 | 40% | Failed on runs 2, 4, 7, 10; passed 20/20 in isolation |
| orders > shows the latest order first | 2/10 | 20% | Failed on runs 3, 8; 3/50 failures in isolated repeat run |

**Deterministic failures (failed every run, not flaky):**

| Test | Failures | Rate | Status |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10/10 | 100% | Real defect, not a flaky test; report separately |

**No issues:**

| Test | Passes |
| --- | --- |
| login > signs in with valid credentials | 10/10 |

---

## Classification & Diagnosis

### 1. cart > updates the total when the quantity changes
**Class:** Test timing  
**Root cause:** Hardcoded `page.waitForTimeout(300)` before reading the total. The UI update takes longer than 300ms on some runs.  
**Evidence:** Same failure ("€29.00" instead of "€58.00") in every failed run; predictable pattern across distributed workers suggests timing variance, not environmental skew.  
**Fix:** Replace the hardcoded sleep with a web-first assertion that waits for the DOM to stabilize:
```javascript
await page.locator('[data-total]').toContainText('€58.00');
```

### 2. search > filters results by tag
**Class:** Test order or shared state collision  
**Root cause:** Test data isolation failure. The test passes in isolation (20/20 with `--workers=1 --repeat-each=20`) but fails in the suite because `tags.spec.ts` renames the seeded "summer" tag during its own run.  
**Evidence:** Isolation run succeeded 100%; suite run failed 40%. Failure rate depends on test execution order and tags.spec.ts interference.  
**Fix:** Ensure test isolation:
- Use a unique tag per test (e.g., UUID or timestamp-based) instead of seeded constants.
- Or: Run `tags.spec.ts` in a separate worker pool so it does not collide with search tests.
- Or: Have `tags.spec.ts` clean up after itself (restore the original "summer" tag).

### 3. orders > shows the latest order first
**Class:** Product intermittent defect (eventual consistency)  
**Root cause:** Backend API eventual consistency lag. GET /orders does not return the newly created order for up to 2 seconds after the POST /orders succeeds.  
**Evidence:** Failed 3/50 even with web-first assertions, new user per run, and clean isolation. The delay is in the backend, not the test.  
**Action:** 
- **Immediate:** Quarantine with `@flaky @quarantine` tags pending backend fix.
- **Backend fix required:** Add a consistency check or cache flush to ensure GET /orders includes the new order within <500ms.
- **Test:** After backend fix, verify with `npx playwright test orders.spec.ts --workers=4 --repeat-each=20` that the order appears immediately.

---

## Quarantine Ledger

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | Test timing | — | QA (fix test, not a product defect) | 2026-10-28 | 2026-11-11 | @flaky (do not quarantine; fix in 2 sprints) |
| search > filters results by tag | Test order/shared state | — | QA (fix test isolation) | 2026-10-28 | 2026-11-11 | @flaky (do not quarantine; fix in 2 sprints) |
| orders > shows the latest order first | Product intermittent defect | DR-TBD | Backend + QA | 2026-10-28 | 2026-11-11 | @flaky @quarantine |
| profile > saves a new avatar | Deterministic failure | DR-TBD | Backend | 2026-10-28 | — | Not flaky; report as product defect |

---

## Recommendations

1. **Do not quarantine cart and search tests.** Both are test bugs, not product bugs. Fix them before the deadline (2026-11-11, assuming 2-week sprints). Tag with `@flaky` only during investigation.

2. **Quarantine orders test.** Tag with `@flaky @quarantine` and open a backend defect (DR-TBD) for the 2-second GET /orders lag. Exclude from `@smoke` and `@regression` jobs with `--grep-invert @quarantine`. Run it in a separate, non-blocking job so the backend fix is visible when it lands.

3. **Report profile as a separate defect.** This is not flaky; it is deterministic. Open DR-TBD for avatar save failure and assign to backend.

4. **Assumption:** 2-week sprints (standard); deadline is 2 weeks from quarantine date. Adjust if your sprints differ.
