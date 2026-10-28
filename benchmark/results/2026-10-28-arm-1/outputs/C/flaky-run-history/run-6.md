---
title: CI Tests Failing or Flaky on Main
slug: ci-tests-failing-or-flaky-on-main
article_type: troubleshooting
product_area: Testing
audience: Developer, QA Engineer
plan_availability: None: internal document
reading_time: 3 min
related_articles: None: create test-isolation and timing best-practices articles
last_updated: 2026-10-28
---

# CI Tests Failing or Flaky on Main

Ten runs of the e2e suite on commit c0ffee1 found 4 tests with issues. Three are flaky; one is a real bug that needs a fix.

## profile > saves a new avatar

**Status:** Failing in all 10 runs (100%)

**The problem:** The assertion expects "avatar.png" but receives `undefined`. The avatar filename is not reaching the DOM. This is a real bug, not flakiness.

**What to do:** File a bug and assign to a backend or component developer. Check the avatar save endpoint and the DOM update logic. Do not close the test until the bug is fixed.

## cart > updates the total when the quantity changes

**Status:** Flaky (3 of 10 failures)

**The problem:** The test waits 300ms after clicking "+", then reads the total once. The component takes longer than 300ms to recalculate.

**What to do:** Replace the fixed wait with a web-first assertion. Instead of `page.waitForTimeout(300)` plus `textContent()`, use `page.locator('total-element').filter({hasText: '€58.00'}).waitFor()`.

## search > filters results by tag

**Status:** Flaky (3 of 10 failures)

**The problem:** Test isolation. The test seeds "summer" tag. When tags.spec.ts runs before search.spec.ts and renames "summer", the search test breaks. Running search.spec.ts alone passes 20 of 20 times.

**What to do:** Reorder the test suite so tags.spec.ts runs after search.spec.ts. Or have tags.spec.ts restore the "summer" tag after it finishes.

## orders > shows the latest order first

**Status:** Flaky (2 of 10 failures)

**The problem:** The test creates an order and immediately polls `/orders`, but the backend needs up to 2 seconds to include it in the response.

**What to do:** Add a retry loop to the test. Poll `/orders` every 100ms up to 5 times before asserting. Do not increase the static wait; fixing the backend latency is a separate issue.

## login > signs in with valid credentials

**Status:** Stable (10 of 10 passes)

No action needed.
